class WordEntry {
  final String word;
  final String pronunciation;
  final String meaning;
  final List<String> examples;
  final List<String> commonPhrases;
  final String? day;  // DAY 1, DAY 2 등 단어장 그룹
  final DateTime createdAt;
  int reviewCount;
  bool isMemorized;

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
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordEntry && other.word == word;
  }

  @override
  int get hashCode => word.hashCode;
}