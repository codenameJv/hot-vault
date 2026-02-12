import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/models/models.dart';
import '../../core/utils/condition_helper.dart';
import '../styles/app_spacing.dart';
import 'soft_button.dart';

enum DuplicateAction { addAnyway, viewExisting, cancel }

class DuplicateCarSheet extends StatelessWidget {
  final List<HotWheelsCar> existingCars;
  final String newCarName;

  const DuplicateCarSheet({
    super.key,
    required this.existingCars,
    required this.newCarName,
  });

  static Future<DuplicateAction?> show(
    BuildContext context, {
    required List<HotWheelsCar> existingCars,
    required String newCarName,
  }) {
    return showModalBottomSheet<DuplicateAction>(
      context: context,
      backgroundColor: AppColors.tertiary,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => DuplicateCarSheet(
        existingCars: existingCars,
        newCarName: newCarName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = existingCars.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.warning,
                  size: 48.sp,
                ),
                AppSpacing.verticalMd,
                Text(
                  'Duplicate Found',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalXs,
                Text(
                  'You already have $count ${count == 1 ? 'copy' : 'copies'} of "$newCarName" in your collection.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Existing cars list
          if (existingCars.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Existing in collection:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
            AppSpacing.verticalSm,
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: existingCars.length,
                itemBuilder: (context, index) {
                  final car = existingCars[index];
                  return _ExistingCarTile(
                    car: car,
                    onTap: () => Navigator.pop(context, DuplicateAction.viewExisting),
                  );
                },
              ),
            ),
          ],
          // Action buttons
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                SoftButton.primary(
                  onPressed: () => Navigator.pop(context, DuplicateAction.addAnyway),
                  text: 'Add Anyway',
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
                AppSpacing.verticalSm,
                SoftButton.secondary(
                  onPressed: () => Navigator.pop(context, DuplicateAction.cancel),
                  text: 'Cancel',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingCarTile extends StatelessWidget {
  final HotWheelsCar car;
  final VoidCallback? onTap;

  const _ExistingCarTile({
    required this.car,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: car.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.file(
                        File(car.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      ),
                    )
                  : _buildPlaceholder(),
            ),
            AppSpacing.horizontalMd,
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
                  AppSpacing.verticalXs,
                  Row(
                    children: [
                      if (car.condition != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: ConditionHelper.getColor(car.condition!),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            car.condition!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9.sp,
                            ),
                          ),
                        ),
                      if (car.huntType != HuntType.normal) ...[
                        SizedBox(width: 4.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: car.huntType == HuntType.sth
                                ? AppColors.warning
                                : Colors.green,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            car.huntType == HuntType.sth ? 'STH' : 'RTH',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
              size: 20.sp,
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
        size: 24.sp,
      ),
    );
  }
}
