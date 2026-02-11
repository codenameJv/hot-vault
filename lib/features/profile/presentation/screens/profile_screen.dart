import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/assets/assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/services.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: AppConstants.toolbarHeight,
        leadingWidth: 120,
        leading: Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Image.asset(
            AppLogos.hotwheels,
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.verticalLg,
                Text(
                  'Profile',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSm,
                Text(
                  'Collector settings & stats',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white54,
                  ),
                ),
                AppSpacing.verticalXl,
                // Stats Card
                SoftCard(
                  padding: AppSpacing.paddingLg,
                  color: AppColors.primary,
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.bar_chart_rounded,
                            color: Colors.white70,
                          ),
                          AppSpacing.horizontalSm,
                          Text(
                            'Collection Stats',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalLg,
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Total Cars',
                              _isLoading ? '--' : '$_totalCars',
                              Icons.directions_car_rounded,
                            ),
                          ),
                          Container(
                            width: 1.w,
                            height: 50.h,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Series',
                              _isLoading ? '--' : '$_totalSeries',
                              Icons.category_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalMd,
                // Settings Section
                Text(
                  'Settings',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.verticalMd,
                SoftCard(
                  padding: EdgeInsets.zero,
                  color: AppColors.primary,
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Coming soon',
                        onTap: () {},
                        enabled: false,
                      ),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _buildSettingItem(
                        icon: Icons.cloud_sync_outlined,
                        title: 'Backup & Sync',
                        subtitle: 'Coming soon',
                        onTap: () {},
                        enabled: false,
                      ),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _buildSettingItem(
                        icon: Icons.palette_outlined,
                        title: 'Appearance',
                        subtitle: 'Coming soon',
                        onTap: () {},
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalMd,
                // Danger Zone
                Text(
                  'Danger Zone',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.verticalMd,
                SoftCard(
                  padding: EdgeInsets.zero,
                  color: AppColors.primary,
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  child: _buildSettingItem(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete All Data',
                    subtitle: 'Permanently delete all cars',
                    onTap: _showDeleteConfirmation,
                    iconColor: AppColors.error,
                    titleColor: AppColors.error,
                  ),
                ),
                AppSpacing.verticalMd,
                // About Section
                Text(
                  'About',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.verticalMd,
                SoftCard(
                  padding: AppSpacing.paddingLg,
                  color: AppColors.primary,
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            AppLogos.hotwheels,
                            width: 60.w,
                            height: 30.h,
                            fit: BoxFit.contain,
                          ),
                          AppSpacing.horizontalMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hot Vault',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Version 1.0.0',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalMd,
                      Text(
                        'Track and manage your Hot Wheels collection with ease.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalXl,
                SizedBox(height: 80.h),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.tertiary,
        elevation: 0,
        child: SizedBox(
          height: 60.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => context.go(Routes.home),
                icon: Icon(
                  Icons.home_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 28.sp,
                ),
              ),
              IconButton(
                onPressed: () => context.go(Routes.collection),
                icon: Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 28.sp,
                ),
              ),
              IconButton(
                onPressed: () => context.go(Routes.favorites),
                icon: Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 28.sp,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 28.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 24.sp,
        ),
        AppSpacing.verticalSm,
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled
                    ? (iconColor ?? Colors.white70)
                    : Colors.white38,
                size: 24.sp,
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: enabled
                            ? (titleColor ?? Colors.white)
                            : Colors.white54,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
