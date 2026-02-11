import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/assets/assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CarRepository _carRepository = sl<CarRepository>();

  int _totalCount = 0;
  int _totalSeries = 0;
  HotWheelsCar? _recentAddition;
  List<HotWheelsCar> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final count = await _carRepository.getTotalCount();
      final recentCars = await _carRepository.getRecentCars(limit: 5);
      final allSeries = await _carRepository.getAllSeries();

      setState(() {
        _totalCount = count;
        _totalSeries = allSeries.length;
        _recentAddition = recentCars.isNotEmpty ? recentCars.first : null;
        _recentActivity = recentCars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                AppSpacing.verticalLg,
                // Total Collection Card
                SoftCard(
                  padding: AppSpacing.paddingLg,
                  color: AppColors.primary,
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Collection',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        AppSpacing.verticalSm,
                        Text(
                          _isLoading ? '--' : '$_totalCount',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.verticalMd,
                // Favorites Row
                Row(
                  children: [
                    // Total Series Card
                    Expanded(
                      child: SoftCard(
                        padding: AppSpacing.paddingLg,
                        color: AppColors.primary,
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Series',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            AppSpacing.verticalSm,
                            Text(
                              _isLoading ? '--' : '$_totalSeries',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.horizontalMd,
                    // Recent Addition Card
                    Expanded(
                      child: SoftCard(
                        padding: AppSpacing.paddingLg,
                        color: AppColors.primary,
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Addition',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            AppSpacing.verticalSm,
                            Text(
                              _recentAddition?.name ?? '--',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalLg,
                // Recent Activity Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recent Activity',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppSpacing.verticalMd,
                Expanded(
                  child: SoftCard(
                    padding: AppSpacing.paddingLg,
                    color: AppColors.primary,
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : _recentActivity.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_car_outlined,
                                      size: 48.sp,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                    AppSpacing.verticalMd,
                                    Text(
                                      'No cars yet',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: Colors.white54,
                                      ),
                                    ),
                                    AppSpacing.verticalSm,
                                    Text(
                                      'Tap the camera to add your first car',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _recentActivity.length,
                                itemBuilder: (context, index) {
                                  final car = _recentActivity[index];
                                  return _buildActivityItem(
                                    name: car.name,
                                    date: _formatDate(car.createdAt),
                                  );
                                },
                              ),
                  ),
                ),
                AppSpacing.verticalMd,
                // Space for bottom nav
                SizedBox(height: 80.h),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        height: 64.w,
        width: 64.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'home_add',
          onPressed: () async {
            final result = await context.push(Routes.addCar);
            if (result == true) {
              _loadData();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 28.sp,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.tertiary,
        elevation: 0,
        notchMargin: 8.w,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left side items
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.home_rounded,
                        color: AppColors.primary,
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
                  ],
                ),
              ),
              // Space for FAB
              SizedBox(width: 64.w),
              // Right side items
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => context.go(Routes.favorites),
                      icon: Icon(
                        Icons.favorite_border_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 28.sp,
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go(Routes.profile),
                      icon: Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 28.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String name,
    required String date,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.horizontalMd,
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          Text(
            date,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
