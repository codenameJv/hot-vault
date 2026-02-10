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

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final CarRepository _carRepository = CarRepository();
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
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
        toolbarHeight: 70,
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset(
            AppLogos.hotwheels,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            onPressed: _showSortOptions,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  size: 64,
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _filteredCars.length,
                            itemBuilder: (context, index) {
                              final car = _filteredCars[index];
                              return _buildCarCard(car);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
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
              blurRadius: 12,
              offset: const Offset(0, 4),
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
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
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
                onPressed: () {},
                icon: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              IconButton(
                onPressed: () => context.go(Routes.favorites),
                icon: Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
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

  Widget _buildCarCard(HotWheelsCar car) {
    return GestureDetector(
      onTap: () async {
        final result = await context.push('${Routes.carDetail}/${car.id}');
        if (result == true) {
          _loadCars();
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
            // Condition badge and actions
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleFavorite(car),
                      child: Icon(
                        car.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: car.isFavorite
                            ? AppColors.error
                            : Colors.white.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteCar(car),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ),
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
        size: 40,
      ),
    );
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
}
