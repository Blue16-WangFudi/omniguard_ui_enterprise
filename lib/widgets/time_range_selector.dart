import 'package:flutter/material.dart';

class TimeRange {
  final String label;
  final int seconds;

  const TimeRange(this.label, this.seconds);
}

class TimeRangeSelector extends StatelessWidget {
  final TimeRange selectedRange;
  final Function(TimeRange) onRangeSelected;
  final List<TimeRange> availableRanges;

  const TimeRangeSelector({
    Key? key,
    required this.selectedRange,
    required this.onRangeSelected,
    required this.availableRanges,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: availableRanges.map((range) => _buildRangeButton(range)).toList(),
        ),
      ),
    );
  }

  Widget _buildRangeButton(TimeRange range) {
    final isSelected = range.seconds == selectedRange.seconds;

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        backgroundColor: isSelected ? const Color.fromRGBO(1, 102, 255, 1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        minimumSize: const Size(0, 32),
      ),
      onPressed: () {
        onRangeSelected(range);
      },
      child: Text(
        range.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontFamily: 'HarmonyOS_Sans',
        ),
      ),
    );
  }
}
