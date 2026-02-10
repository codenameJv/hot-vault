import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/assets/assets.dart';
import '../../../../core/database/database.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final CarRepository _carRepository = CarRepository();
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

  Color _getConditionColor(String condition) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _favoriteCars.length,
                            itemBuilder: (context, index) {
                              final car = _favoriteCars[index];
                              return _buildCarCard(car);
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
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => context.go(Routes.home),
                icon: Icon(
                  Icons.home_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 28,
                ),
              ),
              IconButton(
                onPressed: () => context.go(Routes.collection),
                icon: Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 28,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              IconButton(
                onPressed: () => context.go(Routes.profile),
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 28,
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
        padding: const EdgeInsets.all(20),
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
                size: 80,
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

  Widget _buildCarCard(HotWheelsCar car) {
    return GestureDetector(
      onTap: () async {
        final result = await context.push('${Routes.carDetail}/${car.id}');
        if (result == true) {
          _loadFavorites();
        }
      },
      child: SoftCard(
        padding: AppSpacing.paddingMd,
        color: AppColors.primary,
        elevation: 6,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
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
            ),
            AppSpacing.verticalSm,
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
            AppSpacing.verticalXs,
            // Condition badge and favorite
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (car.condition != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getConditionColor(car.condition!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      car.condition!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => _toggleFavorite(car),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
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
        size: 40,
      ),
    );
  }
}
