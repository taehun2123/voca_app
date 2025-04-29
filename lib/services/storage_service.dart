import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> deleteDayCollection(String day) async {
    // 단어장 정보 삭제
    final prefs = await SharedPreferences.getInstance();
    final key = 'day_collection_$day';
    await prefs.remove(key);
    
    // 해당 단어장의 단어들도 삭제
    final allWords = await getAllWords(); // getWords() -> getAllWords()로 수정
    final wordsToKeep = allWords.where((word) => word.day != day).toList();
    await saveWords(wordsToKeep); // saveAllWords() -> saveWords()로 수정
  }
  // lib/services/storage_service.dart에 추가할 메서드

  // 퀴즈 결과 업데이트
  Future<void> updateQuizResult(String wordText, bool isCorrect) async {
    try {
      // 단어 찾기
      final word = await getWord(wordText);
      if (word == null) {
        print('퀴즈 결과 업데이트 오류: 단어 $wordText를 찾을 수 없음');
        return;
      }
      
      // 퀴즈 결과 업데이트
      final updatedWord = word.updateQuizResult(isCorrect);
      
      // 저장
      await saveWord(updatedWord);
      
      print('퀴즈 결과 업데이트 성공: $wordText (정답: $isCorrect)');
    } catch (e) {
      print('퀴즈 결과 업데이트 오류: $e');
    }
  }
  
  // 특정 단어의 퀴즈 정보 가져오기
  Future<Map<String, dynamic>> getWordQuizInfo(String wordText) async {
    try {
      final word = await getWord(wordText);
      if (word == null) {
        return {
          'attempts': 0,
          'correct': 0,
          'rate': 0.0,
          'difficulty': 0.5,
        };
      }
      
      return {
        'attempts': word.quizAttempts,
        'correct': word.quizCorrect,
        'rate': word.getCorrectRate(),
        'difficulty': word.difficulty,
      };
    } catch (e) {
      print('단어 퀴즈 정보 조회 오류: $e');
      return {
        'attempts': 0,
        'correct': 0,
        'rate': 0.0,
        'difficulty': 0.5,
      };
    }
  }
  
  // 특정 단어장의 평균 퀴즈 정답률 계산
  Future<double> getDayCollectionAverageQuizRate(String day) async {
    try {
      final words = await getWordsByDay(day);
      if (words.isEmpty) return 0.0;
      
      double totalRate = 0.0;
      int wordCount = 0;
      
      for (var word in words) {
        if (word.quizAttempts > 0) {
          totalRate += word.getCorrectRate();
          wordCount++;
        }
      }
      
      return wordCount > 0 ? totalRate / wordCount : 0.0;
    } catch (e) {
      print('단어장 퀴즈 정답률 계산 오류: $e');
      return 0.0;
    }
  }
}
