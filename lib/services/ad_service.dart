// lib/services/ad_service.dart (수정)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vocabulary_app/services/tracking_permission_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // 테스트 광고 ID
  static const String _interstitialAdUnitId = 'ca-app-pub-4919515349758409/5584013489';
  static const String _rewardedAdUnitId = 'ca-app-pub-4919515349758409/7377399317'; 

  // 광고 로드 상태 스트림
  final _adLoadingController = StreamController<bool>.broadcast();
  Stream<bool> get adLoadingStream => _adLoadingController.stream;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdLoading = false;
  bool _isRewardedAdLoading = false;
  
  // 권한 서비스 인스턴스
  final _trackingPermissionService = TrackingPermissionService();

  // 초기화 - ATT 권한 요청 추가
  Future<void> initialize() async {
    // 앱 추적 투명성 권한 요청 (iOS)
    await _trackingPermissionService.requestTrackingPermission();
    
    // MobileAds 초기화
    await MobileAds.instance.initialize();
    
    // 광고 로드
    _loadInterstitialAd();
    _loadRewardedAd();
    
    debugPrint('광고 서비스 초기화 완료');
  }

  // 전면 광고 로드
  void _loadInterstitialAd() {
    if (_isInterstitialAdLoading) return;
    
    _isInterstitialAdLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          debugPrint('전면 광고 로드 완료');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoading = false;
          debugPrint('전면 광고 로드 실패: $error');
        },
      ),
    );
  }

  // 보상형 광고 로드
  void _loadRewardedAd() {
    if (_isRewardedAdLoading) return;
    
    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          debugPrint('보상형 광고 로드 완료');
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoading = false;
          debugPrint('보상형 광고 로드 실패: $error');
        },
      ),
    );
  }

  // 전면 광고 표시
  Future<bool> showInterstitialAd() async {
    // 먼저 권한 확인
    final hasPermission = await _trackingPermissionService.isTrackingPermissionGranted();
    debugPrint('광고 추적 권한 상태: $hasPermission');
    
    if (_interstitialAd == null) {
      _loadInterstitialAd();
      return false;
    }

    final completer = Completer<bool>();
    
    // 광고 로딩 시작 알림
    _adLoadingController.add(true);

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // 새 광고 로드
        _adLoadingController.add(false); // 광고 로딩 종료 알림
        completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        _adLoadingController.add(false);
        debugPrint('전면 광고 표시 실패: $error');
        completer.complete(false);
      },
    );

    await _interstitialAd!.show();
    return completer.future;
  }

  // 보상형 광고 표시
  Future<bool> showRewardedAd() async {
    // 먼저 권한 확인
    final hasPermission = await _trackingPermissionService.isTrackingPermissionGranted();
    debugPrint('광고 추적 권한 상태: $hasPermission');
    
    if (_rewardedAd == null) {
      _loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();
    bool receivedReward = false;
    
    // 광고 로딩 시작 알림
    _adLoadingController.add(true);

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // 새 광고 로드
        _adLoadingController.add(false); // 광고 로딩 종료 알림
        completer.complete(receivedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        _adLoadingController.add(false);
        debugPrint('보상형 광고 표시 실패: $error');
        completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        receivedReward = true;
        debugPrint('사용자가 보상을 획득했습니다: ${reward.amount}');
      },
    );
    
    return completer.future;
  }

  // 정리
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _adLoadingController.close();
  }
}