import 'package:flutter/material.dart';

class DataModeIndicator extends StatelessWidget {
  final bool isSimulated;
  final String label;

  const DataModeIndicator({
    super.key,
    this.isSimulated = true,
    this.label = 'DEMO MODE: Simulated Safety Data',
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSimulated
        ? const Color(0xFFFFF3CD)
        : const Color(0xFFD1E7DD);
    final borderColor = isSimulated
        ? const Color(0xFFFFEEBA)
        : const Color(0xFFBADBCC);
    final textColor = isSimulated
        ? const Color(0xFF856404)
        : const Color(0xFF0F5132);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSimulated ? Icons.science_outlined : Icons.verified_user_outlined,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
