// lib/services/purchase_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vocabulary_app/model/purchase_model.dart';
import 'package:vocabulary_app/utils/constants.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final _secureStorage = FlutterSecureStorage();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final List<ProductDetails> _products = [];
  
  // 사용량 관련 키
  static const String _usageCountKey = 'remaining_usages';
  static const String _hasFreeUsageKey = 'has_free_usage';
  static const String _purchaseHistoryKey = 'purchase_history';
  
  // 상품 ID 목록
  final List<String> _productIds = [
    AppConstants.credits10ProductId,
    AppConstants.credits30ProductId,
    AppConstants.credits100ProductId,
  ];
  
  // 구매 상태 스트림 컨트롤러
  final _purchaseStateController = StreamController<PurchaseState>.broadcast();
  Stream<PurchaseState> get purchaseStateStream => _purchaseStateController.stream;
  
  // 초기화
  Future<void> initialize() async {
    // 무료 사용량 초기화
    await _initializeFreeUsage();
    
    // 인앱 결제 초기화
    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      _purchaseStateController.add(PurchaseState.notAvailable);
      return;
    }
    
    // 결제 스트림 리스너 등록
    _subscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        _purchaseStateController.add(PurchaseState.error);
      }
    );
    
    // 제품 정보 로드
    await _loadProducts();
  }
  
  // 무료 사용량 초기화 (앱 최초 설치 시 10회 무료 제공)
  Future<void> _initializeFreeUsage() async {
    final hasFreeUsage = await _secureStorage.read(key: _hasFreeUsageKey);
    
    if (hasFreeUsage == null) {
      // 최초 설치 시 무료 사용량 부여
      await _secureStorage.write(key: _usageCountKey, value: '${AppConstants.initialFreeCredits}');
      await _secureStorage.write(key: _hasFreeUsageKey, value: 'true');
    } else {
      // 이미 초기화되었는지 확인
      final countStr = await _secureStorage.read(key: _usageCountKey);
      if (countStr == null) {
        // 값이 없으면 0으로 초기화
        await _secureStorage.write(key: _usageCountKey, value: '0');
      }
    }
  }
  
  // 상품 목록 불러오기
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(_productIds.toSet());
          
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('상품을 찾을 수 없음: ${response.notFoundIDs}');
      }
      
      _products.clear();
      _products.addAll(response.productDetails);
      
      _purchaseStateController.add(PurchaseState.loaded);
    } catch (e) {
      debugPrint('상품 로드 오류: $e');
      _purchaseStateController.add(PurchaseState.error);
    }
  }
  
  // 결제 스트림 처리
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchaseStateController.add(PurchaseState.pending);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                purchaseDetails.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _purchaseStateController.add(PurchaseState.error);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _purchaseStateController.add(PurchaseState.canceled);
      }
      
      // 완료된 구매 처리 마무리
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  // 구매 성공 처리
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // 구매 상품 ID에 따라 크레딧 추가
      int creditsToAdd = 0;
      if (purchaseDetails.productID == AppConstants.credits10ProductId) {
        creditsToAdd = 10;
      } else if (purchaseDetails.productID == AppConstants.credits30ProductId) {
        creditsToAdd = 30;
      } else if (purchaseDetails.productID == AppConstants.credits100ProductId) {
        creditsToAdd = 100;
      }
      
      if (creditsToAdd > 0) {
        // 사용량 추가
        await addUsages(creditsToAdd);
        
        // 구매 내역 저장
        await _savePurchaseHistory(PurchaseHistory(
          purchaseId: purchaseDetails.purchaseID ?? 'unknown',
          productId: purchaseDetails.productID,
          purchaseDate: DateTime.now(),
          creditsAmount: creditsToAdd,
        ));
        
        _purchaseStateController.add(PurchaseState.purchased);
      }
    } catch (e) {
      debugPrint('구매 처리 오류: $e');
      _purchaseStateController.add(PurchaseState.error);
    }
  }
  
  // 구매 내역 저장
  Future<void> _savePurchaseHistory(PurchaseHistory history) async {
    try {
      // 기존 구매 내역 불러오기
      final historyJson = await _secureStorage.read(key: _purchaseHistoryKey);
      List<PurchaseHistory> historyList = [];
      
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        historyList = decoded.map((item) => PurchaseHistory.fromJson(item)).toList();
      }
      
      // 새 구매 내역 추가
      historyList.add(history);
      
      // 저장
      final updatedJson = json.encode(historyList.map((item) => item.toJson()).toList());
      await _secureStorage.write(key: _purchaseHistoryKey, value: updatedJson);
    } catch (e) {
      debugPrint('구매 내역 저장 오류: $e');
    }
  }
  
  // 구매 내역 불러오기
  Future<List<PurchaseHistory>> getPurchaseHistory() async {
    try {
      final historyJson = await _secureStorage.read(key: _purchaseHistoryKey);
      if (historyJson == null) return [];
      
      final List<dynamic> decoded = json.decode(historyJson);
      return decoded.map((item) => PurchaseHistory.fromJson(item)).toList();
    } catch (e) {
      debugPrint('구매 내역 불러오기 오류: $e');
      return [];
    }
  }
  
  // 남은 사용량 확인
  Future<int> getRemainingUsages() async {
    final countStr = await _secureStorage.read(key: _usageCountKey);
    if (countStr == null) return 0;
    return int.tryParse(countStr) ?? 0;
  }
  
  // 사용량 차감
  Future<bool> useOneCredit() async {
    final currentCount = await getRemainingUsages();
    if (currentCount <= 0) return false;
    
    await _secureStorage.write(key: _usageCountKey, value: '${currentCount - 1}');
    return true;
  }
  
  // 사용량 추가
  Future<void> addUsages(int count) async {
    final currentCount = await getRemainingUsages();
    await _secureStorage.write(key: _usageCountKey, value: '${currentCount + count}');
  }
  
  // 상품 목록 가져오기
  List<ProductDetails> getProducts() {
    return _products;
  }
  
  // 상품 구매 시작
  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }
  
  // 정리
  void dispose() {
    _subscription?.cancel();
    _purchaseStateController.close();
  }
}

// 구매 상태 열거형
enum PurchaseState {
  notAvailable,
  loading,
  loaded,
  pending,
  purchased,
  canceled,
  error
}