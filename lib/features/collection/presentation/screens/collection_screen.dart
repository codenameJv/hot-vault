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
import '../../../../core/services/services.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final CarRepository _carRepository = sl<CarRepository>();
  final ImageService _imageService = sl<ImageService>();
  final TextEditingController _searchController = TextEditingController();

  List<HotWheelsCar> _cars = [];
  List<HotWheelsCar> _filteredCars = [];
  bool _isLoading = true;
  SortField _sortField = SortField.createdAt;
  SortOrder _sortOrder = SortOrder.descending;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCars() async {
    setState(() => _isLoading = true);
    try {
      final cars = await _carRepository.getAllCars(
        sortBy: _sortField,
        order: _sortOrder,
      );
      setState(() {
        _cars = cars;
        _filteredCars = cars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterCars(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCars = _cars);
    } else {
      setState(() {
        _filteredCars = _cars.where((car) {
          final nameLower = car.name.toLowerCase();
          final seriesLower = car.series?.toLowerCase() ?? '';
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              seriesLower.contains(queryLower);
        }).toList();
      });
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tertiary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
            ),
            AppSpacing.verticalMd,
            _buildSortOption('Recently Added', SortField.createdAt, SortOrder.descending),
            _buildSortOption('Oldest First', SortField.createdAt, SortOrder.ascending),
            _buildSortOption('Name (A-Z)', SortField.name, SortOrder.ascending),
            _buildSortOption('Name (Z-A)', SortField.name, SortOrder.descending),
            _buildSortOption('Year (Newest)', SortField.year, SortOrder.descending),
            _buildSortOption('Year (Oldest)', SortField.year, SortOrder.ascending),
            AppSpacing.verticalMd,
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, SortField field, SortOrder order) {
    final isSelected = _sortField == field && _sortOrder == order;
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isSelected ? AppColors.primary : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          _sortField = field;
          _sortOrder = order;
        });
        Navigator.pop(context);
        _loadCars();
      },
    );
  }

  Future<void> _toggleFavorite(HotWheelsCar car) async {
    await _carRepository.toggleFavorite(car.id, !car.isFavorite);
    _loadCars();
  }

  Future<void> _deleteCar(HotWheelsCar car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        title: Text(
          'Delete Car',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${car.name}"?',
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

    if (confirmed == true) {
      // Delete image file if exists
      if (car.imagePath != null) {
        await _imageService.deleteImage(car.imagePath!);
      }
      await _carRepository.deleteCar(car.id);
      _loadCars();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${car.name} deleted'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
        actions: [
          IconButton(
            icon: Icon(Icons.sort_rounded, color: Colors.white, size: 24.sp),
            onPressed: _showSortOptions,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: SoftCard(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  color: AppColors.primary,
                  elevation: 4,
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      AppSpacing.horizontalMd,
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search cars...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: _filterCars,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _filterCars('');
                          },
                        ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalMd,
              // Results count
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredCars.length} cars',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalMd,
              // Grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _filteredCars.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 64.sp,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                AppSpacing.verticalMd,
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No cars found'
                                      : 'No cars in collection',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                                if (_searchController.text.isEmpty) ...[
                                  AppSpacing.verticalSm,
                                  Text(
                                    'Add your first car!',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16.h,
                              crossAxisSpacing: 16.w,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _filteredCars.length,
                            itemBuilder: (context, index) {
                              final car = _filteredCars[index];
                              return CarCard(
                                car: car,
                                onTap: () async {
                                  final result = await context
                                      .push('${Routes.carDetail}/${car.id}');
                                  if (result == true) {
                                    _loadCars();
                                  }
                                },
                                onFavoriteToggle: () => _toggleFavorite(car),
                                onDelete: () => _deleteCar(car),
                              );
                            },
                          ),
              ),
            ],
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
          heroTag: 'collection_add',
          onPressed: () async {
            final result = await context.push(Routes.addCar);
            if (result == true) {
              _loadCars();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 28.sp,
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
                onPressed: () {},
                icon: Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
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

}
