import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/models/models.dart';
import '../../core/utils/condition_helper.dart';
import '../styles/app_spacing.dart';
import 'soft_card.dart';

class CarCard extends StatelessWidget {
  final HotWheelsCar car;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;
  final bool showDeleteButton;
  final int? duplicateCount;

  const CarCard({
    super.key,
    required this.car,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
    this.showDeleteButton = true,
    this.duplicateCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SoftCard(
        padding: EdgeInsets.all(12.w),
        color: AppColors.primary,
        elevation: 6,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: car.imagePath != null
                        ? ClipRRect(
                            borderRadius: AppSpacing.borderRadiusSm,
                            child: Image.file(
                              File(car.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(),
                            ),
                          )
                        : _buildPlaceholder(),
                  ),
                  // Duplicate count badge
                  if (duplicateCount != null && duplicateCount! > 1)
                    Positioned(
                      top: 6.h,
                      right: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '×$duplicateCount',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            // Car name
            Text(
              car.name,
              style: AppTextStyles.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (car.series != null || car.year != null)
              Text(
                [
                  if (car.series != null) car.series,
                  if (car.year != null) car.year.toString(),
                ].join(' - '),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 4.h),
            // Condition badge and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (car.condition != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: ConditionHelper.getColor(car.condition!),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      car.condition!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onFavoriteToggle != null)
                      GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Icon(
                          car.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: car.isFavorite
                              ? AppColors.error
                              : Colors.white.withValues(alpha: 0.5),
                          size: 18.sp,
                        ),
                      ),
                    if (showDeleteButton && onDelete != null) ...[
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 18.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.directions_car_rounded,
        color: Colors.white.withValues(alpha: 0.3),
        size: 40.sp,
      ),
    );
  }
}
