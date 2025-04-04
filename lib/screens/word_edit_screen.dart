import 'package:flutter/material.dart';
import '../model/word_entry.dart';

class WordEditScreen extends StatefulWidget {
  final List<WordEntry> words;
  final String dayName;

  const WordEditScreen({
    Key? key,
    required this.words,
    required this.dayName,
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
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            title: Text(
                              word.word,
                              style: TextStyle(fontWeight: FontWeight.bold),
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
              OutlinedButton(
                onPressed: () {
                  // '취소' 대신 '다시 시도' 버튼으로 변경
                  // 이전 화면으로 돌아가되, 다시 인식 시도 요청
                  Navigator.of(context).pop({'retry': true});
                },
                child: Text('다시 인식하기'),
              ),
              ElevatedButton(
                // 항상 활성화 (조건 제거)
                onPressed: () {
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
