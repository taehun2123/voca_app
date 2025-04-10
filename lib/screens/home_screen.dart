import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocabulary_app/screens/purchase_screen.dart';
import 'package:vocabulary_app/screens/word_edit_screen.dart';
import 'package:vocabulary_app/services/ad_service.dart';
import 'package:vocabulary_app/services/purchase_service.dart';
import 'package:vocabulary_app/services/remote_config_service.dart';
import 'package:vocabulary_app/tabs/capture_tab.dart';
import 'package:vocabulary_app/tabs/flash_card_tab.dart';
import 'package:vocabulary_app/tabs/quiz_tab.dart';
import 'package:vocabulary_app/tabs/word_list_tab.dart';
import 'package:vocabulary_app/widgets/dialogs/admin_login_dialog.dart';
import 'package:vocabulary_app/widgets/dialogs/day_selection_dialog.dart';
import 'package:vocabulary_app/widgets/dialogs/duplicate_warning_dialog.dart';
import '../model/word_entry.dart';
import '../services/openai_vision_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
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
// 이전 탭 인덱스 저장용 변수 추가
  bool _hasShownProcessingWarning = false; // 경고 메시지 표시 여부 추적

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      // 변경 이벤트가 발생할 때마다 UI 업데이트
      if (!mounted) return;

      // 이미지 처리 중인 경우 탭 변경 제한 로직 (첫 번째 탭 제외)
      if (_isProcessing && _tabController.index != 0) {
        print('이미지 처리 중 탭 변경 시도 차단');

        // 변경을 방지하고 원래 탭으로 되돌림 (지연 적용)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tabController.animateTo(0, duration: Duration.zero);

          // 경고 메시지가 아직 표시되지 않았으면 표시
          if (!_hasShownProcessingWarning) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('이미지 처리 중에는 탭을 변경할 수 없습니다.'),
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
        // 탭이 변경되면 UI 강제 업데이트
        setState(() {
          // 현재 선택된 탭 인덱스는 _tabController.index로 접근
          // 별도 변수 필요 없음
        });
      }
    });
    _storageService.validateStorage();
    print('홈 화면 초기화 - 저장된 단어 로드 시작');
    _loadSavedWords();
    print('홈 화면 초기화 - API 초기화 시작');
    _initializeOpenAI();
    _purchaseService.initialize();
    _loadRemainingUsages();
  }

  Future<void> _initializeOpenAI() async {
    try {
      // Remote Config 서비스에서 API 키 직접 가져오기
      final remoteConfigService = RemoteConfigService();
      final apiKey = remoteConfigService.getApiKey();

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
      }
    } catch (e) {
      print('OpenAI 서비스 초기화 중 오류: $e');
      setState(() {
        _openAIService = null;
      });
    }
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

  //단어 로딩 알고리즘
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

  //이미지 촬영 관련
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

  //이미지 선택 관련
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

  //이미지 더 촬영 관련 함수
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

  //이미지 처리 프로세스 함수
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

    // 프로그레스 표시 초기화
    setState(() {
      _processedImages = 0;
      _totalImagesToProcess = _batchImages.length;
      _extractedWordsCount = 0;
    });

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
    Map<String, WordEntry> uniqueWords = {};
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

    // 다른 단어장에 중복 단어가 있는지 확인 및 처리
    Map<String, List<String>> duplicatesInOtherCollections =
        await _checkWordExistsInOtherCollections(
            uniqueWords.values.toList(), _currentDay);

    // 다른 단어장에 중복 단어가 있는 경우
    if (duplicatesInOtherCollections.isNotEmpty) {
      // 사용자에게 중복 단어 경고 다이얼로그 표시
      bool allowDuplicates =
          await _showDuplicateWarningDialog(duplicatesInOtherCollections);

      if (!allowDuplicates) {
        // 중복 단어 건너뛰기 선택 시
        print('사용자가 중복 단어 건너뛰기를 선택했습니다.');

        // 중복 단어 목록 (모든 단어장의 중복 단어를 한 곳에 모음)
        Set<String> allDuplicateWords = {};
        duplicatesInOtherCollections.forEach((day, words) {
          allDuplicateWords.addAll(words);
        });

        // 중복되지 않는 단어만 필터링
        Map<String, WordEntry> filteredWords = {};
        uniqueWords.forEach((word, entry) {
          if (!allDuplicateWords.contains(word)) {
            filteredWords[word] = entry;
          }
        });

        // 중복되지 않는 단어만 유지
        uniqueWords = filteredWords;

        // 중복 단어 제거 후 남은 단어가 없는 경우 처리
        if (uniqueWords.isEmpty) {
          if (creditUsed) {
            print('중복 제거 후 저장할 단어가 없어 크레딧 복구');
            await _purchaseService.addUsages(1);
            creditUsed = false; // 크레딧 반환됨
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('추출된 모든 단어가 이미 다른 단어장에 저장되어 있습니다.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
      } else {
        // 중복 단어 추가 허용 시, 기존 단어 삭제 처리
        print('사용자가 중복 단어 추가를 허용했습니다. 기존 단어장에서 해당 단어를 제거합니다.');

        // 모든 중복 단어 삭제 처리
        for (final day in duplicatesInOtherCollections.keys) {
          for (final word in duplicatesInOtherCollections[day]!) {
            await _storageService.deleteWord(word);
            print('단어 "$word"를 단어장 "$day"에서 삭제했습니다.');
          }
        }

        // 각 단어장의 단어 수 업데이트
        for (final day in duplicatesInOtherCollections.keys) {
          // 해당 단어장의 현재 단어 수 계산
          int wordCount = (_dayCollections[day]?.length ?? 0) -
              duplicatesInOtherCollections[day]!.length;
          if (wordCount < 0) wordCount = 0;

          // 단어장 정보 업데이트
          await _storageService.saveDayCollection(day, wordCount);

          // UI 상태 업데이트를 위해 단어장에서 해당 단어들 제거
          if (_dayCollections.containsKey(day)) {
            setState(() {
              _dayCollections[day] = _dayCollections[day]!
                  .where((entry) =>
                      !duplicatesInOtherCollections[day]!.contains(entry.word))
                  .toList();
            });
          }
        }
      }
    }

    // 전체 단어 목록 준비 (기존 단어 + 새 단어)
    List<WordEntry> combinedWords = [];

    // 기존 단어 추가 (기존 단어와 같은 순서 유지)
    combinedWords.addAll(existingWords);

    // 새 단어 추가 (중복 제거된 단어들)
    combinedWords.addAll(uniqueWords.values.toList());

    // 모든 처리 완료 후 광고 표시 (단 한 번만)
    if (!hasError && allWords.isNotEmpty) {
      try {
        final adService = AdService();
        await adService.showInterstitialAd(); // 전면 광고 표시
      } catch (e) {
        print('광고 표시 중 오류: $e');
        // 광고 표시 실패해도 계속 진행
      }
    }

    // 단어 편집 화면으로 이동 (전체 단어 목록 전달)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordEditScreen(
          words: combinedWords, // 기존 단어 + 새 단어 함께 전달
          dayName: _currentDay,
          newWords: uniqueWords.values.toList(), // 새 단어 표시용으로 추가 전달
          isFromImageRecognition: true, // 이미지 인식에서 왔음을 표시
        ),
      ),
    );

    // 편집 화면에서 돌아왔을 때 처리
    if (result != null && result is Map) {
      // 다시 시도 요청인 경우
      if (result.containsKey('retry') && result['retry'] == true) {
        print('사용자가 다시 인식하기를 요청했습니다. 이미지 재처리 시도...');
        // 크레딧 복구 (다시 인식할 때는 크레딧을 차감하지 않음)
        if (creditUsed) {
          print('다시 인식하기 요청으로 크레딧 복구');
          await _purchaseService.addUsages(1);
          creditUsed = false; // 크레딧 복구 표시
        }
        // 같은 이미지로 다시 처리 시작 (기존 이미지 유지)
        if (_batchImages.isEmpty) {
          // 만약 이미지가 초기화되었다면 사용자에게 알림
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미지가 없습니다. 새 이미지를 촬영하거나 선택해주세요.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // 이미지가 있으면 다시 처리 (재귀 호출)
          await _processBatchImages();
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
          await _purchaseService.addUsages(1);
          creditUsed = false;
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

// 2. 단어장 선택 다이얼로그 수정 - 기존 단어장에 추가 옵션 제공
  Future<String?> _showDaySelectionDialog() async {
    // 다음 DAY 번호 계산 함수 사용
    int nextDayNum = calculateNextDayNumber(_dayCollections);

    // 분리된 다이얼로그 사용
    return showDaySelectionDialog(
      context: context,
      dayCollections: _dayCollections,
      nextDayNum: nextDayNum,
    );
  }

// 단어가 다른 단어장에 존재하는지 확인하는 함수
  Future<Map<String, List<String>>> _checkWordExistsInOtherCollections(
      List<WordEntry> words, String currentDayName) async {
    // 결과를 저장할 맵: 단어장 이름 -> 중복 단어 목록
    Map<String, List<String>> duplicatesInOtherCollections = {};

    // 모든 단어 로드 (전체 단어 데이터)
    final allWords = await _storageService.getAllWords();

    // 추가하려는 단어 목록
    final newWordTexts = words.map((w) => w.word).toSet();

    // 현재 단어장을 제외한 다른 단어장에서 중복 단어 확인
    for (final word in allWords) {
      // 현재 추가하려는 단어인지 확인하고, 다른 단어장에 있는지 확인
      if (newWordTexts.contains(word.word) &&
          word.day != null &&
          word.day != currentDayName) {
        // 해당 단어장에 대한 리스트가 없으면 새로 생성
        if (!duplicatesInOtherCollections.containsKey(word.day)) {
          duplicatesInOtherCollections[word.day!] = [];
        }

        // 중복 목록에 단어 추가
        duplicatesInOtherCollections[word.day!]!.add(word.word);
      }
    }

    return duplicatesInOtherCollections;
  }

// 중복 단어가 있을 때 표시할 다이얼로그
  Future<bool> _showDuplicateWarningDialog(
      Map<String, List<String>> duplicatesInOtherCollections) async {
    return showDuplicateWarningDialog(
      context: context,
      duplicatesInOtherCollections: duplicatesInOtherCollections,
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

  // 현재 단어장 변경
  void _setCurrentDay(String dayName) {
    setState(() {
      _currentDay = dayName;
    });
  }

  // 복습 횟수 증가
  Future<void> _incrementReviewCount(String wordText) async {
    await _storageService.incrementReviewCount(wordText);
  }

  // 0번 탭으로 이동
  void _navigateToCaptureTab() {
    _tabController.animateTo(0);
  }

  void _clearImages() {
    setState(() {
      _batchImages = [];
    });
  }

  // 전체 단어 목록 가져오기
  List<WordEntry> _getAllWords() {
    List<WordEntry> allWords = [];
    for (var words in _dayCollections.values) {
      allWords.addAll(words);
    }
    return allWords;
  }

// lib/screens/home_screen.dart 파일의 Scaffold 부분 수정
// TabBar 대신 BottomNavigationBar 사용

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        // Shop 아이콘을 좌측에 배치하기 위한 leading 위젯 설정
        leading: IconButton(
          icon: Icon(
            Icons.shopping_cart,
            color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade800,
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
              color: isDarkMode ? Colors.white : Colors.black87,
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
              color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade800,
            ),
            onPressed: () {
              // 테마 전환
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            tooltip: '테마 변경',
          ),
        ],
      ),
      // 메인 컨텐츠 영역 - TabBarView 유지
      body: TabBarView(
        controller: _tabController,
        physics: _isProcessing
            ? NeverScrollableScrollPhysics() // 이미지 처리 중일 때 스와이프 비활성화
            : AlwaysScrollableScrollPhysics(), // 그 외에는 정상 작동
        children: [
          // 탭 내용은 동일하게 유지
          CaptureTab(
            onTakePhoto: _takePhoto,
            onPickImage: _pickImage,
            onClearImages: _clearImages,
            navigateToPurchaseScreen: _navigateToPurchaseScreen,
            batchImages: _batchImages,
            isProcessing: _isProcessing,
            remainingUsages: _remainingUsages,
            processedImages: _processedImages,
            totalImagesToProcess: _totalImagesToProcess,
            extractedWordsCount: _extractedWordsCount,
            showDetailedProgress: _showDetailedProgress,
          ),

          WordListTab(
            dayCollections: _dayCollections,
            currentDay: _currentDay,
            onDayChanged: (String day) {
              setState(() {
                _currentDay = day;
              });
            },
            navigateToCaptureTab: () {
              _tabController.animateTo(0);
            },
            onSpeakWord: _speakWord,
            storageService: _storageService,
          ),

          FlashCardTab(
            words: _dayCollections[_currentDay] ?? [],
            onSpeakWord: _speakWord,
            onReviewComplete: _incrementReviewCount,
            dayCollections: _dayCollections,
            currentDay: _currentDay,
            onDayChanged: _setCurrentDay,
            navigateToCaptureTab: _navigateToCaptureTab,
          ),

          QuizTab(
            words: _dayCollections[_currentDay] ?? [],
            allWords: _getAllWords(),
            onSpeakWord: _speakWord,
            dayCollections: _dayCollections,
            currentDay: _currentDay,
            onDayChanged: _setCurrentDay,
            navigateToCaptureTab: _navigateToCaptureTab,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _tabController.index,
            onTap: (index) {
              if (_isProcessing && index != 0) {
                // 이미지 처리 중이고 첫 번째 탭이 아닌 다른 탭 선택 시
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
                  _hasShownProcessingWarning = true;
                }
              } else {
                _tabController.animateTo(index);
              }
            },
            type: BottomNavigationBarType.fixed, // 4개 이상 항목이 있을 때 필요
            backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            selectedItemColor: isDarkMode ? Colors.blue.shade300 : Colors.blue,
            unselectedItemColor:
                isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700,
            selectedLabelStyle:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: TextStyle(fontSize: 12),
            elevation: 0, // 그림자는 위 Container에서 처리
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt),
                label: '단어 추가',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: '단어장',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.quiz),
                label: '플래시카드',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.games),
                label: '퀴즈',
              ),
            ],
          ),
        ),
      ),
    );
  }

// 관리자 로그인 다이얼로그 표시 함수
  void _showAdminLogin() {
    showAdminLoginDialog(
      context: context,
      onSuccess: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminScreen()),
        );
      },
    );
  }
}
