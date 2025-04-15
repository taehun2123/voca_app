import 'package:flutter/material.dart';
import '../model/word_entry.dart';
import '../widgets/dialogs/day_selection_dialog.dart';

class ManualWordAddScreen extends StatefulWidget {
  final String? initialDayName;
  final List<WordEntry> existingWords;
  final Map<String, List<WordEntry>> dayCollections;
  final Function(String, List<WordEntry>) onDayCollectionUpdated;

  const ManualWordAddScreen({
    Key? key,
    this.initialDayName,
    this.existingWords = const [],
    required this.dayCollections,
    required this.onDayCollectionUpdated,
  }) : super(key: key);

  @override
  _ManualWordAddScreenState createState() => _ManualWordAddScreenState();
}

class _ManualWordAddScreenState extends State<ManualWordAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<WordEntry> _addedWords = [];

  // 기존 단어 목록 (보기용)
  late List<WordEntry> _existingWordsList = [];

  // 현재 입력 중인 단어에 대한 컨트롤러들
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _pronunciationController =
      TextEditingController();
  final TextEditingController _meaningController = TextEditingController();

  // 예문 및 관용구 컨트롤러들 (다수 입력 지원)
  final List<TextEditingController> _exampleControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _phraseControllers = [
    TextEditingController()
  ];

  Map<String, List<WordEntry>> _dayCollections = {};

  // 단어장 이름
  String? _currentDay;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentDay = widget.initialDayName;
    _dayCollections = Map<String, List<WordEntry>>.from(widget.dayCollections
        .map((key, value) => MapEntry(key, List<WordEntry>.from(value))));
    // 화면이 완전히 빌드된 후 다이얼로그 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentDay == null) {
        _showDaySelectionDialog(initialSelection: true);
      } else {
        _loadExistingWordsForCurrentDay();
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  // 현재 단어장의 단어들만 로드
  void _loadExistingWordsForCurrentDay() {
    if (_currentDay == null) return;

    setState(() {
      _existingWordsList = widget.existingWords
          .where((word) => word.day == _currentDay)
          .toList();
    });
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    _wordController.dispose();
    _pronunciationController.dispose();
    _meaningController.dispose();

    for (var controller in _exampleControllers) {
      controller.dispose();
    }

    for (var controller in _phraseControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  // 예문 컨트롤러 추가
  void _addExampleField() {
    setState(() {
      _exampleControllers.add(TextEditingController());
    });
  }

  // 관용구 컨트롤러 추가
  void _addPhraseField() {
    setState(() {
      _phraseControllers.add(TextEditingController());
    });
  }

  // 예문 컨트롤러 제거
  void _removeExampleField(int index) {
    if (_exampleControllers.length > 1) {
      setState(() {
        _exampleControllers[index].dispose();
        _exampleControllers.removeAt(index);
      });
    }
  }

  // 관용구 컨트롤러 제거
  void _removePhraseField(int index) {
    if (_phraseControllers.length > 1) {
      setState(() {
        _phraseControllers[index].dispose();
        _phraseControllers.removeAt(index);
      });
    }
  }

  // nextDayNum 계산 함수
  int calculateNextDayNumber(Map<String, List<WordEntry>> dayCollections) {
    int nextDayNum = 1;

    if (dayCollections.isNotEmpty) {
      try {
        // 유효한 DAY 형식의 키만 필터링
        List<int> validDayNumbers = [];

        for (var day in dayCollections.keys) {
          // 정규식으로 "DAY " 다음에 오는 숫자 추출
          final match = RegExp(r'DAY\s+(\d+)').firstMatch(day);
          if (match != null && match.group(1) != null) {
            validDayNumbers.add(int.parse(match.group(1)!));
          }
        }

        if (validDayNumbers.isNotEmpty) {
          // 가장 큰 DAY 번호 찾기
          nextDayNum = validDayNumbers.reduce((a, b) => a > b ? a : b) + 1;
        }
      } catch (e) {
        print('DAY 번호 계산 중 오류 발생: $e');
        // 오류 발생 시 기본값 1 사용
        nextDayNum = 1;
      }
    }

    return nextDayNum;
  }

  // 단어장 선택 다이얼로그 표시
  Future<void> _showDaySelectionDialog({bool initialSelection = false}) async {
    // 다음 DAY 번호 계산 함수 사용
    int nextDayNum = calculateNextDayNumber(_dayCollections);
    try {
      // 기존 다이얼로그 함수 호출
      final String? selectedDay = await showDaySelectionDialog(
        context: context,
        dayCollections: _dayCollections,
        nextDayNum: nextDayNum,
      );

      // 결과 처리
      if (selectedDay != null && selectedDay.isNotEmpty) {
        setState(() {
          _currentDay = selectedDay;
          _isInitialized = true;

          // 이미 추가된 단어들의 day 값 업데이트
          for (var i = 0; i < _addedWords.length; i++) {
            _addedWords[i] = _addedWords[i].copyWith(day: _currentDay);
          }
        });

        // 새 단어장에 맞는 기존 단어 목록 필터링해서 보여주기
        _loadExistingWordsForCurrentDay();
      } else if (initialSelection) {
        // 초기 선택인데 선택하지 않았으면 기본값 설정
        setState(() {
          _currentDay = 'Day$nextDayNum';
          _isInitialized = true;
        });
        _loadExistingWordsForCurrentDay();
      }
    } catch (e) {
      print('단어장 선택 다이얼로그 오류: $e');
      // 오류 발생 시 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('단어장 선택 중 오류가 발생했습니다'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );

      // 초기 선택인데 오류 발생 시 기본값 설정
      if (initialSelection && _currentDay == null) {
        setState(() {
          _currentDay = 'Day$nextDayNum';
          _isInitialized = true;
        });
        _loadExistingWordsForCurrentDay();
      }
    }
  }

  // 단어 추가
  void _addWord() {
    if (_formKey.currentState!.validate()) {
      // 영어 단어와 의미는 필수
      final word = _wordController.text.trim();
      final meaning = _meaningController.text.trim();

      // 이미 추가된 단어인지 확인
      if (_isWordAlreadyAdded(word)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미 추가한 단어입니다: $word'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 발음은 선택사항
      final pronunciation = _pronunciationController.text.trim();

      // 예문 및 관용구 필터링 (빈 항목 제거)
      final examples = _exampleControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final phrases = _phraseControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // WordEntry 객체 생성 및 추가
      final newWord = WordEntry(
        word: word,
        pronunciation: pronunciation,
        meaning: meaning,
        examples: examples,
        commonPhrases: phrases,
        day: _currentDay,
        // 기본값 설정
        reviewCount: 0,
        isMemorized: false,
      );
      setState(() {
        _addedWords.add(newWord);

        // 현재 단어장에 추가된 단어 목록 업데이트
        if (_currentDay != null) {
          if (_dayCollections.containsKey(_currentDay)) {
            // 기존 단어장이 있으면 추가
            _dayCollections[_currentDay!] = [
              ..._dayCollections[_currentDay!]!,
              newWord
            ];
          } else {
            // 없으면 새로 생성
            _dayCollections[_currentDay!] = [newWord];
          }
        }
      });

      // 입력 필드 초기화
      _resetInputFields();

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('단어 추가됨: $word'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // 추가된 단어 또는 기존 단어에 이미 있는지 체크
  bool _isWordAlreadyAdded(String word) {
    // 현재 추가된 단어 목록에서 체크
    if (_addedWords.any((w) => w.word.toLowerCase() == word.toLowerCase())) {
      return true;
    }

    // 기존 단어 목록에서 체크
    if (widget.existingWords
        .any((w) => w.word.toLowerCase() == word.toLowerCase())) {
      return true;
    }

    return false;
  }

  // 입력 필드 초기화
  void _resetInputFields() {
    _wordController.clear();
    _pronunciationController.clear();
    _meaningController.clear();

    // 예문 필드 초기화 (첫 번째는 유지, 나머지 제거)
    while (_exampleControllers.length > 1) {
      _exampleControllers.last.dispose();
      _exampleControllers.removeLast();
    }
    _exampleControllers.first.clear();

    // 관용구 필드 초기화 (첫 번째는 유지, 나머지 제거)
    while (_phraseControllers.length > 1) {
      _phraseControllers.last.dispose();
      _phraseControllers.removeLast();
    }
    _phraseControllers.first.clear();
  }

  // 단어 제거
  void _removeWord(int index) {
    setState(() {
      _addedWords.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 초기화 중이면 로딩 표시
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('단어 직접 추가'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('단어 직접 추가'),
        actions: [
          IconButton(
            icon: Icon(Icons.drive_file_rename_outline),
            tooltip: '단어장 선택',
            onPressed: () => _showDaySelectionDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 단어장 정보
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentDay ?? '단어장 미선택',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '추가된 단어: ${_addedWords.length}개',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          Divider(),

          // 입력 폼과 추가된 단어 목록을 탭으로 구분
          Expanded(
            child: DefaultTabController(
              length: 3, // 탭 3개: 단어 입력, 추가된 단어, 기존 단어
              child: Column(
                children: [
                  TabBar(
                    labelColor: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                    unselectedLabelColor: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                    indicatorColor: isDarkMode
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                    tabs: [
                      Tab(text: '단어 입력'),
                      Tab(text: '추가된 단어 (${_addedWords.length})'),
                      Tab(text: '기존 단어 (${_existingWordsList.length})'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 단어 입력 폼
                        _buildInputForm(),

                        // 추가된 단어 목록
                        _buildAddedWordsList(),

                        // 기존 단어 목록
                        _buildExistingWordsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 ${_addedWords.length}개 단어 추가됨',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: _addedWords.isEmpty || _currentDay == null
                    ? null
                    : () {
                        // 단어장 데이터 업데이트 (부모 위젯에 알림)
                        _updateDayCollection();

                        // 이전 화면으로 돌아가기
                        Navigator.of(context).pop({
                          'words': _addedWords,
                          'dayName': _currentDay,
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? Colors.green.shade600 : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 단어 입력 폼
  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 단어 입력
            TextFormField(
              controller: _wordController,
              decoration: InputDecoration(
                labelText: '영어 단어 *',
                hintText: '영어 단어를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.text_fields),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '단어를 입력해주세요';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 16),

            // 발음 입력
            TextFormField(
              controller: _pronunciationController,
              decoration: InputDecoration(
                labelText: '발음 기호',
                hintText: '발음 기호를 입력하세요 (선택사항)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.record_voice_over),
              ),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 16),
            // 의미 입력
            TextFormField(
              controller: _meaningController,
              decoration: InputDecoration(
                labelText: '한국어 의미 *',
                hintText: '단어의 의미를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.translate),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '단어의 의미를 입력해주세요';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 24),

// 예문 섹션
            Text(
              '예문 (선택사항)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

// 예문 입력 필드들
            ..._buildExampleFields(),

            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addExampleField,
              icon: Icon(Icons.add),
              label: Text('예문 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue.shade800
                    : Colors.blue.shade100,
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue.shade100
                    : Colors.blue.shade800,
              ),
            ),

            SizedBox(height: 24),

// 관용구 섹션
            Text(
              '관용구 or 기출 표현 (선택사항)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

// 관용구 입력 필드들
            ..._buildPhraseFields(),

            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addPhraseField,
              icon: Icon(Icons.add),
              label: Text('관용구 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.purple.shade900.withOpacity(0.5)
                    : Colors.purple.shade100,
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.purple.shade100
                    : Colors.purple.shade800,
              ),
            ),

            SizedBox(height: 32),

// 단어 추가 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addWord,
                icon: Icon(Icons.add_circle),
                label: Text('단어 추가하기'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Colors.white,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.amber.shade700
                          : Colors.amber.shade600,
                ),
              ),
            ),
// 여백 추가
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // 예문 입력 필드들 생성
  List<Widget> _buildExampleFields() {
    List<Widget> fields = [];

    for (var i = 0; i < _exampleControllers.length; i++) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _exampleControllers[i],
                  decoration: InputDecoration(
                    hintText: '예문 ${i + 1}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => _removeExampleField(i),
              ),
            ],
          ),
        ),
      );
    }

    return fields;
  }

  // 관용구 입력 필드들 생성
  List<Widget> _buildPhraseFields() {
    List<Widget> fields = [];

    for (var i = 0; i < _phraseControllers.length; i++) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phraseControllers[i],
                  decoration: InputDecoration(
                    hintText: '관용구 ${i + 1}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => _removePhraseField(i),
              ),
            ],
          ),
        ),
      );
    }

    return fields;
  }

  // 추가된 단어 목록
  Widget _buildAddedWordsList() {
    if (_addedWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.format_list_bulleted,
              size: 80,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              '추가된 단어가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '왼쪽 탭에서 단어를 추가해주세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _addedWords.length,
      itemBuilder: (context, index) {
        final word = _addedWords[index];

        return Dismissible(
          key: Key('word_${index}_${word.word}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _removeWord(index);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${word.word} 단어가 삭제되었습니다'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                word.word,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (word.pronunciation.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        word.pronunciation,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  Text(word.meaning),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (word.examples.isNotEmpty) ...[
                        Divider(),
                        Text(
                          '예문:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        ...word.examples.map((example) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                '• $example',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            )),
                      ],
                      if (word.commonPhrases.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Divider(),
                        Text(
                          '관용구:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        ...word.commonPhrases.map((phrase) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                '• $phrase',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 기존 단어 목록 표시
  Widget _buildExistingWordsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_existingWordsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              '${_currentDay}에 저장된 단어가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _existingWordsList.length,
      itemBuilder: (context, index) {
        final word = _existingWordsList[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.6),
            ),
          ),
          color: isDarkMode
              ? Colors.grey.shade800.withOpacity(0.5)
              : Colors.grey.shade50,
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color:
                      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    word.word,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (word.pronunciation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      word.pronunciation,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Text(
                  word.meaning,
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (word.examples.isNotEmpty) ...[
                      Divider(),
                      Text(
                        '예문:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4),
                      ...word.examples.map((example) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              '• $example',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          )),
                    ],
                    if (word.commonPhrases.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Divider(),
                      Text(
                        '관용구:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4),
                      ...word.commonPhrases.map((phrase) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              '• $phrase',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// 이런 함수가 필요합니다
  void _updateDayCollection() {
    if (_currentDay == null) return;

    // 현재 단어장의 단어 목록 업데이트
    List<WordEntry> updatedWords = [..._existingWordsList, ..._addedWords];

    // 부모 위젯에 알림
    widget.onDayCollectionUpdated(_currentDay!, updatedWords);

    // 로컬 상태 업데이트
    setState(() {
      _dayCollections[_currentDay!] = updatedWords;
    });
  }
}
