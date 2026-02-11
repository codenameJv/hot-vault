import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/services.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class CollectionContent extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const CollectionContent({
    super.key,
    this.onDataChanged,
  });

  @override
  State<CollectionContent> createState() => CollectionContentState();
}

class CollectionContentState extends State<CollectionContent> {
  final CarRepository _carRepository = sl<CarRepository>();
  final ImageService _imageService = sl<ImageService>();
  final TextEditingController _searchController = TextEditingController();

  List<HotWheelsCar> _cars = [];
  List<HotWheelsCar> _filteredCars = [];
  bool _isLoading = true;
  SortField _sortField = SortField.createdAt;
  SortOrder _sortOrder = SortOrder.descending;

  // Filter options
  String? _selectedSeries;
  String? _selectedCondition;
  int? _selectedYear;
  List<String> _availableSeries = [];
  List<String> _availableConditions = [];
  List<int> _availableYears = [];
  int _activeFilterCount = 0;

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

      // Extract available filter options
      final seriesSet = <String>{};
      final conditionSet = <String>{};
      final yearSet = <int>{};

      for (final car in cars) {
        if (car.series != null && car.series!.isNotEmpty) {
          seriesSet.add(car.series!);
        }
        if (car.condition != null && car.condition!.isNotEmpty) {
          conditionSet.add(car.condition!);
        }
        if (car.year != null) {
          yearSet.add(car.year!);
        }
      }

      setState(() {
        _cars = cars;
        _availableSeries = seriesSet.toList()..sort();
        _availableConditions = conditionSet.toList()..sort();
        _availableYears = yearSet.toList()..sort((a, b) => b.compareTo(a));
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void refresh() {
    _loadCars();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredCars = _cars.where((car) {
        // Text search filter
        if (query.isNotEmpty) {
          final nameLower = car.name.toLowerCase();
          final seriesLower = car.series?.toLowerCase() ?? '';
          if (!nameLower.contains(query) && !seriesLower.contains(query)) {
            return false;
          }
        }

        // Series filter
        if (_selectedSeries != null && car.series != _selectedSeries) {
          return false;
        }

        // Condition filter
        if (_selectedCondition != null && car.condition != _selectedCondition) {
          return false;
        }

        // Year filter
        if (_selectedYear != null && car.year != _selectedYear) {
          return false;
        }

        return true;
      }).toList();

      // Count active filters
      _activeFilterCount = 0;
      if (_selectedSeries != null) _activeFilterCount++;
      if (_selectedCondition != null) _activeFilterCount++;
      if (_selectedYear != null) _activeFilterCount++;
    });
  }

  void _filterCars(String query) {
    _applyFilters();
  }

  void showSortOptions() {
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

  void showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tertiary,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedSeries = null;
                          _selectedCondition = null;
                          _selectedYear = null;
                        });
                        setState(() {});
                        _applyFilters();
                      },
                      child: Text(
                        'Clear All',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalMd,
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Series Filter
                      if (_availableSeries.isNotEmpty) ...[
                        _buildFilterSection(
                          title: 'Series',
                          icon: Icons.layers_rounded,
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: _availableSeries.map((series) {
                              final isSelected = _selectedSeries == series;
                              return FilterChip(
                                label: Text(series),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedSeries = selected ? series : null;
                                  });
                                  setState(() {});
                                  _applyFilters();
                                },
                                backgroundColor: AppColors.primary,
                                selectedColor: AppColors.tertiary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                                checkmarkColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.tertiary
                                      : Colors.white24,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        AppSpacing.verticalLg,
                      ],
                      // Condition Filter
                      if (_availableConditions.isNotEmpty) ...[
                        _buildFilterSection(
                          title: 'Condition',
                          icon: Icons.stars_rounded,
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: _availableConditions.map((condition) {
                              final isSelected = _selectedCondition == condition;
                              return FilterChip(
                                label: Text(condition),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedCondition = selected ? condition : null;
                                  });
                                  setState(() {});
                                  _applyFilters();
                                },
                                backgroundColor: AppColors.primary,
                                selectedColor: AppColors.tertiary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                                checkmarkColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.tertiary
                                      : Colors.white24,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        AppSpacing.verticalLg,
                      ],
                      // Year Filter
                      if (_availableYears.isNotEmpty) ...[
                        _buildFilterSection(
                          title: 'Year',
                          icon: Icons.calendar_today_rounded,
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: _availableYears.map((year) {
                              final isSelected = _selectedYear == year;
                              return FilterChip(
                                label: Text(year.toString()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedYear = selected ? year : null;
                                  });
                                  setState(() {});
                                  _applyFilters();
                                },
                                backgroundColor: AppColors.primary,
                                selectedColor: AppColors.tertiary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                                checkmarkColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.tertiary
                                      : Colors.white24,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      AppSpacing.verticalLg,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20.sp),
            AppSpacing.horizontalSm,
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        AppSpacing.verticalMd,
        child,
      ],
    );
  }

  Widget _buildSortOption(String title, SortField field, SortOrder order) {
    final isSelected = _sortField == field && _sortOrder == order;
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.white)
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
    widget.onDataChanged?.call();
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
    return AppBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpacing.verticalLg,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Collection',
                            style: AppTextStyles.displaySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.verticalXs,
                          Text(
                            '${_filteredCars.length} car${_filteredCars.length == 1 ? '' : 's'}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      // Sort and Filter buttons
                      Row(
                        children: [
                          GestureDetector(
                            onTap: showSortOptions,
                            child: SoftCard(
                              padding: EdgeInsets.all(12.w),
                              color: AppColors.primary,
                              elevation: 4,
                              child: Icon(
                                Icons.sort_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 22.sp,
                              ),
                            ),
                          ),
                          AppSpacing.horizontalSm,
                          GestureDetector(
                            onTap: showFilterOptions,
                            child: SoftCard(
                              padding: EdgeInsets.all(12.w),
                              color: _activeFilterCount > 0
                                  ? AppColors.tertiary
                                  : AppColors.primary,
                              elevation: 4,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 22.sp,
                                  ),
                                  if (_activeFilterCount > 0)
                                    Positioned(
                                      top: -8.h,
                                      right: -8.w,
                                      child: Container(
                                        padding: EdgeInsets.all(4.w),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$_activeFilterCount',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.verticalMd,
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
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
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
                          _applyFilters();
                        },
                      ),
                  ],
                ),
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
                                  widget.onDataChanged?.call();
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
    );
  }

}
