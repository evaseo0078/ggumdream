// functions/src/index.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

import { v4 as uuidv4 } from "uuid";
import * as querystring from "querystring";

admin.initializeApp();

const db = admin.firestore();
const bucket = admin.storage().bucket();
const FieldValue = admin.firestore.FieldValue;

// ====================================================================
// 1) Pollinations 이미지 생성 (v2 callable)
// ====================================================================
export const generateImageFromPollinations = onCall(
  { region: "asia-northeast3" },
  async (request) => {
    const prompt: string = (request.data?.prompt || "").trim();
    if (!prompt) {
      throw new HttpsError("invalid-argument", "prompt is empty");
    }

    const encoded = querystring.escape(prompt);
    const pollinationsUrl =
      `https://image.pollinations.ai/prompt/${encoded}` +
      "?nologo=true&width=1024&height=1024";

    try {
      const resp = await fetch(pollinationsUrl);
      if (!resp.ok) {
        throw new Error(`pollinations status: ${resp.status}`);
      }

      const arrayBuffer = await resp.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);

      const fileId = uuidv4();
      const filePath = `pollinations/${fileId}.png`;
      const downloadToken = uuidv4();

      const file = bucket.file(filePath);
      await file.save(buffer, {
        metadata: {
          contentType: "image/png",
          metadata: { firebaseStorageDownloadTokens: downloadToken },
        },
      });

      const imageUrl =
        `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
        `${encodeURIComponent(filePath)}?alt=media&token=${downloadToken}`;

      logger.info("Generated Pollinations image", {
        prompt,
        path: filePath,
        imageUrl,
      });

      return { prompt, path: filePath, imageUrl };
    } catch (err: any) {
      logger.error("generateImageFromPollinations error", err);
      throw new HttpsError(
        "internal",
        "failed to generate image: " + (err?.message ?? String(err)),
      );
    }
  },
);

// ====================================================================
// 2) 회원가입 1000코인 지급 (Auth Trigger, v1)
// ====================================================================
export const grantSignupBonus = functions
  .region("asia-northeast3")
  .auth.user()
  .onCreate(async (user) => {
    const uid = user.uid;
    const userRef = db.collection("users").doc(uid);
    const ledgerRef = userRef.collection("coin_ledger").doc("signup_bonus");

    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      const userData = userSnap.exists ? userSnap.data()! : {};

      // 이미 지급한 경우 종료
      if (userData.signupBonusGranted) return;

      const now = FieldValue.serverTimestamp();

      if (!userSnap.exists) {
        // 최초 생성
        tx.set(userRef, {
          coins: 1000,
          signupBonusGranted: true,
          createdAt: now,
          updatedAt: now,
        });
      } else {
        // 기존 문서 → 코인 증가
        tx.update(userRef, {
          coins: FieldValue.increment(1000),
          signupBonusGranted: true,
          updatedAt: now,
        });
      }

      // Ledger 기록
      tx.set(ledgerRef, {
        amount: 1000,
        type: "signup_bonus",
        refType: "system",
        refId: "signup_bonus",
        createdAt: now,
      });
    });

    logger.info("Signup bonus granted", { uid });
  });

// ====================================================================
// 3) 마켓 아이템 구매 (Callable, v2) — 단일 트랜잭션
// ====================================================================
type MarketStatus = "listed" | "sold" | "cancelled";

export const purchaseMarketItem = onCall(
  { region: "asia-northeast3" },
  async (request) => {
    const buyerUid = request.auth?.uid;
    if (!buyerUid) {
      throw new HttpsError("unauthenticated", "Login required.");
    }

    const itemId: string = (request.data?.itemId || "").trim();
    if (!itemId) {
      throw new HttpsError("invalid-argument", "itemId is required.");
    }

    const itemRef = db.collection("market_items").doc(itemId);
    const buyerRef = db.collection("users").doc(buyerUid);

    try {
      const result = await db.runTransaction(async (tx) => {
        const itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) {
          throw new HttpsError("not-found", "Market item not found.");
        }

        const item = itemSnap.data()!;
        const status = item.status as MarketStatus;
        const sellerUid = item.sellerUid as string;
        const price = item.price as number;
        const diaryId = item.diaryId as string;

        if (!sellerUid || !diaryId || typeof price !== "number") {
          throw new HttpsError("failed-precondition", "Invalid item data.");
        }

        if (sellerUid === buyerUid) {
          throw new HttpsError(
            "failed-precondition",
            "You cannot buy your own item.",
          );
        }

        if (status !== "listed") {
          throw new HttpsError(
            "failed-precondition",
            "Item is not available.",
          );
        }

        // Buyer
        const buyerSnap = await tx.get(buyerRef);
        if (!buyerSnap.exists) {
          throw new HttpsError(
            "failed-precondition",
            "Buyer profile not found.",
          );
        }

        const buyerCoins = (buyerSnap.data()!.coins ?? 0) as number;
        if (buyerCoins < price) {
          throw new HttpsError("failed-precondition", "Insufficient coins.");
        }

        // Seller
        const sellerRef = db.collection("users").doc(sellerUid);

        // 거래 ID
        const purchaseTxId = uuidv4();
        const now = FieldValue.serverTimestamp();

        // Ledger
        const buyerLedgerRef =
          buyerRef.collection("coin_ledger").doc(purchaseTxId);
        const sellerLedgerRef =
          sellerRef.collection("coin_ledger").doc(purchaseTxId);

        // 구매/판매 기록
        const purchaseDocRef =
          buyerRef.collection("purchases").doc(purchaseTxId);
        const saleDocRef =
          sellerRef.collection("sales").doc(purchaseTxId);

        // --------------------------------------------------------
        // 트랜잭션: 아이템 상태 업데이트
        // --------------------------------------------------------
        tx.update(itemRef, {
          status: "sold",
          buyerUid,
          soldAt: now,
          updatedAt: now,
          purchaseTxId,
        });

        // Ledger 기록
        tx.set(buyerLedgerRef, {
          amount: -price,
          type: "purchase_spend",
          refType: "market_item",
          refId: itemId,
          counterpartyUid: sellerUid,
          createdAt: now,
        });

        tx.set(sellerLedgerRef, {
          amount: price,
          type: "sale_earn",
          refType: "market_item",
          refId: itemId,
          counterpartyUid: buyerUid,
          createdAt: now,
        });

        // 유저 코인 조정
        tx.update(buyerRef, { coins: FieldValue.increment(-price) });
        tx.update(sellerRef, { coins: FieldValue.increment(price) });

        // 구매/판매 기록 생성
        tx.set(purchaseDocRef, {
          itemId,
          diaryId,
          sellerUid,
          price,
          purchasedAt: now,
          purchaseTxId,
        });

        tx.set(saleDocRef, {
          itemId,
          diaryId,
          buyerUid,
          price,
          soldAt: now,
          purchaseTxId,
        });

        return { purchaseTxId, sellerUid, diaryId, price };
      });

      logger.info("Market purchase success", { buyerUid, itemId, result });
      return result;
    } catch (err: any) {
      logger.error("purchaseMarketItem error", err);

      if (err instanceof HttpsError) throw err;

      throw new HttpsError(
        "internal",
        "Purchase failed: " + (err?.message ?? String(err)),
      );
    }
  },
);

// ====================================================================
// 4) 마켓 아이템 등록 (Callable, v2)
// ====================================================================
export const createMarketItem = onCall(
  { region: "asia-northeast3" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Login required.");
    }

    const diaryId: string = request.data?.diaryId ?? "";
    const price: number = request.data?.price ?? 0;
    const ownerName: string = request.data?.ownerName ?? "";

    if (!diaryId) {
      throw new HttpsError("invalid-argument", "Missing diaryId");
    }

    const id = `${diaryId}_${Date.now()}`;
    const now = FieldValue.serverTimestamp();

    await db.collection("market_items").doc(id).set({
      id,
      diaryId,
      sellerUid: uid,
      ownerName,
      price,
      status: "listed",
      createdAt: now,
      updatedAt: now,
    });

    logger.info("Market item created", { id, diaryId, uid, price });

    return { id };
  },
);
