import 'package:flutter/material.dart';
import '../utils/theme.dart';

class StatusIndicator extends StatelessWidget {
  final bool isActive;
  final String activeText;
  final String inactiveText;

  const StatusIndicator({
    super.key,
    required this.isActive,
    this.activeText = 'Active',
    this.inactiveText = 'Inactive',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.successColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppTheme.successColor : Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.successColor : Colors.grey,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.successColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isActive ? activeText : inactiveText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isActive ? AppTheme.successColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
