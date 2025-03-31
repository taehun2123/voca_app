import 'package:hive/hive.dart';
import '../model/word_entry.dart';

class StorageService {
  final Box _wordBox;
  final Box _dayCollectionBox;

  StorageService() :
    _wordBox = Hive.box('wordBox'),
    _dayCollectionBox = Hive.box('dayCollectionBox');

  // 단어 저장
  Future<void> saveWord(WordEntry word) async {
    await _wordBox.put(word.word, word.toMap());
  }

  // 여러 단어 저장
  Future<void> saveWords(List<WordEntry> words) async {
    for (var word in words) {
      await saveWord(word);
    }
  }

  // 단어 가져오기
  WordEntry? getWord(String wordText) {
    final wordMap = _wordBox.get(wordText);
    if (wordMap == null) return null;
    return WordEntry.fromMap(Map<String, dynamic>.from(wordMap));
  }

  // 모든 단어 가져오기
  List<WordEntry> getAllWords() {
    List<WordEntry> words = [];
    for (var key in _wordBox.keys) {
      final wordMap = _wordBox.get(key);
      if (wordMap != null) {
        words.add(WordEntry.fromMap(Map<String, dynamic>.from(wordMap)));
      }
    }
    return words;
  }

  // DAY별 단어 가져오기
  List<WordEntry> getWordsByDay(String day) {
    List<WordEntry> words = [];
    for (var key in _wordBox.keys) {
      final wordMap = _wordBox.get(key);
      if (wordMap != null) {
        final word = WordEntry.fromMap(Map<String, dynamic>.from(wordMap));
        if (word.day == day) {
          words.add(word);
        }
      }
    }
    return words;
  }

  // DAY 컬렉션 정보 저장
  Future<void> saveDayCollection(String day, int wordCount) async {
    await _dayCollectionBox.put(day, {
      'date': DateTime.now().millisecondsSinceEpoch,
      'wordCount': wordCount,
    });
  }

  // 모든 DAY 정보 가져오기
  Map<String, Map<String, dynamic>> getAllDays() {
    Map<String, Map<String, dynamic>> result = {};
    for (var key in _dayCollectionBox.keys) {
      final dayInfo = _dayCollectionBox.get(key);
      if (dayInfo != null) {
        result[key.toString()] = Map<String, dynamic>.from(dayInfo);
      }
    }
    return result;
  }

  // 단어 삭제
  Future<void> deleteWord(String wordText) async {
    await _wordBox.delete(wordText);
  }

  // DAY 삭제
  Future<void> deleteDay(String day) async {
    // DAY에 속한 단어들 찾기
    List<String> wordsToDelete = [];
    
    for (var key in _wordBox.keys) {
      final wordMap = _wordBox.get(key);
      if (wordMap != null) {
        final word = WordEntry.fromMap(Map<String, dynamic>.from(wordMap));
        if (word.day == day) {
          wordsToDelete.add(word.word);
        }
      }
    }
    
    // 단어들 삭제
    for (var word in wordsToDelete) {
      await _wordBox.delete(word);
    }
    
    // DAY 정보 삭제
    await _dayCollectionBox.delete(day);
  }
  
  // 암기 상태 업데이트
  Future<void> updateMemorizedStatus(String wordText, bool isMemorized) async {
    final wordMap = _wordBox.get(wordText);
    if (wordMap != null) {
      final word = WordEntry.fromMap(Map<String, dynamic>.from(wordMap));
      final updatedWord = word.copyWith(isMemorized: isMemorized);
      await _wordBox.put(wordText, updatedWord.toMap());
    }
  }
  
  // 복습 횟수 증가
  Future<void> incrementReviewCount(String wordText) async {
    final wordMap = _wordBox.get(wordText);
    if (wordMap != null) {
      final word = WordEntry.fromMap(Map<String, dynamic>.from(wordMap));
      final updatedWord = word.copyWith(reviewCount: word.reviewCount + 1);
      await _wordBox.put(wordText, updatedWord.toMap());
    }
  }
}