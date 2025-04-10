// lib/screens/tabs/flash_card_tab.dart
import 'package:flutter/material.dart';
import 'package:vocabulary_app/model/word_entry.dart';
import 'package:vocabulary_app/services/tts_service.dart';
import 'package:vocabulary_app/screens/modern_flash_card_screen.dart';

class FlashCardTab extends StatefulWidget {
  final List<WordEntry> words;
  final Function(String, {AccentType? accent}) onSpeakWord;
  final Function(String)? onReviewComplete;
  final Map<String, List<WordEntry>> dayCollections;
  final String currentDay;
  final Function(String) onDayChanged;
  final Function() navigateToCaptureTab;

  const FlashCardTab({
    Key? key,
    required this.words,
    required this.onSpeakWord,
    this.onReviewComplete,
    required this.dayCollections,
    required this.currentDay,
    required this.onDayChanged,
    required this.navigateToCaptureTab,
  }) : super(key: key);

  @override
  State<FlashCardTab> createState() => _FlashCardTabState();
}

class _FlashCardTabState extends State<FlashCardTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.dayCollections.isEmpty) {
      return _buildEmptyState();
    }

    // 단어장 선택 영역 추가
    return Column(
      children: [
        _buildDaySelector(),
        // 단어 개수 정보 표시 (선택된 단어장에 단어가 없는 경우 처리)
        if (widget.dayCollections[widget.currentDay]?.isEmpty ?? true)
          Expanded(
            child: _buildEmptyDayState(),
          )
        else
          // 플래시카드 화면
          Expanded(
            child: ModernFlashCardScreen(
              words: widget.dayCollections[widget.currentDay] ?? [],
              onSpeakWord: widget.onSpeakWord,
              onReviewComplete: widget.onReviewComplete,
            ),
          ),
      ],
    );
  }

  // 단어장 선택기
  Widget _buildDaySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
              color: Theme.of(context).cardColor,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: widget.dayCollections.keys.contains(widget.currentDay)
                    ? widget.currentDay
                    : widget.dayCollections.keys.first,
                items: widget.dayCollections.keys.map((String day) {
                  final count = widget.dayCollections[day]?.length ?? 0;
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          day,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green.shade900.withOpacity(0.3)
                                    : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$count단어',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.green.shade300
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    widget.onDayChanged(newValue);
                  }
                },
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).iconTheme.color,
                ),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
                dropdownColor: Theme.of(context).cardColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 빈 상태 UI (단어장이 없음)
  Widget _buildEmptyState() {
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
            onPressed: widget.navigateToCaptureTab,
            icon: Icon(Icons.add_photo_alternate),
            label: Text('단어 추가하기'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green.shade700
                  : Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 빈 단어장 상태 UI (현재 선택된 단어장에 단어가 없음)
  Widget _buildEmptyDayState() {
    return Center(
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
            '${widget.currentDay}에 저장된 단어가 없습니다.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.navigateToCaptureTab,
            child: Text('단어 추가하기'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green.shade700
                  : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
