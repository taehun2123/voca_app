import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocabulary_app/screens/purchase_screen.dart';
import 'package:vocabulary_app/screens/word_edit_screen.dart';
import 'package:vocabulary_app/services/ad_service.dart';
import 'package:vocabulary_app/services/purchase_service.dart';
import 'package:vocabulary_app/services/remote_config_service.dart';
import 'package:vocabulary_app/widgets/modern_flash_card_screen.dart';
import 'package:vocabulary_app/widgets/modern_quiz_card_screen.dart';
import 'package:vocabulary_app/widgets/usage_indicator_widget.dart';
import '../model/word_entry.dart';
import '../services/openai_vision_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/word_card_widget.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'package:vocabulary_app/screens/admin_screen.dart'; // 관리자 화면

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
  final PurchaseService _purchaseService = PurchaseService();
  int _processedImages = 0; // 처리된 이미지 수
  int _totalImagesToProcess = 0; // 총 처리할 이미지 수
  int _extractedWordsCount = 0; // 추출된 단어 수
  bool _showDetailedProgress = false; // 상세 진행 상태 표시 여부
  int _remainingUsages = 0;
  bool hasError = false;
  int _logoTapCount = 0;
  DateTime? _lastTapTime;

  OpenAIVisionService? _openAIService;

  bool _isProcessing = false;
  List<File> _batchImages = [];
  String _currentDay = 'DAY 1';
  Map<String, List<WordEntry>> _dayCollections = {};

  late TabController _tabController;
  int _previousTabIndex = 0; // 이전 탭 인덱스 저장용 변수 추가
  bool _hasShownProcessingWarning = false; // 경고 메시지 표시 여부 추적

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _storageService.validateStorage();
    print('홈 화면 초기화 - 저장된 단어 로드 시작');
    _loadSavedWords();
    print('홈 화면 초기화 - API 초기화 시작');
    _initializeOpenAI();
    _purchaseService.initialize();
    _loadRemainingUsages();
  }

  // 사용량 로드 함수 추가
  Future<void> _loadRemainingUsages() async {
    try {
      final usages = await _purchaseService.getRemainingUsages();
      setState(() {
        _remainingUsages = usages;
      });
    } catch (e) {
      print('사용량 로드 오류: $e');
    }
  }

  // 구매 화면으로 이동하는 함수
  void _navigateToPurchaseScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PurchaseScreen()),
    ).then((_) {
      // 돌아왔을 때 사용량 갱신
      _loadRemainingUsages();
    });
  }

  Future<void> _initializeOpenAI() async {
    try {
      print('OpenAI 서비스 초기화 시작');

      // Remote Config 서비스에서 API 키 직접 가져오기
      final remoteConfigService = RemoteConfigService();
      final apiKey = remoteConfigService.getApiKey();

      // apiKey 값 로깅 (개발 중에만 사용, 실제 배포 시 제거 필요)
      print(
          'Remote Config에서 가져온 API 키 상태: ${apiKey.isEmpty ? "비어 있음" : "설정됨"}');

      if (apiKey.isNotEmpty) {
        // API 키가 있으면 서비스 초기화
        _openAIService = OpenAIVisionService();
        setState(() {});
        print('OpenAI 서비스 초기화 완료');
      } else {
        // API 키가 없으면 서비스 초기화 실패
        setState(() {
          _openAIService = null;
        });
        print('API 키가 비어 있어 OpenAI 서비스를 초기화할 수 없습니다');
      }
    } catch (e) {
      print('OpenAI 서비스 초기화 중 오류: $e');
      setState(() {
        _openAIService = null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 탭 변경 리스너 제거
    _tabController.removeListener(_handleTabChange);
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

  void _handleTabChange() {
    // 탭이 실제로 변경될 때만 처리 (인덱스가 변경된 경우만)
    if (_tabController.indexIsChanging ||
        _tabController.index != _previousTabIndex) {
      print('탭 변경 감지: ${_previousTabIndex} -> ${_tabController.index}');

      // 이미지 처리 중인 경우 탭 변경 방지
      if (_isProcessing) {
        print('이미지 처리 중 탭 변경 시도 차단');

        // 변경을 방지하고 원래 탭으로 되돌림
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 애니메이션 없이 이전 탭으로 즉시 돌아감
          _tabController.index = 0; // 항상 첫 번째 탭으로 고정

          // 메시지를 아직 표시하지 않은 경우에만 표시
          if (!_hasShownProcessingWarning) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미지 처리 중에는 탭을 변경할 수 없습니다.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            // 메시지 표시 상태 업데이트
            _hasShownProcessingWarning = true;
          }
        });
      } else {
        // 처리 중이 아닌 경우 이전 탭 인덱스 업데이트
        _previousTabIndex = _tabController.index;
      }
    }
  }

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
    // 이미 처리 중이라면 중복 요청 방지
    if (_isProcessing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 처리가 이미 진행 중입니다.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // OpenAI 서비스 확인
    if (_openAIService == null) {
      print('OpenAI 서비스가 null입니다. 재초기화 시도...');
      await _initializeOpenAI();

      // 재초기화 후에도 null이면 오류 메시지 표시
      if (_openAIService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단어 인식 서비스를 사용할 수 없습니다. 관리자에게 문의하세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isProcessing = false;
          _batchImages = []; // 배치 이미지 초기화
        });
        return;
      }
    }

    // 사용량 체크
    if (_remainingUsages <= 0) {
      // 사용량 부족 시 구매 화면으로 안내
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('단어장 생성 횟수가 부족합니다.'),
          action: SnackBarAction(
            label: '충전하기',
            onPressed: _navigateToPurchaseScreen,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // 단어장 생성 전에 먼저 1회만 크레딧 차감 (여러 이미지를 처리해도 1회만 차감)
    final hasEnoughCredit = await _purchaseService.useOneCredit();
    if (!hasEnoughCredit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('단어장 생성 횟수가 부족합니다.'),
          action: SnackBarAction(
            label: '충전하기',
            onPressed: _navigateToPurchaseScreen,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    bool creditUsed = true;

    setState(() {
      _isProcessing = true;
      _showDetailedProgress = true;
      _processedImages = 0;
      _totalImagesToProcess = _batchImages.length;
      _extractedWordsCount = 0;
      _tabController.index = 0;
      _previousTabIndex = 0;
      _hasShownProcessingWarning = false; // 새 처리 작업 시작 시 경고 상태 초기화
    });

    // DAY 입력 다이얼로그 표시
    final String? selectedDay = await _showDaySelectionDialog();
    if (selectedDay == null) {
      // 취소한 경우 크레딧 복구
      await _purchaseService.addUsages(1);
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    _currentDay = selectedDay;

    // 각 이미지 처리
    List<WordEntry> allWords = [];
    bool hasError = false; // 오류 발생 여부 추적

    for (var i = 0; i < _batchImages.length; i++) {
      try {
        setState(() {
          _processedImages = i + 1;
        });

        if (_openAIService == null) {
          throw Exception('OpenAI 서비스가 초기화되지 않았습니다');
        }

        List<WordEntry> words =
            await _openAIService!.extractWordsFromImage(_batchImages[i]);

        // 여기서 추출된 단어들에 현재 선택된 DAY 값을 설정
        for (var j = 0; j < words.length; j++) {
          words[j] = words[j].copyWith(day: _currentDay);
        }

        allWords.addAll(words);

        setState(() {
          _extractedWordsCount += words.length;
        });

        // 처리 완료 후 광고 표시 (이 부분 추가)
        if (!hasError && allWords.isNotEmpty) {
          final adService = AdService();
          adService.showInterstitialAd(); // 전면 광고 표시 (결과는 기다리지 않음)
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
        hasError = true;
        break;
      }
    }

    // 이미지 처리 중 오류 발생 또는 단어를 하나도 추출하지 못한 경우 크레딧 복구
    if (hasError || allWords.isEmpty) {
      if (creditUsed) {
        print('오류 발생 또는 단어 추출 실패로 크레딧 복구');
        await _purchaseService.addUsages(1);
        creditUsed = false; // 크레딧 반환됨
      }
    }

    setState(() {
      _isProcessing = false;
      _batchImages = []; // 배치 이미지 초기화
      _hasShownProcessingWarning = false; // 처리 완료 시 경고 상태 초기화
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

    // 현재 선택된 DAY의 기존 단어들 가져오기
    List<WordEntry> existingWords = _dayCollections[_currentDay] ?? [];

    // 추출된 단어들 중에서 기존 단어들과 중복되는 단어들 필터링
    List<String> existingWordTexts =
        existingWords.map((word) => word.word).toList();
    List<String> duplicateWords = [];

    // 새로운 단어 맵 생성 (중복 제거)
    final Map<String, WordEntry> uniqueWords = {};
    for (var word in allWords) {
      // 이미 맵에 있는 단어는 스킵 (동일 배치 내 중복 제거)
      if (uniqueWords.containsKey(word.word)) {
        continue;
      }

      // 이미 저장된 단어인지 확인
      if (existingWordTexts.contains(word.word)) {
        duplicateWords.add(word.word);
        continue; // 중복 단어는 건너뜀
      }

      // 중복이 아닌 단어만 맵에 추가
      uniqueWords[word.word] = word;
    }

    // 중복 단어가 있었다면 사용자에게 알림
    if (duplicateWords.isNotEmpty) {
      // 최대 3개만 표시하고 나머지는 ...으로 표시
      String displayDuplicates = duplicateWords.length <= 3
          ? duplicateWords.join(', ')
          : duplicateWords.take(3).join(', ') +
              ' 외 ${duplicateWords.length - 3}개';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '이미 저장된 단어 $displayDuplicates ${duplicateWords.length > 3 ? "등" : ""}이(가) 제외되었습니다.'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // 중복 제거 후 남은 단어가 없는 경우 크레딧 복구
    if (uniqueWords.isEmpty) {
      if (creditUsed) {
        print('중복 제거 후 저장할 단어가 없어 크레딧 복구');
        await _purchaseService.addUsages(1);
        creditUsed = false; // 크레딧 반환됨
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('추출된 모든 단어가 이미 저장되어 있습니다.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
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

    // 편집 화면에서 돌아왔을 때 처리
    if (result != null && result is Map) {
      // 다시 시도 요청인 경우
      if (result.containsKey('retry') && result['retry'] == true) {
        if (creditUsed) {
          print('사용자가 다시 인식하기를 요청하여 크레딧 유지');
          // 크레딧은 반환하지 않고 유지 (다시 이미지 촬영으로 돌아감)
        }
        return;
      }

      try {
        final List<WordEntry> editedWords = result['words'];
        final String dayName = result['dayName'];

        // 편집 후 단어가 없는 경우 크레딧 복구
        if (editedWords.isEmpty) {
          if (creditUsed) {
            print('편집 후 저장할 단어가 없어 크레딧 복구');
            await _purchaseService.addUsages(1);
            creditUsed = false; // 크레딧 반환됨
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장할 단어가 없습니다.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }

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

          // 새 단어 추가 또는 업데이트 (기존 단어 유지하면서)
          List<WordEntry> updatedWords =
              List.from(_dayCollections[dayName] ?? []);

          // 기존 단어 중 편집된 단어와 중복되는 것 제거
          updatedWords.removeWhere((existingWord) => editedWords
              .any((editedWord) => editedWord.word == existingWord.word));

          // 편집된 단어 추가
          updatedWords.addAll(editedWords);

          _dayCollections[dayName] = updatedWords;
          print('$dayName 컬렉션 업데이트: ${updatedWords.length}개 단어');
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

        // 저장 중 오류 발생 시 크레딧 복구 고려 (옵션)
        if (creditUsed) {
          print('단어 저장 중 오류 발생으로 크레딧 복구 (선택적)');
          // 아래 줄의 주석을 해제하면 저장 오류 시에도 크레딧을 복구합니다
          // await _purchaseService.addUsages(1);
          // creditUsed = false;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단어 저장 중 오류가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // 사용량 정보 갱신
      _loadRemainingUsages();
    } else {
      // 사용자가 편집 화면을 취소한 경우 (뒤로 가기 등)
      if (creditUsed) {
        print('사용자가 편집 화면을 취소하여 크레딧 복구');
        await _purchaseService.addUsages(1);
        creditUsed = false; // 크레딧 반환됨
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
        backgroundColor: Theme.of(context).cardColor, // 다이얼로그 배경색
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '단어장 설정',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color, // 제목 색상
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '이 단어들을 저장할 DAY를 입력하세요',
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyMedium?.color, // 내용 텍스트 색상
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color, // 입력 텍스트 색상
              ),
              decoration: InputDecoration(
                hintText: '예: DAY 1',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor, // 테두리 색상
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, // 포커스 테두리 색상
                    width: 2,
                  ),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.white, // 입력창 배경색
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('취소'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('확인'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).colorScheme.primary,
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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              // Shop 아이콘을 좌측에 배치하기 위한 leading 위젯 설정
      leading: IconButton(
        icon: Icon(
          Icons.shopping_cart,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.amber.shade300
              : Colors.amber.shade800,
        ),
        onPressed: () {
          // 인앱결제 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PurchaseScreen()),
          ).then((_) {
            // 돌아왔을 때 사용량 갱신
            _loadRemainingUsages();
          });
        },
        tooltip: '충전하기',
      ),
        title: GestureDetector(
          onTap: () {
            // 현재 시간 가져오기
            final now = DateTime.now();

            if (_lastTapTime == null ||
                now.difference(_lastTapTime!).inSeconds > 3) {
              _logoTapCount = 1;
            } else {
              _logoTapCount++;
            }

            _lastTapTime = now;

            if (_logoTapCount >= 15) {
              _logoTapCount = 0;
              _showAdminLogin();
            }
          },
          child: Text(
            '찍어보카',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
        actions: [
          // 다크모드 토글 아이콘 추가
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber.shade300
                  : Colors.amber.shade800,
            ),
            onPressed: () {
              // 테마 전환
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            tooltip: '테마 변경',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).tabBarTheme.labelColor,
          unselectedLabelColor:
              Theme.of(context).tabBarTheme.unselectedLabelColor,
          indicatorColor: Theme.of(context).tabBarTheme.indicatorColor,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.w600),
          // 이미지 처리 중일 때 탭 비활성화 처리
          onTap: (index) {
            if (_isProcessing && index != 0) {
              // 이미지 처리 중이고 첫 번째 탭이 아닌 다른 탭 선택 시
              // 메시지를 아직 표시하지 않은 경우에만 표시
              if (!_hasShownProcessingWarning) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('이미지 처리 중에는 탭을 변경할 수 없습니다.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                // 메시지 표시 상태 업데이트
                _hasShownProcessingWarning = true;
              }
              _tabController.index = 0;
            }
          },
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
        physics: _isProcessing
            ? NeverScrollableScrollPhysics() // 이미지 처리 중일 때 스와이프 비활성화
            : AlwaysScrollableScrollPhysics(), // 그 외에는 정상 작동
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

  // 관리자 로그인 다이얼로그 표시 함수
  void _showAdminLogin() {
    final TextEditingController passwordController = TextEditingController();
    final RemoteConfigService remoteConfigService = RemoteConfigService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('관리자 인증'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('관리자 모드에 접근하려면 비밀번호를 입력하세요.'),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (remoteConfigService
                  .verifyAdminPassword(passwordController.text)) {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminScreen()),
                );
              } else {
                // 비밀번호 불일치
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('비밀번호가 일치하지 않습니다.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              // 항상 컨트롤러 비우기
              passwordController.clear();
            },
            child: Text('로그인'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      // 다이얼로그 닫힐 때 컨트롤러 정리
      passwordController.dispose();
    });
  }

  // 이미지 캡처 탭 UI - 모던한 디자인으로 수정
  Widget _buildCaptureTab() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 사용량 표시 위젯 추가 (최상단)
          UsageIndicatorWidget(
            remainingUsages: _remainingUsages,
            onBuyPressed: _navigateToPurchaseScreen,
          ),
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
// API 키 관련 UI는 제거하고 대신 간단한 정보 표시
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.green.shade900.withOpacity(0.3)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.green.shade900.withOpacity(0.3)
                              : Colors.green.shade50,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.green.shade700
                                  : Colors.green.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.green.shade300
                                  : Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _remainingUsages > 0 ? "사용 가능" : "충전 필요",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.green.shade50
                                  : Colors.green.shade900,
                            ),
                          ),
                        ],
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
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green.shade700 // 다크모드
                                    : Colors.green.shade500, // 라이트모드
                            foregroundColor: Colors.white, // 텍스트는 항상 흰색으로
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
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade700 // 다크모드
                                    : Colors.blue.shade500, // 라이트모드
                            foregroundColor: Colors.white, // 텍스트는 항상 흰색으로
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
        // _buildWordListTab() 함수 내 단어장 선택 드롭다운 수정 부분
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).cardColor, // 하드코딩된 Colors.white 대신 테마 색상 사용
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .shadowColor
                    .withOpacity(0.1), // 테마 그림자 색상 사용
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
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color, // 테마 텍스트 색상 사용
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
                        border: Border.all(
                          color: Theme.of(context).dividerColor, // 테마 구분선 색상 사용
                        ),
                        color: Theme.of(context).cardColor, // 드롭다운 배경색
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
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.blue.shade900
                                              .withOpacity(0.3)
                                          : Colors.blue.shade50, // 다크모드 지원
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '$count단어',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.blue.shade300
                                            : Colors.blue.shade700, // 다크모드 지원
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
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Theme.of(context)
                                .iconTheme
                                .color, // 테마 아이콘 색상 사용
                          ),
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color, // 테마 텍스트 색상 사용
                            fontSize: 16,
                          ),
                          dropdownColor:
                              Theme.of(context).cardColor, // 드롭다운 메뉴 배경색
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.red.shade900.withOpacity(0.3)
                          : Colors.red.shade50, // 다크모드 지원
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.red.shade300
                            : Colors.red.shade700, // 다크모드 지원
                      ),
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
                  Colors.blue, // MaterialColor 그대로 전달
                  Icons.format_list_numbered,
                ),
                SizedBox(width: 12),
                _buildStatCard(
                  '암기 완료',
                  '${_dayCollections[_currentDay]?.where((w) => w.isMemorized).length ?? 0}',
                  Colors.green, // MaterialColor 그대로 전달
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
// _buildStatCard 함수 수정 - MaterialColor 매개변수 유지하고 내부에서 색상 처리
  Widget _buildStatCard(
      String title, String value, MaterialColor color, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 다크모드에 맞는 색상 생성
    final backgroundColor = isDarkMode
        ? Color.fromRGBO(
            color.shade900.red, color.shade900.green, color.shade900.blue, 0.3)
        : color.shade50;

    final iconBackgroundColor = isDarkMode
        ? Color.fromRGBO(
            color.shade800.red, color.shade800.green, color.shade800.blue, 0.5)
        : color.shade100;

    final iconColor = isDarkMode ? color.shade300 : color.shade700;
    final titleColor = isDarkMode ? color.shade300 : color.shade700;
    final valueColor = isDarkMode ? color.shade100 : color.shade900;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: titleColor),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
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
            color: Theme.of(context).cardColor, // 테마에 맞는 배경 색상
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .shadowColor
                    .withOpacity(0.1), // 테마에 맞는 그림자 색상
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade300 // 다크모드 텍스트 색상
                      : Colors.grey.shade700, // 라이트모드 텍스트 색상
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700 // 다크모드 테두리 색상
                        : Colors.grey.shade300, // 라이트모드 테두리 색상
                  ),
                  color: Theme.of(context).cardColor, // 테마에 맞는 배경 색상
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
                            Text(
                              day,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.green.shade900
                                        .withOpacity(0.3) // 다크모드 배경
                                    : Colors.green.shade50, // 라이트모드 배경
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$count단어',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.green.shade300 // 다크모드 텍스트 색상
                                      : Colors.green.shade700, // 라이트모드 텍스트 색상
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
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).iconTheme.color, // 테마에 맞는 아이콘 색상
                    ),
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color, // 테마에 맞는 텍스트 색상
                      fontSize: 16,
                    ),
                    dropdownColor:
                        Theme.of(context).cardColor, // 드롭다운 배경색을 테마에 맞게 설정
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
            color: Theme.of(context).cardColor, // 테마 배경색 적용
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .shadowColor
                    .withOpacity(0.1), // 테마 그림자색 적용
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade300 // 다크모드 텍스트 색상
                      : Colors.grey.shade700, // 라이트모드 텍스트 색상
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
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade700 // 다크모드 테두리
                              : Colors.grey.shade300, // 라이트모드 테두리
                        ),
                        // 드롭다운 배경색도 테마 적용
                        color: Theme.of(context).cardColor,
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
                                  Text(
                                    day,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color, // 테마 텍스트 색상
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.blue.shade900
                                              .withOpacity(0.3) // 다크모드 배지 배경
                                          : Colors.blue.shade50, // 라이트모드 배지 배경
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '$count단어',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors
                                                .blue.shade300 // 다크모드 배지 텍스트
                                            : Colors
                                                .blue.shade700, // 라이트모드 배지 텍스트
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
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color:
                                Theme.of(context).iconTheme.color, // 테마 아이콘 색상
                          ),
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color, // 테마 텍스트 색상
                            fontSize: 16,
                          ),
                          dropdownColor:
                              Theme.of(context).cardColor, // 드롭다운 메뉴 배경색 테마 적용
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
