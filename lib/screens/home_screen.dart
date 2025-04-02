import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocabulary_app/screens/word_edit_screen.dart';
import '../model/word_entry.dart';
import '../services/openai_vision_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/api_key_service.dart';
import '../widgets/word_card_widget.dart';
import 'flash_card_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';
import 'test_demo_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final TtsService _ttsService = TtsService();
  final ApiKeyService _apiKeyService = ApiKeyService();

  OpenAIVisionService? _openAIService;
  bool _isUsingOpenAI = false;

  bool _isProcessing = false;
  List<File> _batchImages = [];
  String _currentDay = 'DAY 1';
  Map<String, List<WordEntry>> _dayCollections = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSavedWords();
    _initializeOpenAI();
  }

  Future<void> _initializeOpenAI() async {
    final apiKey = await _apiKeyService.getOpenAIApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      _openAIService = OpenAIVisionService(apiKey: apiKey);
      setState(() {
        _isUsingOpenAI = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

// _loadSavedWords 메서드에서 수정이 필요한 부분
  void _loadSavedWords() {
    // 모든 단어 로드
    final allWords = _storageService.getAllWords();

    // DAY별로 그룹화
    Map<String, List<WordEntry>> collections = {};

    for (var word in allWords) {
      if (word.day != null) {
        if (!collections.containsKey(word.day)) {
          collections[word.day!] = [];
        }
        collections[word.day!]?.add(word);
      }
    }

    // DAY 컬렉션 정보 로드
    final dayCollections = _storageService.getAllDays();

    // 단어는 없지만 컬렉션 정보는 있는 경우도 포함
    for (var dayName in dayCollections.keys) {
      if (!collections.containsKey(dayName)) {
        collections[dayName] = [];
      }
    }

    setState(() {
      _dayCollections = collections;

      // 가장 최근 DAY 설정 (안전하게 수정)
      if (collections.isNotEmpty) {
        try {
          final validDays = collections.keys.where((day) {
            // DAY 뒤에 숫자만 있는지 확인
            final match = RegExp(r'DAY\s+(\d+)').firstMatch(day);
            return match != null;
          }).toList();

          if (validDays.isNotEmpty) {
            validDays.sort((a, b) {
              // 정규식으로 숫자 부분만 추출
              final numA = int.parse(
                  RegExp(r'DAY\s+(\d+)').firstMatch(a)?.group(1) ?? '0');
              final numB = int.parse(
                  RegExp(r'DAY\s+(\d+)').firstMatch(b)?.group(1) ?? '0');
              return numA.compareTo(numB);
            });
            _currentDay = validDays.last;
          } else if (collections.keys.isNotEmpty) {
            _currentDay = collections.keys.first; // 유효한 날짜가 없으면 첫 번째 키 사용
          }
        } catch (e) {
          print('DAY 정렬 중 오류 발생: $e');
          if (collections.keys.isNotEmpty) {
            _currentDay = collections.keys.first; // 오류 발생 시 첫 번째 키 사용
          }
        }
      }
    });
  }

  // 단어장 이미지 테스트 실행
  Future<void> _runWordImageTest() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // 최고 품질로 이미지 선택
    );

    if (image != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestDemoScreen(imageFile: File(image.path)),
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _batchImages.add(File(photo.path));
      });

      // 사용자에게 더 촬영할지 묻는 다이얼로그
      if (_batchImages.length < 6) {
        _showMoreImagesDialog();
      } else {
        _processBatchImages();
      }
    }
  }

  Future<void> _pickImage() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _batchImages.addAll(images.map((img) => File(img.path)));
      });

      if (_batchImages.length > 6) {
        // 최대 6장으로 제한
        _batchImages = _batchImages.sublist(0, 6);
      }

      // 다중 이미지 처리 시작
      _processBatchImages();
    }
  }

  void _showMoreImagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('추가 이미지'),
        content: Text('현재 ${_batchImages.length}장의 이미지가 있습니다. 더 촬영하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processBatchImages();
            },
            child: Text('완료'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _takePhoto();
            },
            child: Text('더 촬영하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _processBatchImages() async {
    // API 키 확인
    if (_isUsingOpenAI && _openAIService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OpenAI API 키가 설정되지 않았습니다. 설정 화면에서 API 키를 입력해주세요.'),
          action: SnackBarAction(
            label: '설정',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              ).then((_) => _initializeOpenAI());
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // DAY 입력 다이얼로그 표시
    final String? selectedDay = await _showDaySelectionDialog();
    if (selectedDay == null) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    _currentDay = selectedDay;

    // 각 이미지 처리
    List<WordEntry> allWords = [];
    for (var img in _batchImages) {
      try {
        List<WordEntry> words;

        if (_isUsingOpenAI && _openAIService != null) {
          // OpenAI 비전 API 사용
          words = await _openAIService!.extractWordsFromImage(img);
        }
      } catch (e) {
        print('이미지 처리 중 오류: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 처리 중 오류가 발생했습니다: ${e.toString()}')),
        );
      }
    }

    setState(() {
      _isProcessing = false;
      _batchImages = []; // 배치 이미지 초기화
    });

    if (allWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('단어를 추출하지 못했습니다. 다른 이미지를 시도해보세요.')),
      );
      return;
    }

    // 중복 제거 (같은 단어는 하나만 저장)
    final Map<String, WordEntry> uniqueWords = {};
    for (var word in allWords) {
      uniqueWords[word.word] = word;
    }

    // 단어 편집 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordEditScreen(
          words: uniqueWords.values.toList(),
          dayName: _currentDay,
        ),
      ),
    );

    // 편집 화면에서 돌아왔을 때 저장 처리
    if (result != null && result is Map) {
      final List<WordEntry> editedWords = result['words'];
      final String dayName = result['dayName'];

      // DAY 이름이 변경되었다면 처리
      if (dayName != _currentDay) {
        // 새 단어장에 모두 저장
        for (var i = 0; i < editedWords.length; i++) {
          editedWords[i] = editedWords[i].copyWith(day: dayName);
        }

        // DAY 이름 업데이트
        _currentDay = dayName;
      }

      // 저장
      await _storageService.saveWords(editedWords);

      // DAY 컬렉션 정보 저장
      await _storageService.saveDayCollection(dayName, editedWords.length);

      // 상태 업데이트
      if (!_dayCollections.containsKey(dayName)) {
        _dayCollections[dayName] = [];
      }

      // 기존 단어 제거 후 새 단어 추가
      _dayCollections[dayName] = editedWords;

      // 완료 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${editedWords.length}개의 단어가 저장되었습니다.')),
      );

      // 단어장 탭으로 전환
      _tabController.animateTo(1); // 인덱스 1이 단어장 탭
    }
  }

  Future<String?> _showDaySelectionDialog() async {
    // 다음 DAY 번호 계산 - 안전하게 수정
    int nextDayNum = 1;

    if (_dayCollections.isNotEmpty) {
      try {
        // 유효한 DAY 형식의 키만 필터링
        List<int> validDayNumbers = [];

        for (var day in _dayCollections.keys) {
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

    final String suggestedDay = 'DAY $nextDayNum';
    final TextEditingController controller =
        TextEditingController(text: suggestedDay);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('단어장 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('이 단어들을 저장할 DAY를 입력하세요'),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '예: DAY 1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // 단어 발음 듣기
// 단어 발음 듣기 (액센트 선택 기능 추가)
  Future<void> _speakWord(String word, {AccentType? accent}) async {
    try {
      await _ttsService.speak(word, accent: accent);
    } catch (e) {
      print('단어 발음 중 오류: $e');
      // 오류 발생 시 사용자에게 안내
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('발음 재생 중 오류가 발생했습니다.'),
          action: SnackBarAction(
            label: '재시도',
            onPressed: () => _speakWord(word, accent: accent),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영어 단어 학습'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              ).then((_) => _initializeOpenAI());
            },
            tooltip: '설정',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: '단어 추가'),
            Tab(icon: Icon(Icons.book), text: '단어장'),
            Tab(icon: Icon(Icons.quiz), text: '플래시카드'),
            Tab(icon: Icon(Icons.games), text: '퀴즈'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 첫 번째 탭: 이미지 캡처 및 처리
          _buildCaptureTab(),

          // 두 번째 탭: 단어장 (DAY별 정렬)
          _buildWordListTab(),

          // 세 번째 탭: 플래시카드
          _buildFlashCardTab(),

          // 네 번째 탭: 퀴즈
          _buildQuizTab(),
        ],
      ),
    );
  }

  // 이미지 캡처 탭 UI
  Widget _buildCaptureTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_batchImages.isNotEmpty)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    '${_batchImages.length}장의 이미지가 선택됨',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _batchImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Image.file(
                            _batchImages[index],
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  if (_batchImages.length > 1)
                    ElevatedButton(
                      onPressed: _processBatchImages,
                      child: Text('모든 이미지 처리하기'),
                    ),
                ],
              ),
            ),
          )
        else
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '교재나 단어장 이미지를 촬영하거나 갤러리에서 선택하세요\n(최대 6장까지 한 번에 처리 가능)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  if (_isUsingOpenAI)
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(height: 8),
                            Text(
                              'OpenAI Vision API 사용 중',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '이미지에서 더 정확한 단어 인식이 가능합니다',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(height: 8),
                            Text(
                              '기본 OCR 사용 중',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '더 나은 인식을 위해 설정에서 OpenAI API 키를 설정하세요',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SettingsScreen()),
                                ).then((_) => _initializeOpenAI());
                              },
                              child: Text('API 키 설정하기'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  // 단어장 테스트 버튼 추가
                  OutlinedButton.icon(
                    onPressed: _runWordImageTest,
                    icon: Icon(Icons.science),
                    label: Text('단어장 인식 테스트'),
                    style: OutlinedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_isProcessing)
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
              Text('이미지에서 단어를 추출하는 중...'),
            ],
          ),
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('촬영하기'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('갤러리'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        if (_batchImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _batchImages = [];
                });
              },
              child: Text('초기화'),
            ),
          ),
      ],
    );
  }

// 단어장 탭 UI
// 단어장 탭 UI에 삭제 기능 추가
  Widget _buildWordListTab() {
    if (_dayCollections.isEmpty) {
      return Center(child: Text('단어가 없습니다. 이미지를 촬영하여 단어를 추가하세요.'));
    }

    return Column(
      children: [
        // DAY 선택 드롭다운 및 관리 버튼
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _dayCollections.keys.contains(_currentDay)
                      ? _currentDay
                      : _dayCollections.keys.first,
                  items: _dayCollections.keys.map((String day) {
                    final count = _dayCollections[day]?.length ?? 0;
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text('$day ($count단어)'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentDay = newValue;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                tooltip: '단어장 삭제',
                onPressed: () => _showDeleteDayDialog(_currentDay),
              ),
            ],
          ),
        ),

        // 선택된 DAY의 단어 목록
        Expanded(
          child: _dayCollections[_currentDay]?.isEmpty ?? true
              ? Center(child: Text('$_currentDay에 저장된 단어가 없습니다.'))
              : ListView.builder(
                  itemCount: _dayCollections[_currentDay]?.length ?? 0,
                  itemBuilder: (context, index) {
                    final word = _dayCollections[_currentDay]![index];

                    // 단어 카드 위젯 사용
                    return WordCardWidget(
                      word: word,
                      onSpeakWord: _speakWord,
                      onUpdateMemorizedStatus:
                          (String wordText, bool isMemorized) async {
                        await _storageService.updateMemorizedStatus(
                            wordText, isMemorized);

                        setState(() {
                          // 단어장 목록에서 업데이트
                          final index =
                              _dayCollections[_currentDay]!.indexOf(word);
                          if (index >= 0) {
                            _dayCollections[_currentDay]![index] =
                                word.copyWith(isMemorized: isMemorized);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 단어장 삭제 다이얼로그
  Future<void> _showDeleteDayDialog(String dayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('단어장 삭제'),
        content: Text(
            '$dayName 단어장을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없으며, 해당 단어장의 모든 단어가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 단어장 삭제 처리
      await _storageService.deleteDay(dayName);

      // 상태 업데이트
      setState(() {
        _dayCollections.remove(dayName);

        // 다른 단어장으로 이동
        if (_dayCollections.isEmpty) {
          _currentDay = 'DAY 1'; // 기본값 설정
        } else {
          _currentDay = _dayCollections.keys.first;
        }
      });

      // 완료 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$dayName 단어장이 삭제되었습니다.')),
      );
    }
  }

  // 플래시카드 탭 UI
  Widget _buildFlashCardTab() {
    if (_dayCollections.isEmpty) {
      return Center(child: Text('단어가 없습니다. 이미지를 촬영하여 단어를 추가하세요.'));
    }

    return FlashCardScreen(
      words: _dayCollections[_currentDay] ?? [],
      onSpeakWord: _speakWord,
      onReviewComplete: (String wordText) async {
        await _storageService.incrementReviewCount(wordText);
        // 상태 갱신은 필요하면 여기에 추가
      },
    );
  }

  // 퀴즈 탭 UI
  Widget _buildQuizTab() {
    if (_dayCollections.isEmpty) {
      return Center(child: Text('단어가 없습니다. 이미지를 촬영하여 단어를 추가하세요.'));
    }

    // 모든 DAY의 단어 합치기 (다른 DAY의 단어도 퀴즈 보기에 사용)
    List<WordEntry> allWords = [];
    for (var words in _dayCollections.values) {
      allWords.addAll(words);
    }

    return QuizScreen(
      words: _dayCollections[_currentDay] ?? [],
      allWords: allWords,
      onSpeakWord: _speakWord,
    );
  }
}
