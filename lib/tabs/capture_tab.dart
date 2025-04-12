// lib/tabs/capture_tab.dart 수정

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vocabulary_app/widgets/usage_indicator_widget.dart';

class CaptureTab extends StatefulWidget {
  final Function() onTakePhoto;
  final Function() onPickImage;
  final Function() onClearImages;
  final Function() navigateToPurchaseScreen;
  final List<File> batchImages;
  final bool isProcessing;
  final int remainingUsages;
  final int processedImages;
  final int totalImagesToProcess;
  final int extractedWordsCount;
  final bool showDetailedProgress;

  const CaptureTab({
    Key? key,
    required this.onTakePhoto,
    required this.onPickImage,
    required this.onClearImages,
    required this.navigateToPurchaseScreen,
    required this.batchImages,
    required this.isProcessing,
    required this.remainingUsages,
    required this.processedImages,
    required this.totalImagesToProcess,
    required this.extractedWordsCount,
    required this.showDetailedProgress,
  }) : super(key: key);

  @override
  State<CaptureTab> createState() => _CaptureTabState();
}

class _CaptureTabState extends State<CaptureTab> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 사용량 표시 위젯 추가 (최상단)
          UsageIndicatorWidget(
            remainingUsages: widget.remainingUsages,
            onBuyPressed: widget.navigateToPurchaseScreen,
          ),
          if (widget.batchImages.isNotEmpty)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.amber.shade900.withOpacity(0.3)
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, color: isDarkMode 
                            ? Colors.amber.shade300
                            : Colors.amber.shade700),
                        SizedBox(width: 8),
                        Text(
                          '${widget.batchImages.length}장의 이미지가 선택됨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.amber.shade300
                                : Colors.amber.shade700,
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
                        itemCount: widget.batchImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image.file(
                                    widget.batchImages[index],
                                    width: 150,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      onTap: () {
                                        // 이미지 제거 기능은 부모 위젯에서 처리 필요
                                        // 현재는 모든 이미지 초기화만 지원
                                        widget.onClearImages();
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
                    // 햄스터 이모지 또는 아이콘 추가
                    Text(
                      '🐹',
                      style: TextStyle(fontSize: 72),
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
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber.shade900.withOpacity(0.3)
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.amber.shade900.withOpacity(0.3)
                              : Colors.amber.shade100,
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
                                  ? Colors.amber.shade700
                                  : Colors.amber.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.remainingUsages > 0 ? "사용 가능" : "충전 필요",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.amber.shade100
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.isProcessing)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                  ),
                ),
                SizedBox(height: 16),
                if (widget.showDetailedProgress) ...[
                  Text('이미지 처리 중: ${widget.processedImages} / ${widget.totalImagesToProcess}'),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: widget.processedImages / widget.totalImagesToProcess,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.amber.shade300
                          : Colors.amber.shade700,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('추출된 단어: ${widget.extractedWordsCount}개'),
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
                          onPressed: widget.isProcessing ? null : widget.onTakePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('촬영하기'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.amber.shade700 // 다크모드
                                    : Colors.amber.shade600, // 라이트모드
                            foregroundColor: Colors.white, // 텍스트는 항상 흰색으로
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.isProcessing ? null : widget.onPickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('갤러리'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.lightBlue.shade700 // 다크모드
                                    : Colors.lightBlue.shade500, // 라이트모드
                            foregroundColor: Colors.white, // 텍스트는 항상 흰색으로
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.batchImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton(
                        onPressed: widget.onClearImages,
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
}