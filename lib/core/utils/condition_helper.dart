import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

abstract final class ConditionHelper {
  static const List<String> conditions = [
    'Mint',
    'Near Mint',
    'Excellent',
    'Good',
    'Fair',
    'Poor',
  ];

  static Color getColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'mint':
        return AppColors.success;
      case 'near mint':
        return AppColors.success.withValues(alpha: 0.8);
      case 'excellent':
        return Colors.blue;
      case 'good':
        return AppColors.warning;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
}
