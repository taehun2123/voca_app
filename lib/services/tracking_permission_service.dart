// lib/services/tracking_permission_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class TrackingPermissionService {
  // 싱글톤 패턴
  static final TrackingPermissionService _instance = TrackingPermissionService._internal();
  factory TrackingPermissionService() => _instance;
  TrackingPermissionService._internal();

  bool _hasRequestedPermission = false;

  /// 추적 권한 상태를 확인하고 요청합니다.
  /// 안드로이드에서는 항상 true를 반환합니다.
  /// iOS에서는 사용자의 권한 부여 상태를 반환합니다.
  Future<bool> requestTrackingPermission() async {
    // 이미 권한을 요청했거나 iOS가 아닌 경우 처리
    if (_hasRequestedPermission || !Platform.isIOS) {
      return true;
    }

    try {
      // iOS 14 미만은 ATT가 필요하지 않음
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      debugPrint('현재 추적 권한 상태: $status');

      // 아직 결정되지 않은 경우에만 요청
      if (status == TrackingStatus.notDetermined) {
        // 추적 투명성 대화상자를 표시하기 전에 잠시 지연
        // Apple은 의미 있는 컨텍스트를 제공한 후 권한을 요청하도록 권장함
        await Future.delayed(const Duration(milliseconds: 200));
        
        // 권한 요청
        final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('새 추적 권한 상태: $newStatus');
        
        _hasRequestedPermission = true;
        return newStatus == TrackingStatus.authorized;
      } else {
        _hasRequestedPermission = true;
        return status == TrackingStatus.authorized;
      }
    } catch (e) {
      debugPrint('추적 권한 요청 중 오류: $e');
      _hasRequestedPermission = true;
      return false;
    }
  }

  /// 현재 추적 권한 상태만 확인합니다.
  Future<bool> isTrackingPermissionGranted() async {
    if (!Platform.isIOS) {
      return true;
    }

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      return status == TrackingStatus.authorized;
    } catch (e) {
      debugPrint('추적 권한 상태 확인 중 오류: $e');
      return false;
    }
  }
}