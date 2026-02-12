import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/services.dart';
import '../../../../core/utils/utils.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class CarDetailScreen extends StatefulWidget {
  final String carId;

  const CarDetailScreen({super.key, required this.carId});

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  final CarRepository _carRepository = sl<CarRepository>();
  final ImageService _imageService = sl<ImageService>();
  HotWheelsCar? _car;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCar();
  }

  Future<void> _loadCar() async {
    setState(() => _isLoading = true);
    try {
      final car = await _carRepository.getCarById(widget.carId);
      setState(() {
        _car = car;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load car: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteCar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        title: Text(
          'Delete Car',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${_car?.name}"?',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && _car != null) {
      // Delete image file if exists
      if (_car!.imagePath != null) {
        await _imageService.deleteImage(_car!.imagePath!);
      }
      await _carRepository.deleteCar(_car!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_car!.name} deleted'),
            backgroundColor: AppColors.error,
          ),
        );
        context.pop(true);
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  Future<void> _toggleFavorite() async {
    if (_car == null) return;
    await _carRepository.toggleFavorite(_car!.id, !_car!.isFavorite);
    _hasChanges = true;
    _loadCar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
            onPressed: () => context.pop(_hasChanges),
          ),
        ),
        actions: [
          if (_car != null) ...[
            Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _car!.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _car!.isFavorite ? AppColors.error : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ),
            SizedBox(width: 4.w),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.edit_rounded, color: Colors.white, size: 24.sp),
                onPressed: () async {
                  final result = await context.push(
                    '${Routes.editCar}/${_car!.id}',
                  );
                  if (result == true) {
                    _hasChanges = true;
                    _loadCar();
                  }
                },
              ),
            ),
            SizedBox(width: 4.w),
            Container(
              margin: EdgeInsets.only(top: 8.h, bottom: 8.h, right: 8.w),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24.sp),
                onPressed: _deleteCar,
              ),
            ),
          ],
        ],
      ),
      body: AppBackground(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _car == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64.sp,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        AppSpacing.verticalMd,
                        Text(
                          'Car not found',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Image Section
                        _buildHeroImageSection(),
                        // Content Section
                        Transform.translate(
                          offset: Offset(0, -30.h),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(30.r),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 20.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Car Name & Info Header
                                  _buildCarHeader(),
                                  AppSpacing.verticalLg,
                                  // Quick Stats Row
                                  _buildQuickStats(),
                                  // Price Section
                                  if (_car!.purchasePrice != null || _car!.sellingPrice != null) ...[
                                    AppSpacing.verticalMd,
                                    _buildPriceStats(),
                                  ],
                                  AppSpacing.verticalLg,
                                  // Details Section
                                  _buildDetailsSection(),
                                  // Notes Section
                                  if (_car!.notes != null && _car!.notes!.isNotEmpty) ...[
                                    AppSpacing.verticalMd,
                                    _buildNotesSection(),
                                  ],
                                  AppSpacing.verticalXl,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeroImageSection() {
    return SizedBox(
      height: 350.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          _car!.imagePath != null
              ? Image.file(
                  File(_car!.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildHeroPlaceholder(),
                )
              : _buildHeroPlaceholder(),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  AppColors.surface.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_rounded,
            size: 80.sp,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          AppSpacing.verticalSm,
          Text(
            'No image',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarHeader() {
    return Column(
      children: [
        // Hunt Type Badge (STH/RTH)
        if (_car!.huntType != HuntType.normal) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _car!.huntType == HuntType.sth
                    ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                    : [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: (_car!.huntType == HuntType.sth
                          ? const Color(0xFFFFD700)
                          : AppColors.success)
                      .withValues(alpha: 0.4),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _car!.huntType == HuntType.sth ? Icons.star_rounded : Icons.local_fire_department_rounded,
                  color: _car!.huntType == HuntType.sth ? Colors.black87 : Colors.white,
                  size: 18.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  _car!.huntType == HuntType.sth ? 'SUPER TREASURE HUNT' : 'REGULAR TREASURE HUNT',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _car!.huntType == HuntType.sth ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalMd,
        ],
        // Car Name
        Text(
          _car!.name,
          style: AppTextStyles.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (_car!.series != null || _car!.year != null || _car!.segment != null) ...[
          AppSpacing.verticalSm,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              if (_car!.series != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _car!.series!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              if (_car!.segment != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _car!.segment!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              if (_car!.year != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _car!.year.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        // Condition
        if (_car!.condition != null)
          Expanded(
            child: _buildStatCard(
              icon: Icons.stars_rounded,
              label: 'Condition',
              value: _car!.condition!,
              color: ConditionHelper.getColor(_car!.condition!),
            ),
          ),
        if (_car!.condition != null && _car!.acquiredDate != null)
          AppSpacing.horizontalMd,
        // Acquired
        if (_car!.acquiredDate != null)
          Expanded(
            child: _buildStatCard(
              icon: Icons.event_rounded,
              label: 'Acquired',
              value: DateFormat('MMM d, yyyy').format(_car!.acquiredDate!),
              color: AppColors.secondary,
            ),
          ),
      ],
    );
  }

  Widget _buildPriceStats() {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return Row(
      children: [
        // Purchase Price
        if (_car!.purchasePrice != null)
          Expanded(
            child: _buildStatCard(
              icon: Icons.shopping_cart_rounded,
              label: 'Paid',
              value: currencyFormat.format(_car!.purchasePrice),
              color: AppColors.success,
            ),
          ),
        if (_car!.purchasePrice != null && _car!.sellingPrice != null)
          AppSpacing.horizontalMd,
        // Selling Price
        if (_car!.sellingPrice != null)
          Expanded(
            child: _buildStatCard(
              icon: Icons.sell_rounded,
              label: 'Selling For',
              value: currencyFormat.format(_car!.sellingPrice),
              color: AppColors.tertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return SoftCard(
      padding: EdgeInsets.all(16.w),
      color: AppColors.primary,
      elevation: 6,
      shadowColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
          ),
          AppSpacing.verticalSm,
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white54,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return SoftCard(
      padding: AppSpacing.paddingLg,
      color: AppColors.primary,
      elevation: 6,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              AppSpacing.horizontalMd,
              Text(
                'Details',
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.verticalLg,
          _buildDetailItem(
            icon: Icons.add_circle_outline_rounded,
            label: 'Added to Collection',
            value: _formatDate(_car!.createdAt),
          ),
          if (_car!.updatedAt != _car!.createdAt) ...[
            _buildDivider(),
            _buildDetailItem(
              icon: Icons.update_rounded,
              label: 'Last Updated',
              value: _formatDate(_car!.updatedAt),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Container(
        height: 1.h,
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.5),
          size: 20.sp,
        ),
        AppSpacing.horizontalMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white54,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return SoftCard(
      padding: AppSpacing.paddingLg,
      color: AppColors.primary,
      elevation: 6,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notes_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              AppSpacing.horizontalMd,
              Text(
                'Notes',
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.verticalMd,
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              _car!.notes!,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
