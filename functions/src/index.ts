// functions/src/index.ts
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

import fetch from "node-fetch";
import {v4 as uuidv4} from "uuid";
import * as querystring from "querystring";

admin.initializeApp();
const bucket = admin.storage().bucket();

export const generateImageFromPollinations = onCall(
  {region: "asia-northeast3"},
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
      const file = bucket.file(filePath);
      const downloadToken = uuidv4();

      await file.save(buffer, {
        metadata: {
          contentType: "image/png",
          metadata: {firebaseStorageDownloadTokens: downloadToken},
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

      return {
        prompt,
        path: filePath,
        imageUrl,
      };
    } catch (err: any) {
      logger.error("generateImageFromPollinations error", err);
      throw new HttpsError(
        "internal",
        "failed to generate image: " + err.message
      );
    }
  }
);
