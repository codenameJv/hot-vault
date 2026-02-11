import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../providers/home_providers.dart';

class HomeContent extends ConsumerWidget {
  final VoidCallback? onNavigateToCollection;
  final VoidCallback? onNavigateToFavorites;

  const HomeContent({
    super.key,
    this.onNavigateToCollection,
    this.onNavigateToFavorites,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);

    return AppBackground(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              AppSpacing.verticalLg,
              // Total Collection Card
              GestureDetector(
                onTap: onNavigateToCollection,
                child: SoftCard(
                  padding: AppSpacing.paddingLg,
                  color: AppColors.primary,
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
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
                                state.isLoading ? '--' : '${state.totalCount}',
                                style: AppTextStyles.displayLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AppSpacing.verticalMd,
              // Stats Row
              Row(
                children: [
                  // Total Series Card
                  Expanded(
                    child: GestureDetector(
                      onTap: onNavigateToCollection,
                      child: SoftCard(
                        padding: AppSpacing.paddingLg,
                        color: AppColors.primary,
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.layers_rounded,
                                  color: Colors.white70,
                                  size: 18.sp,
                                ),
                                AppSpacing.horizontalXs,
                                Text(
                                  'Series',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.verticalSm,
                            Text(
                              state.isLoading ? '--' : '${state.totalSeries}',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  // Favorites Card
                  Expanded(
                    child: GestureDetector(
                      onTap: onNavigateToFavorites,
                      child: SoftCard(
                        padding: AppSpacing.paddingLg,
                        color: AppColors.primary,
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.white70,
                                  size: 18.sp,
                                ),
                                AppSpacing.horizontalXs,
                                Text(
                                  'Favorites',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.verticalSm,
                            Text(
                              state.isLoading ? '--' : '${state.favoritesCount}',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : state.recentActivity.isEmpty
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
                                    'Tap + to add your first car',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: state.recentActivity.length,
                              itemBuilder: (context, index) {
                                final car = state.recentActivity[index];
                                return _buildActivityItem(
                                  context: context,
                                  ref: ref,
                                  name: car.name,
                                  date: _formatDate(car.createdAt),
                                  onTap: () async {
                                    final result = await context
                                        .push('${Routes.carDetail}/${car.id}');
                                    if (result == true) {
                                      ref.read(homeProvider.notifier).refresh();
                                    }
                                  },
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
    );
  }

  Widget _buildActivityItem({
    required BuildContext context,
    required WidgetRef ref,
    required String name,
    required String date,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
            AppSpacing.horizontalSm,
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
