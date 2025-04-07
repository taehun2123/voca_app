import 'package:flutter/material.dart';
import '../model/word_entry.dart';

class WordEditScreen extends StatefulWidget {
  final List<WordEntry> words;
  final String dayName;
  final List<WordEntry>? newWords; // 새 단어 목록 (선택 사항)
  final bool isFromImageRecognition; // 새로 추가한 플래그

  const WordEditScreen({
    Key? key,
    required this.words,
    required this.dayName,
    this.newWords,
    this.isFromImageRecognition = false, // 기본값은 false
  }) : super(key: key);

  @override
  _WordEditScreenState createState() => _WordEditScreenState();
}

class _WordEditScreenState extends State<WordEditScreen> {
  late List<WordEntry> _editableWords;
  late String _currentDay;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    // 수정 가능한 단어 목록 복사
    _editableWords = List.from(widget.words);
    _currentDay = widget.dayName;
  }

  // 단어 삭제
  void _removeWord(int index) {
    setState(() {
      _editableWords.removeAt(index);
      _isModified = true;
    });
  }

  // 단어 수정 다이얼로그
  Future<void> _editWord(int index) async {
    final word = _editableWords[index];

    // 컨트롤러 초기화
    final TextEditingController wordController =
        TextEditingController(text: word.word);
    final TextEditingController pronunciationController =
        TextEditingController(text: word.pronunciation);
    final TextEditingController meaningController =
        TextEditingController(text: word.meaning);

    // 예문과 관용구 관리를 위한 상태 변수
    List<TextEditingController> exampleControllers =
        word.examples.map((e) => TextEditingController(text: e)).toList();
    if (exampleControllers.isEmpty) {
      exampleControllers.add(TextEditingController());
    }

    List<TextEditingController> phraseControllers =
        word.commonPhrases.map((e) => TextEditingController(text: e)).toList();

    // 수정 다이얼로그 표시
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('단어 수정'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: wordController,
                    decoration: InputDecoration(
                      labelText: '단어',
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: pronunciationController,
                    decoration: InputDecoration(
                      labelText: '발음',
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: meaningController,
                    decoration: InputDecoration(
                      labelText: '의미',
                    ),
                  ),

                  // 예문 관리
                  SizedBox(height: 16),
                  Text('예문:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List.generate(exampleControllers.length, (i) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: exampleControllers[i],
                            decoration: InputDecoration(
                              hintText: '예문 ${i + 1}',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              exampleControllers.removeAt(i);
                            });
                          },
                        ),
                      ],
                    );
                  }),
                  TextButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('예문 추가'),
                    onPressed: () {
                      setState(() {
                        exampleControllers.add(TextEditingController());
                      });
                    },
                  ),

                  // 관용구 관리
                  SizedBox(height: 16),
                  Text('관용구:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List.generate(phraseControllers.length, (i) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phraseControllers[i],
                            decoration: InputDecoration(
                              hintText: '관용구 ${i + 1}',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              phraseControllers.removeAt(i);
                            });
                          },
                        ),
                      ],
                    );
                  }),
                  TextButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('관용구 추가'),
                    onPressed: () {
                      setState(() {
                        phraseControllers.add(TextEditingController());
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('저장'),
              ),
            ],
          );
        },
      ),
    );

    // 저장 처리
    if (result == true) {
      // 예문 및 관용구 필터링 (빈 항목 제거)
      final examples = exampleControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final phrases = phraseControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // 단어 업데이트
      setState(() {
        _editableWords[index] = word.copyWith(
          word: wordController.text.trim(),
          pronunciation: pronunciationController.text.trim(),
          meaning: meaningController.text.trim(),
          examples: examples,
          commonPhrases: phrases,
        );
        _isModified = true;
      });
    }

    // 컨트롤러 정리
    wordController.dispose();
    pronunciationController.dispose();
    meaningController.dispose();
    for (var controller in exampleControllers) {
      controller.dispose();
    }
    for (var controller in phraseControllers) {
      controller.dispose();
    }
  }

  // 단어장 이름 변경
  Future<void> _changeDayName() async {
    final TextEditingController controller =
        TextEditingController(text: _currentDay);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('단어장 이름 변경'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '예: DAY 1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('저장'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _currentDay) {
      setState(() {
        _currentDay = result;
        _isModified = true;
      });
    }

    controller.dispose();
  }

  // 새 단어 추가
  Future<void> _addNewWord() async {
    // 빈 컨트롤러들 생성
    final wordController = TextEditingController();
    final pronunciationController = TextEditingController();
    final meaningController = TextEditingController();
    final exampleController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('새 단어 추가'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordController,
                decoration: InputDecoration(
                  labelText: '단어',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: pronunciationController,
                decoration: InputDecoration(
                  labelText: '발음',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: meaningController,
                decoration: InputDecoration(
                  labelText: '의미',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: exampleController,
                decoration: InputDecoration(
                  labelText: '예문 (선택사항)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (wordController.text.trim().isEmpty ||
                  meaningController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('단어와 의미는 필수입니다.')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: Text('추가'),
          ),
        ],
      ),
    );

    if (result == true) {
      // 예문 처리
      List<String> examples = [];
      if (exampleController.text.trim().isNotEmpty) {
        examples.add(exampleController.text.trim());
      }

      // 새 단어 추가
      setState(() {
        _editableWords.add(WordEntry(
          word: wordController.text.trim(),
          pronunciation: pronunciationController.text.trim(),
          meaning: meaningController.text.trim(),
          examples: examples,
          day: _currentDay,
        ));
        _isModified = true;
      });
    }

    // 컨트롤러 정리
    wordController.dispose();
    pronunciationController.dispose();
    meaningController.dispose();
    exampleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 새 단어 목록 확인
    final hasNewWords = widget.newWords != null && widget.newWords!.isNotEmpty;

    // 새 단어의 단어 텍스트만 추출 (비교용)
    final newWordTexts =
        hasNewWords ? widget.newWords!.map((w) => w.word).toSet() : <String>{};
    return Scaffold(
      appBar: AppBar(
        title: Text('단어장 편집'),
        actions: [
          IconButton(
            icon: Icon(Icons.drive_file_rename_outline),
            tooltip: '단어장 이름 변경',
            onPressed: _changeDayName,
          ),
          IconButton(
            icon: Icon(Icons.add),
            tooltip: '단어 추가',
            onPressed: _addNewWord,
          ),
        ],
      ),
      body: Column(
        children: [
          // 단어장 정보
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentDay,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '총 ${_editableWords.length}개 단어',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                if (_isModified)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '변경사항이 있습니다. 저장 버튼을 눌러 적용하세요.',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                // 새 단어가 있는 경우 안내 메시지 추가
                if (hasNewWords)
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.amber.shade900.withOpacity(0.3)
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber.shade700
                            : Colors.amber.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.amber.shade300
                              : Colors.amber.shade800,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '새로 추가된 ${widget.newWords!.length}개의 단어는 하이라이트 표시됩니다.',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Divider(),

          // 단어 목록
          Expanded(
            child: _editableWords.isEmpty
                ? Center(
                    child: Text('단어가 없습니다. 우측 상단의 + 버튼을 눌러 단어를 추가하세요.'),
                  )
                : ReorderableListView.builder(
                    itemCount: _editableWords.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final word = _editableWords.removeAt(oldIndex);
                        _editableWords.insert(newIndex, word);
                        _isModified = true;
                      });
                    },
                    itemBuilder: (context, index) {
                      final word = _editableWords[index];
                      final isNewWord =
                          newWordTexts.contains(word.word); // 새로 추가한 부분
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
                              action: SnackBarAction(
                                label: '되돌리기',
                                onPressed: () {
                                  setState(() {
                                    _editableWords.insert(index, word);
                                    _isModified = true;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          color: isNewWord
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.amber.shade900.withOpacity(0.3)
                                  : Colors.amber.shade50)
                              : null, // 기존 단어는 기본 색상 사용
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isNewWord
                                ? BorderSide(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.amber.shade700
                                        : Colors.amber.shade200,
                                    width: 1.5,
                                  )
                                : BorderSide(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                  ),
                          ),
                          child: ListTile(
                            title: Row(
                              children: [
                                if (isNewWord)
                                  Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.amber.shade800
                                          : Colors.amber.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'NEW',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.black
                                            : Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    word.word,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (word.pronunciation.isNotEmpty)
                                  Text(
                                    word.pronunciation,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                Text(word.meaning),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.reorder),
                                  tooltip: '순서 변경',
                                  onPressed: null, // ReorderableListView에서 사용
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  tooltip: '수정',
                                  onPressed: () => _editWord(index),
                                ),
                              ],
                            ),
                            onTap: () => _editWord(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // lib/screens/word_edit_screen.dart 파일의 bottomNavigationBar 위젯 수정
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.isFromImageRecognition)
                // 다시 인식하기 버튼을 OutlinedButton으로 변경
                OutlinedButton.icon(
                  onPressed: () {
                    // 사용자에게 확인 다이얼로그 표시
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('다시 인식하기'),
                        content: Text('현재 단어장 편집을 취소하고 같은 이미지로 다시 인식하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('취소'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // 다이얼로그 닫기
                              Navigator.of(context).pop();
                              // 이전 화면으로 돌아가되, 다시 인식 시도 요청
                              // 크레딧 소모없이 동일한 이미지로 다시 시도하도록 신호 전달
                              Navigator.of(context).pop({'retry': true});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: Text('다시 인식하기'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('다시 인식하기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.shade300
                            : Colors.blue.shade700,
                  ),
                )
              else
                const SizedBox(),
              ElevatedButton(
                // 항상 활성화 (조건 제거)
                onPressed: () {
                  // 저장할 단어가 없는 경우 경고
                  if (_editableWords.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('저장할 단어가 없습니다.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // 수정된 단어와 DAY 이름을 함께 반환
                  Navigator.of(context).pop({
                    'words': _editableWords,
                    'dayName': _currentDay,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.shade600 // 다크모드에서는 밝은 초록색
                          : Colors.green, // 라이트모드에서는 기본 초록색
                  foregroundColor: Colors.white, // 텍스트는 항상 흰색으로
                ),
                child: Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
