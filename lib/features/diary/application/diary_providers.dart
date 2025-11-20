import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/diary_entry.dart';
import '../data/diary_repository.dart';
import '../../music/application/audio_handler.dart'; 

final diaryBoxProvider = Provider<Box<DiaryEntry>>((ref) {
  throw UnimplementedError(); 
});

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  final box = ref.watch(diaryBoxProvider);
  return DiaryRepository(box);
});

final llmServiceProvider = Provider<MockLLMService>((ref) => MockLLMService());

class DiaryListNotifier extends StateNotifier<List<DiaryEntry>> {
  final DiaryRepository _repository;

  DiaryListNotifier(this._repository) : super([]) {
    loadDiaries();
  }

  void loadDiaries() {
    state = _repository.getDiaries();
  }

  Future<void> addDiary(DiaryEntry entry) async {
    await _repository.addDiary(entry);
    loadDiaries();
  }

  // ⚡ [추가됨] 일기 수정 함수
  Future<void> updateDiary(DiaryEntry entry) async {
    // Hive는 같은 Key(ID)에 put을 하면 덮어쓰기(수정)가 됩니다.
    await _repository.addDiary(entry); 
    loadDiaries();
  }

  Future<void> deleteDiary(String id) async {
    await _repository.deleteDiary(id);
    loadDiaries();
  }
  
  Future<void> toggleSell(String id) async {
    await _repository.toggleSellStatus(id);
    loadDiaries(); 
  }
}

final diaryListProvider = StateNotifierProvider<DiaryListNotifier, List<DiaryEntry>>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return DiaryListNotifier(repository);
});