import '../model/word_entry.dart';
import 'db_service.dart';

class StorageService {
  final DBService _dbService = DBService();
  
  // 단어 저장
  Future<void> saveWord(WordEntry word) async {
    await _dbService.saveWord(word);
  }

  // 여러 단어 저장
  Future<void> saveWords(List<WordEntry> words) async {
    await _dbService.saveWords(words);
  }

  // 단어 가져오기
  Future<WordEntry?> getWord(String wordText) async {
    return await _dbService.getWord(wordText);
  }

  // 모든 단어 가져오기
  Future<List<WordEntry>> getAllWords() async {
    return await _dbService.getAllWords();
  }

  // DAY별 단어 가져오기
  Future<List<WordEntry>> getWordsByDay(String day) async {
    return await _dbService.getWordsByDay(day);
  }

  // DAY 컬렉션 정보 저장
  Future<void> saveDayCollection(String day, int wordCount) async {
    await _dbService.saveDayCollection(day, wordCount);
  }

  // 모든 DAY 정보 가져오기
  Future<Map<String, Map<String, dynamic>>> getAllDays() async {
    return await _dbService.getAllDays();
  }

  // 단어 삭제
  Future<void> deleteWord(String wordText) async {
    await _dbService.deleteWord(wordText);
  }

  // DAY 삭제
  Future<void> deleteDay(String day) async {
    await _dbService.deleteDay(day);
  }
  
  // 암기 상태 업데이트
  Future<void> updateMemorizedStatus(String wordText, bool isMemorized) async {
    await _dbService.updateMemorizedStatus(wordText, isMemorized);
  }
  
  // 복습 횟수 증가
  Future<void> incrementReviewCount(String wordText) async {
    await _dbService.incrementReviewCount(wordText);
  }
  
  // 데이터베이스 유효성 검사 (디버깅용)
  Future<void> validateStorage() async {
    await _dbService.validateDatabase();
  }

  // lib/services/storage_service.dart에 메서드 추가
Future<void> deleteNullDayWords() async {
  await _dbService.deleteNullDayWords();
}
}