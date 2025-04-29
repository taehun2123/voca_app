// lib/model/word_entry.dart (수정)
class WordEntry {
  final String word;
  final String pronunciation;
  final String meaning;
  final List<String> examples;
  final List<String> commonPhrases;
  final String? day;  // DAY 1, DAY 2 등 단어장 그룹
  final DateTime createdAt;
  int reviewCount;    // 복습 횟수
  bool isMemorized;   // 암기 여부
  
  // 퀴즈 관련 정보 추가
  int quizAttempts;   // 퀴즈 시도 횟수
  int quizCorrect;    // 퀴즈 정답 횟수
  double difficulty;  // 난이도 점수 (0.0~1.0)

  WordEntry({
    required this.word,
    required this.pronunciation,
    required this.meaning,
    required this.examples,
    this.commonPhrases = const [],
    this.day,
    DateTime? createdAt,
    this.reviewCount = 0,
    this.isMemorized = false,
    this.quizAttempts = 0,
    this.quizCorrect = 0,
    this.difficulty = 0.5,  // 기본 난이도는 중간
  }) : createdAt = createdAt ?? DateTime.now();

  // Hive 저장을 위한 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'pronunciation': pronunciation,
      'meaning': meaning,
      'examples': examples,
      'commonPhrases': commonPhrases,
      'day': day,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'reviewCount': reviewCount,
      'isMemorized': isMemorized,
      'quizAttempts': quizAttempts,
      'quizCorrect': quizCorrect,
      'difficulty': difficulty,
    };
  }

  factory WordEntry.fromMap(Map<String, dynamic> map) {
    return WordEntry(
      word: map['word'] ?? '',
      pronunciation: map['pronunciation'] ?? '',
      meaning: map['meaning'] ?? '',
      examples: List<String>.from(map['examples'] ?? []),
      commonPhrases: List<String>.from(map['commonPhrases'] ?? []),
      day: map['day'],
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
          : DateTime.now(),
      reviewCount: map['reviewCount'] ?? 0,
      isMemorized: map['isMemorized'] ?? false,
      quizAttempts: map['quizAttempts'] ?? 0,
      quizCorrect: map['quizCorrect'] ?? 0,
      difficulty: map['difficulty'] ?? 0.5,
    );
  }

  // 단어 업데이트를 위한 복사 메서드
  WordEntry copyWith({
    String? word,
    String? pronunciation,
    String? meaning,
    List<String>? examples,
    List<String>? commonPhrases,
    String? day,
    DateTime? createdAt,
    int? reviewCount,
    bool? isMemorized,
    int? quizAttempts,
    int? quizCorrect,
    double? difficulty,
  }) {
    return WordEntry(
      word: word ?? this.word,
      pronunciation: pronunciation ?? this.pronunciation,
      meaning: meaning ?? this.meaning,
      examples: examples ?? this.examples,
      commonPhrases: commonPhrases ?? this.commonPhrases,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
      reviewCount: reviewCount ?? this.reviewCount,
      isMemorized: isMemorized ?? this.isMemorized,
      quizAttempts: quizAttempts ?? this.quizAttempts,
      quizCorrect: quizCorrect ?? this.quizCorrect,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  // 퀴즈 결과 업데이트 메서드
  WordEntry updateQuizResult(bool isCorrect) {
    return copyWith(
      quizAttempts: quizAttempts + 1,
      quizCorrect: isCorrect ? quizCorrect + 1 : quizCorrect,
      // 난이도 조정: 맞추면 난이도 감소, 틀리면 난이도 증가
      difficulty: _calculateNewDifficulty(isCorrect),
    );
  }

  // 난이도 계산 메서드
  double _calculateNewDifficulty(bool isCorrect) {
    double change = 0.05; // 변화량
    
    if (quizAttempts < 3) {
      change = 0.1; // 초기에는 더 큰 변화폭
    }
    
    double newDifficulty;
    if (isCorrect) {
      newDifficulty = difficulty - change;
    } else {
      newDifficulty = difficulty + change;
    }
    
    // 0.1~1.0 범위로 제한
    return newDifficulty.clamp(0.1, 1.0);
  }

  // 정답률 계산 메서드
  double getCorrectRate() {
    if (quizAttempts == 0) return 0.0;
    return quizCorrect / quizAttempts;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordEntry && other.word == word;
  }

  @override
  int get hashCode => word.hashCode;
}