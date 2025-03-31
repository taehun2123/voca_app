import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../model/word_entry.dart';
import '../services/ocr_service.dart';
import '../services/openai_vision_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/api_key_service.dart';
import 'flash_card_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
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
    _ocrService.dispose();
    _tabController.dispose();
    _ttsService.dispose();
    super.dispose();
  }
  
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
      
      // 가장 최근 DAY 설정
      if (collections.isNotEmpty) {
        final days = collections.keys.toList()
          ..sort((a, b) => int.parse(a.replaceAll('DAY ', ''))
              .compareTo(int.parse(b.replaceAll('DAY ', ''))));
        _currentDay = days.last;
      }
    });
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
    if (selectedDay != null) {
      _currentDay = selectedDay;
    }
    
    // 각 이미지 처리
    List<WordEntry> allWords = [];
    for (var img in _batchImages) {
      try {
        List<WordEntry> words;
        
        if (_isUsingOpenAI && _openAIService != null) {
          // OpenAI 비전 API 사용
          words = await _openAIService!.extractWordsFromImage(img);
        } else {
          // 기존 OCR 서비스 사용
          words = await _ocrService.extractWordsFromImage(img);
        }
        
        // 현재 DAY 설정
        for (var word in words) {
          word = word.copyWith(day: _currentDay);
        }
        
        allWords.addAll(words);
      } catch (e) {
        print('이미지 처리 중 오류: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 처리 중 오류가 발생했습니다: ${e.toString()}')),
        );
      }
    }
    
    // 중복 제거 (같은 단어는 하나만 저장)
    final Map<String, WordEntry> uniqueWords = {};
    for (var word in allWords) {
      uniqueWords[word.word] = word;
    }
    
    // 저장
    await _storageService.saveWords(uniqueWords.values.toList());
    
    // DAY 컬렉션 정보 저장
    await _storageService.saveDayCollection(_currentDay, uniqueWords.length);
    
    // 상태 업데이트
    if (!_dayCollections.containsKey(_currentDay)) {
      _dayCollections[_currentDay] = [];
    }
    _dayCollections[_currentDay]!.addAll(uniqueWords.values);
    
    setState(() {
      _isProcessing = false;
      _batchImages = []; // 배치 이미지 초기화
    });
    
    // 완료 메시지
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${uniqueWords.length}개의 단어가 저장되었습니다.')),
    );
  }
  
  Future<String?> _showDaySelectionDialog() async {
    // 다음 DAY 번호 계산
    int nextDayNum = 1;
    if (_dayCollections.isNotEmpty) {
      final lastDay = _dayCollections.keys
        .map((day) => int.parse(day.replaceAll('DAY ', '')))
        .reduce((a, b) => a > b ? a : b);
      nextDayNum = lastDay + 1;
    }
    
    final String suggestedDay = 'DAY $nextDayNum';
    final TextEditingController controller = TextEditingController(text: suggestedDay);
    
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
  Future<void> _speakWord(String word) async {
    await _ttsService.speak(word);
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
                                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                                ).then((_) => _initializeOpenAI());
                              },
                              child: Text('API 키 설정하기'),
                            ),
                          ],
                        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('갤러리'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
  Widget _buildWordListTab() {
    if (_dayCollections.isEmpty) {
      return Center(child: Text('단어가 없습니다. 이미지를 촬영하여 단어를 추가하세요.'));
    }
    
    return Column(
      children: [
        // DAY 선택 드롭다운
        Padding(
          padding: const EdgeInsets.all(10),
          child: DropdownButton<String>(
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
        
        // 선택된 DAY의 단어 목록
        Expanded(
          child: _dayCollections[_currentDay]?.isEmpty ?? true
              ? Center(child: Text('$_currentDay에 저장된 단어가 없습니다.'))
              : ListView.builder(
                  itemCount: _dayCollections[_currentDay]?.length ?? 0,
                  itemBuilder: (context, index) {
                    final word = _dayCollections[_currentDay]![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                word.word,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.volume_up),
                              onPressed: () => _speakWord(word.word),
                              tooltip: '발음 듣기',
                            ),
                            if (word.isMemorized)
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                          ],
                        ),
                        subtitle: Text('${word.pronunciation} - ${word.meaning}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (word.examples.isNotEmpty) ...[
                                  const Text(
                                    '예문:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  ...word.examples.map((example) => Padding(
                                        padding: const EdgeInsets.only(bottom: 5),
                                        child: Text('• $example'),
                                      )),
                                  const SizedBox(height: 10),
                                ],
                                if (word.commonPhrases.isNotEmpty) ...[
                                  const Text(
                                    '기출 표현:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  ...word.commonPhrases.map((phrase) => Padding(
                                        padding: const EdgeInsets.only(bottom: 5),
                                        child: Text('• $phrase'),
                                      )),
                                ],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: Icon(word.isMemorized ? Icons.check_circle : Icons.check_circle_outline),
                                      label: Text(word.isMemorized ? '암기완료' : '암기하기'),
                                      onPressed: () async {
                                        await _storageService.updateMemorizedStatus(
                                          word.word, 
                                          !word.isMemorized
                                        );
                                        
                                        setState(() {
                                          // 단어장 목록에서 업데이트
                                          final index = _dayCollections[_currentDay]!.indexOf(word);
                                          if (index >= 0) {
                                            _dayCollections[_currentDay]![index] = 
                                              word.copyWith(isMemorized: !word.isMemorized);
                                          }
                                        });
                                      },
                                      style: ButtonStyle(
                                        foregroundColor: MaterialStateProperty.all(
                                          word.isMemorized ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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