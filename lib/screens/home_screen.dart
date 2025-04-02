import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocabulary_app/screens/word_edit_screen.dart';
import 'package:vocabulary_app/widgets/modern_flash_card_screen.dart';
import 'package:vocabulary_app/widgets/modern_quiz_card_screen.dart';
import '../model/word_entry.dart';
import '../services/openai_vision_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/api_key_service.dart';
import '../widgets/word_card_widget.dart';
import 'settings_screen.dart';
import 'test_demo_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final TtsService _ttsService = TtsService();
  final ApiKeyService _apiKeyService = ApiKeyService();
  int _processedImages = 0; // 처리된 이미지 수
  int _totalImagesToProcess = 0; // 총 처리할 이미지 수
  int _extractedWordsCount = 0; // 추출된 단어 수
  bool _showDetailedProgress = false; // 상세 진행 상태 표시 여부

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
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _storageService.validateStorage();
    print('홈 화면 초기화 - 저장된 단어 로드 시작');
    _loadSavedWords();
    print('홈 화면 초기화 - API 초기화 시작');
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
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // 앱이 백그라운드로 이동할 때
      print('앱이 백그라운드로 이동, 데이터 저장 확인');
      _storageService.validateStorage();
    }

    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아올 때
      print('앱이 포그라운드로 복귀, 데이터 재로드');
      _loadSavedWords();
    }
  }

// lib/screens/home_screen.dart의 _loadSavedWords() 함수 수정
  Future<void> _loadSavedWords() async {
    try {
      print('단어 로드 시작');

      // 모든 DAY 컬렉션 정보 로드
      final dayCollections = await _storageService.getAllDays();
      print('DAY 컬렉션 로드 완료: ${dayCollections.keys.length}개');

      // 모든 단어 로드
      final allWords = await _storageService.getAllWords();
      print('로드된 단어 수: ${allWords.length}');

      // DAY별로 그룹화
      Map<String, List<WordEntry>> collections = {};

      // 모든 단어를 day별로 분류
      for (var word in allWords) {
        if (word.day != null) {
          if (!collections.containsKey(word.day)) {
            collections[word.day!] = [];
          }
          collections[word.day!]?.add(word);
          print('단어 "${word.word}" 를 "${word.day}" 컬렉션에 추가');
        } else {
          // day가 null인 단어도 임시 컬렉션에 추가 (옵션)
          if (!collections.containsKey('기타')) {
            collections['기타'] = [];
          }
          collections['기타']?.add(word);
          print('day가 null인 단어 "${word.word}" 를 "기타" 컬렉션에 추가');
        }
      }

      // 단어가 없는 컬렉션도 추가 (dayCollections에 있는 모든 키)
      for (var dayName in dayCollections.keys) {
        if (!collections.containsKey(dayName)) {
          collections[dayName] = [];
          print('빈 컬렉션 생성: $dayName');
        }
      }

      // 각 컬렉션별 단어 수 출력 (디버깅용)
      collections.forEach((day, words) {
        print('$day: ${words.length}개 단어');
      });

      // 상태 업데이트
      setState(() {
        _dayCollections = collections;

        // 가장 최근 DAY 설정
        if (collections.isNotEmpty) {
          // 일단 첫 번째 키 사용
          _currentDay = collections.keys.first;
          print('현재 DAY 설정: $_currentDay');
        }
      });

      print('단어 로드 완료');
    } catch (e) {
      print('단어 로드 중 오류: $e');
    }
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
      // 선택된 이미지가 6개 이상이면 처리
      if (images.length > 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 6장까지만 선택할 수 있습니다. 처음 6장만 사용됩니다.')),
        );
        // 6개까지만 잘라서 사용
        setState(() {
          _batchImages =
              images.sublist(0, 6).map((img) => File(img.path)).toList();
        });
      } else {
        setState(() {
          _batchImages = images.map((img) => File(img.path)).toList();
        });
      }

      // 이미지 처리 시작
      _processBatchImages();
    }
  }

  void _showMoreImagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
          content:
              const Text('OpenAI API 키가 설정되지 않았습니다. 설정 화면에서 API 키를 입력해주세요.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
      _showDetailedProgress = true;
      _processedImages = 0;
      _totalImagesToProcess = _batchImages.length;
      _extractedWordsCount = 0;
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
    for (var i = 0; i < _batchImages.length; i++) {
      try {
        setState(() {
          _processedImages = i + 1;
        });

        if (_isUsingOpenAI && _openAIService != null) {
          List<WordEntry> words =
              await _openAIService!.extractWordsFromImage(_batchImages[i]);
          allWords.addAll(words);

          setState(() {
            _extractedWordsCount += words.length;
          });
        }
      } catch (e) {
        print('이미지 처리 중 오류: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 처리 중 오류가 발생했습니다: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }

    setState(() {
      _isProcessing = false;
      _batchImages = []; // 배치 이미지 초기화
    });

    if (allWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('단어를 추출하지 못했습니다. 다른 이미지를 시도해보세요.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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

// _processBatchImages 함수 수정

// 편집 화면에서 돌아왔을 때 저장 처리
// 편집 화면에서 돌아왔을 때 저장 처리 부분 수정
    if (result != null && result is Map) {
      try {
        final List<WordEntry> editedWords = result['words'];
        final String dayName = result['dayName'];

        print('단어 편집 결과: ${editedWords.length}개 단어, DAY: $dayName');

        // DAY 이름이 변경되었다면 처리
        if (dayName != _currentDay) {
          print('DAY 이름 변경: $_currentDay -> $dayName');
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

        // 상태 업데이트 - 즉시 반영
        setState(() {
          if (!_dayCollections.containsKey(dayName)) {
            _dayCollections[dayName] = [];
            print('새 컬렉션 생성: $dayName');
          }

          // 새 단어로 기존 단어 교체
          _dayCollections[dayName] = List.from(editedWords);
          print('$dayName 컬렉션 업데이트: ${editedWords.length}개 단어');
        });

        // 기존 데이터 다시 로드 (확실한 동기화를 위해)
        _loadSavedWords();

        // 완료 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${editedWords.length}개의 단어가 저장되었습니다.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // 약간의 지연 후 단어장 탭으로 전환
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _tabController.animateTo(1); // 인덱스 1이 단어장 탭
          }
        });
      } catch (e) {
        print('단어 저장 중 오류: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단어 저장 중 오류가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('단어장 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('이 단어들을 저장할 DAY를 입력하세요'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '예: DAY 1',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('취소', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('확인'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          '영어 단어 학습',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black54),
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
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.w600),
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

  // 이미지 캡처 탭 UI - 모던한 디자인으로 수정
  Widget _buildCaptureTab() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_batchImages.isNotEmpty)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, color: Colors.blue.shade700),
                        SizedBox(width: 8),
                        Text(
                          '${_batchImages.length}장의 이미지가 선택됨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _batchImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image.file(
                                    _batchImages[index],
                                    width: 150,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _batchImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.all(24),
                      child: Icon(
                        Icons.image_search,
                        size: 20,
                        color: Colors.blue.shade300,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '교재나 단어장 이미지를 촬영하거나 갤러리에서 선택하세요',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '(최대 6장까지 한 번에 처리 가능)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 22),
                    if (_isUsingOpenAI)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.shade100,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'OpenAI 사용 중',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.shade100,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'API 키가 필요합니다',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SettingsScreen()),
                                ).then((_) => _initializeOpenAI());
                              },
                              child: Text('API 키 설정하기'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.orange.shade300),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // 단어장 테스트 버튼 추가
                    OutlinedButton.icon(
                      onPressed: _runWordImageTest,
                      icon: Icon(Icons.science),
                      label: Text('단어장 인식 테스트'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
// 진행 상태 표시 위젯 수정
          if (_isProcessing)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                if (_showDetailedProgress) ...[
                  Text('이미지 처리 중: $_processedImages / $_totalImagesToProcess'),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _processedImages / _totalImagesToProcess,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 16),
                  Text('추출된 단어: $_extractedWordsCount개'),
                ] else
                  Text('이미지에서 단어를 추출하는 중...'),
              ],
            ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('촬영하기'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.limeAccent,
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('갤러리'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.amberAccent,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_batchImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _batchImages = [];
                          });
                        },
                        child: Text('모든 이미지 초기화'),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// 단어장 탭 UI - 모던한 디자인으로 수정
  Widget _buildWordListTab() {
    if (_dayCollections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 24),
            Text(
              '단어장이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '이미지를 촬영하여 단어를 추가하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(0); // 단어 추가 탭으로 이동
              },
              icon: Icon(Icons.add_photo_alternate),
              label: Text('단어 추가하기'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // DAY 선택 드롭다운 및 관리 버튼
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '단어장 선택',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _dayCollections.keys.contains(_currentDay)
                              ? _currentDay
                              : _dayCollections.keys.first,
                          items: _dayCollections.keys.map((String day) {
                            final count = _dayCollections[day]?.length ?? 0;
                            return DropdownMenuItem<String>(
                              value: day,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(day),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '$count단어',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _currentDay = newValue;
                              });
                            }
                          },
                          icon: Icon(Icons.keyboard_arrow_down),
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red.shade700),
                      tooltip: '단어장 삭제',
                      onPressed: () => _showDeleteDayDialog(_currentDay),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // // 단어 검색 필드 추가
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //   child: TextField(
        //     decoration: InputDecoration(
        //       hintText: '단어 검색',
        //       prefixIcon: Icon(Icons.search),
        //       filled: true,
        //       fillColor: Colors.grey.shade100,
        //       border: OutlineInputBorder(
        //         borderRadius: BorderRadius.circular(12),
        //         borderSide: BorderSide.none,
        //       ),
        //       contentPadding: EdgeInsets.symmetric(vertical: 0),
        //     ),
        //     onChanged: (value) {
        //       // 검색 기능 구현 (향후 기능)
        //     },
        //   ),
        // ),

        // 단어 통계 정보 표시
        if (_dayCollections[_currentDay]?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildStatCard(
                  '총 단어',
                  '${_dayCollections[_currentDay]?.length ?? 0}',
                  Colors.blue,
                  Icons.format_list_numbered,
                ),
                SizedBox(width: 12),
                _buildStatCard(
                  '암기 완료',
                  '${_dayCollections[_currentDay]?.where((w) => w.isMemorized).length ?? 0}',
                  Colors.green,
                  Icons.check_circle,
                ),
              ],
            ),
          ),

        // 선택된 DAY의 단어 목록
        Expanded(
          child: _dayCollections[_currentDay]?.isEmpty ?? true
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_add,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '$_currentDay에 저장된 단어가 없습니다.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _tabController.animateTo(0); // 단어 추가 탭으로 이동
                        },
                        child: Text('단어 추가하기'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: 24),
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

// 통계 카드 위젯
  Widget _buildStatCard(
      String title, String value, MaterialColor color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color.shade700, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// 단어장 삭제 다이얼로그
// lib/screens/home_screen.dart의 _showDeleteDayDialog 함수 수정
// lib/screens/home_screen.dart의 _showDeleteDayDialog 함수 수정
  Future<void> _showDeleteDayDialog(String dayName) async {
    // "기타" 단어장은 day가 null인 단어들의 모음
    final bool isNullDayCollection = dayName == '기타';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            SizedBox(width: 8),
            Text('단어장 삭제'),
          ],
        ),
        content: Text(
            '$dayName 단어장을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없으며, 해당 단어장의 모든 단어가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 단어장 삭제 전 해당 단어장의 단어 수 확인
        final wordsCount = _dayCollections[dayName]?.length ?? 0;
        print('단어장 "$dayName" 삭제 시작 (UI): $wordsCount개 단어 포함');

        if (isNullDayCollection) {
          // "기타" 단어장 처리 (day가 null인 단어들 삭제)
          print('"기타" 단어장 삭제 - day가 null인 단어들 삭제');

          // day가 null인 단어들 모두 삭제
          await _storageService.deleteNullDayWords();

          print('day가 null인 단어 삭제 완료');
        } else {
          // 일반 단어장 삭제 처리
          await _storageService.deleteDay(dayName);
        }

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

        // 저장소 상태 확인
        await _storageService.validateStorage();

        // 데이터 다시 로드
        await _loadSavedWords();

        // 완료 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$dayName 단어장이 삭제되었습니다. ($wordsCount개 단어 함께 삭제)'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        print('단어장 삭제 중 오류 (UI): $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단어장 삭제 중 오류가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

// 플래시카드 탭 UI - 모던한 디자인으로 수정
  Widget _buildFlashCardTab() {
    if (_dayCollections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style,
              size: 80,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 24),
            Text(
              '단어장이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '먼저 단어를 추가해주세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(0); // 단어 추가 탭으로 이동
              },
              icon: Icon(Icons.add_photo_alternate),
              label: Text('단어 추가하기'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // 단어장 선택 영역 추가
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '플래시카드 학습',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _dayCollections.keys.contains(_currentDay)
                        ? _currentDay
                        : _dayCollections.keys.first,
                    items: _dayCollections.keys.map((String day) {
                      final count = _dayCollections[day]?.length ?? 0;
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(day),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$count단어',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _currentDay = newValue;
                        });
                      }
                    },
                    icon: Icon(Icons.keyboard_arrow_down),
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 단어 개수 정보 표시 (선택된 단어장에 단어가 없는 경우 처리)
        if (_dayCollections[_currentDay]?.isEmpty ?? true)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '$_currentDay에 저장된 단어가 없습니다.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _tabController.animateTo(0); // 단어 추가 탭으로 이동
                    },
                    child: Text('단어 추가하기'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // 플래시카드 화면
          Expanded(
            child: ModernFlashCardScreen(
              words: _dayCollections[_currentDay] ?? [],
              onSpeakWord: _speakWord,
              onReviewComplete: (String wordText) async {
                await _storageService.incrementReviewCount(wordText);
                // 상태 업데이트는 필요하면 여기서 처리
              },
            ),
          ),
      ],
    );
  }

// 퀴즈 탭 UI - 모던한 디자인으로 수정
  Widget _buildQuizTab() {
    if (_dayCollections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 80,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 24),
            Text(
              '단어장이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '먼저 단어를 추가해주세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(0); // 단어 추가 탭으로 이동
              },
              icon: Icon(Icons.add_photo_alternate),
              label: Text('단어 추가하기'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // 단어장 선택 영역 추가
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '퀴즈 모드',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
// _buildWordListTab() 함수 내부 수정 부분

// 상단 드롭다운 메뉴 표시 부분
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _dayCollections.keys.contains(_currentDay)
                              ? _currentDay
                              : (_dayCollections.keys.isNotEmpty
                                  ? _dayCollections.keys.first
                                  : null),
                          items: _dayCollections.keys.map((String day) {
                            final count = _dayCollections[day]?.length ?? 0;
                            print('드롭다운 항목: $day ($count단어)'); // 디버깅용
                            return DropdownMenuItem<String>(
                              value: day,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(day),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '$count단어',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _currentDay = newValue;
                                print(
                                    '선택된 DAY 변경: $_currentDay (${_dayCollections[_currentDay]?.length ?? 0}단어)');
                              });
                            }
                          },
                          icon: Icon(Icons.keyboard_arrow_down),
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 퀴즈 내용
        Expanded(
          child: ModernQuizScreen(
            words: _dayCollections[_currentDay] ?? [],
            allWords: _dayCollections.values.fold<List<WordEntry>>(
              [],
              (list, words) => list..addAll(words),
            ),
            onSpeakWord: _speakWord,
          ),
        ),
      ],
    );
  }
}
