import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/assets/assets.dart';
import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/services.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => ProfileContentState();
}

class ProfileContentState extends State<ProfileContent> {
  final CarRepository _carRepository = sl<CarRepository>();
  final ImageService _imageService = sl<ImageService>();

  int _totalCars = 0;
  int _totalSeries = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final totalCars = await _carRepository.getTotalCount();
      final allSeries = await _carRepository.getAllSeries();
      setState(() {
        _totalCars = totalCars;
        _totalSeries = allSeries.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void refresh() {
    _loadStats();
  }

  Future<void> _deleteAllData() async {
    // Clean up all images (passing empty list means all images are orphaned)
    await _imageService.cleanupOrphanedImages([]);
    await _carRepository.deleteAllCars();
    _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data deleted'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        title: Text(
          'Delete All Data',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete all cars from your collection? This action cannot be undone.',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllData();
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.verticalLg,
              // Header Section
              _buildHeader(),
              AppSpacing.verticalXl,
              // Stats Cards
              _buildStatsSection(),
              AppSpacing.verticalLg,
              // About Section
              _buildSectionHeader(
                icon: Icons.info_outline_rounded,
                title: 'About',
              ),
              AppSpacing.verticalMd,
              _buildAboutCard(),
              AppSpacing.verticalLg,
              // Danger Zone
              _buildSectionHeader(
                icon: Icons.warning_amber_rounded,
                title: 'Danger Zone',
                color: AppColors.error,
              ),
              AppSpacing.verticalMd,
              _buildDangerZone(),
              AppSpacing.verticalXl,
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SoftCard(
      padding: EdgeInsets.all(24.w),
      color: AppColors.primary,
      elevation: 10,
      shadowColor: AppColors.primary.withValues(alpha: 0.6),
      child: Row(
        children: [
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.tertiary,
                  AppColors.primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.tertiary.withValues(alpha: 0.4),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 36.sp,
            ),
          ),
          AppSpacing.horizontalLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collector',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalXs,
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _isLoading ? '-- cars' : '$_totalCars cars collected',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.directions_car_rounded,
            label: 'Total Cars',
            value: _isLoading ? '--' : '$_totalCars',
            color: AppColors.tertiary,
          ),
        ),
        AppSpacing.horizontalMd,
        Expanded(
          child: _buildStatCard(
            icon: Icons.layers_rounded,
            label: 'Series',
            value: _isLoading ? '--' : '$_totalSeries',
            color: AppColors.success,
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
      padding: EdgeInsets.all(20.w),
      color: AppColors.primary,
      elevation: 6,
      shadowColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28.sp,
            ),
          ),
          AppSpacing.verticalMd,
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.verticalXs,
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Color? color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: color ?? Colors.white70,
            size: 18.sp,
          ),
        ),
        AppSpacing.horizontalMd,
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard() {
    return SoftCard(
      padding: EdgeInsets.all(20.w),
      color: AppColors.primary,
      elevation: 6,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Image.asset(
                  AppLogos.hotwheels,
                  width: 50.w,
                  height: 25.h,
                  fit: BoxFit.contain,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hot Vault',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'v1.0.0',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
              'Track and manage your Hot Wheels collection with ease. Add cars, organize by series, and keep your collection at your fingertips.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return SoftCard(
      padding: EdgeInsets.zero,
      color: AppColors.primary,
      elevation: 6,
      shadowColor: AppColors.error.withValues(alpha: 0.2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showDeleteConfirmation,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1.w,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.error,
                    size: 24.sp,
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete All Data',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        'Permanently remove all cars from your collection',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
