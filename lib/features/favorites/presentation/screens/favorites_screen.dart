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
import '../../../../core/models/models.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final CarRepository _carRepository = sl<CarRepository>();
  List<HotWheelsCar> _favoriteCars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final cars = await _carRepository.getFavoriteCars();
      setState(() {
        _favoriteCars = cars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(HotWheelsCar car) async {
    await _carRepository.toggleFavorite(car.id, !car.isFavorite);
    _loadFavorites();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.verticalLg,
                    Text(
                      'Favorites',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.verticalSm,
                    Text(
                      '${_favoriteCars.length} favorite${_favoriteCars.length == 1 ? '' : 's'}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalLg,
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _favoriteCars.isEmpty
                        ? _buildEmptyState()
                        : GridView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16.h,
                              crossAxisSpacing: 16.w,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _favoriteCars.length,
                            itemBuilder: (context, index) {
                              final car = _favoriteCars[index];
                              return CarCard(
                                car: car,
                                showDeleteButton: false,
                                onTap: () async {
                                  final result = await context
                                      .push('${Routes.carDetail}/${car.id}');
                                  if (result == true) {
                                    _loadFavorites();
                                  }
                                },
                                onFavoriteToggle: () => _toggleFavorite(car),
                              );
                            },
                          ),
              ),
            ],
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
                onPressed: () {},
                icon: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: SoftCard(
          padding: AppSpacing.paddingXl,
          color: AppColors.primary,
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 80.sp,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              AppSpacing.verticalLg,
              Text(
                'No favorites yet',
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white70,
                ),
              ),
              AppSpacing.verticalSm,
              Text(
                'Tap the heart icon on any car\nto add it to your favorites',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white38,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalXl,
              SoftButton.outline(
                onPressed: () => context.go(Routes.collection),
                text: 'Browse Collection',
              ),
            ],
          ),
        ),
      ),
    );
  }

}
