import 'package:flutter/material.dart';

/// 반응형 화면 빌더 위젯
/// 화면 크기에 따라 다른 레이아웃을 구현할 수 있도록 도와주는 위젯
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;
  
  const ResponsiveBuilder({
    Key? key, 
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, constraints);
      },
    );
  }
}

/// 화면 크기와 관련된 유틸리티 함수들을 제공하는 클래스
class ResponsiveUtil {
  static bool isMobile(BoxConstraints constraints) {
    return constraints.maxWidth < 600;
  }
  
  static bool isTablet(BoxConstraints constraints) {
    return constraints.maxWidth >= 600 && constraints.maxWidth < 900;
  }
  
  static bool isDesktop(BoxConstraints constraints) {
    return constraints.maxWidth >= 900;
  }
  
  static bool isLandscape(BoxConstraints constraints) {
    return constraints.maxWidth > constraints.maxHeight;
  }
  
  static bool isPortrait(BoxConstraints constraints) {
    return constraints.maxHeight > constraints.maxWidth;
  }
  
  /// 가로모드에서의 오버플로우 방지를 위한 패딩 계산
  static EdgeInsets safePadding(BoxConstraints constraints) {
    final isLandscapeMode = isLandscape(constraints);
    
    if (isLandscapeMode) {
      // 가로모드에서는 좌우 패딩을 더 크게 설정하여 중앙 영역에 콘텐츠 배치
      return EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.15, vertical: 8);
    } else {
      // 세로모드에서는 기본 패딩 사용
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
  }
  
  /// 가로모드에서 콘텐츠 영역 최대 너비 계산
  static double contentMaxWidth(BoxConstraints constraints) {
    if (isLandscape(constraints)) {
      // 가로모드에서는 화면 너비의 70%만 사용
      return constraints.maxWidth * 0.7;
    } else {
      // 세로모드에서는 전체 너비 사용
      return constraints.maxWidth;
    }
  }
  
  /// 가로모드에서 스크롤 뷰 대응을 위한 최대 높이 계산
  static double scrollViewMaxHeight(BoxConstraints constraints) {
    if (isLandscape(constraints)) {
      // 가로모드에서는 화면 높이의 80%만 사용 (탭바, 앱바 등 고려)
      return constraints.maxHeight * 0.8;
    } else {
      // 세로모드에서는 제한 없음
      return double.infinity;
    }
  }
}