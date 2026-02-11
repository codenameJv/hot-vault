import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class FavoritesContent extends StatefulWidget {
  final VoidCallback? onNavigateToCollection;
  final VoidCallback? onDataChanged;

  const FavoritesContent({
    super.key,
    this.onNavigateToCollection,
    this.onDataChanged,
  });

  @override
  State<FavoritesContent> createState() => FavoritesContentState();
}

class FavoritesContentState extends State<FavoritesContent> {
  final CarRepository _carRepository = sl<CarRepository>();
  final TextEditingController _searchController = TextEditingController();

  List<HotWheelsCar> _favoriteCars = [];
  List<HotWheelsCar> _filteredCars = [];
  bool _isLoading = true;

  // Filter options
  String? _selectedSeries;
  String? _selectedCondition;
  int? _selectedYear;
  List<String> _availableSeries = [];
  List<String> _availableConditions = [];
  List<int> _availableYears = [];
  int _activeFilterCount = 0;

  // Sort options
  SortField _sortField = SortField.createdAt;
  SortOrder _sortOrder = SortOrder.descending;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final cars = await _carRepository.getFavoriteCars();

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
        _favoriteCars = cars;
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
    _loadFavorites();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredCars = _favoriteCars.where((car) {
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

      // Apply sorting
      _filteredCars.sort((a, b) {
        int comparison;
        switch (_sortField) {
          case SortField.name:
            comparison = a.name.compareTo(b.name);
            break;
          case SortField.year:
            final aYear = a.year ?? 0;
            final bYear = b.year ?? 0;
            comparison = aYear.compareTo(bYear);
            break;
          case SortField.createdAt:
          default:
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
        }
        return _sortOrder == SortOrder.ascending ? comparison : -comparison;
      });

      // Count active filters
      _activeFilterCount = 0;
      if (_selectedSeries != null) _activeFilterCount++;
      if (_selectedCondition != null) _activeFilterCount++;
      if (_selectedYear != null) _activeFilterCount++;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedSeries = null;
      _selectedCondition = null;
      _selectedYear = null;
      _searchController.clear();
    });
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
        _applyFilters();
      },
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

  Future<void> _toggleFavorite(HotWheelsCar car) async {
    await _carRepository.toggleFavorite(car.id, !car.isFavorite);
    _loadFavorites();
    widget.onDataChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Favorites',
                            style: AppTextStyles.displaySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.verticalXs,
                          Text(
                            '${_filteredCars.length} favorite${_filteredCars.length == 1 ? '' : 's'}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      // Sort and Filter buttons
                      if (_favoriteCars.isNotEmpty)
                        Row(
                          children: [
                            // Sort button
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
                            // Filter button
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
            // Search Bar (only show if there are favorites)
            if (_favoriteCars.isNotEmpty) ...[
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
                            hintText: 'Search favorites...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => _applyFilters(),
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
            ],
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _favoriteCars.isEmpty
                      ? _buildEmptyState()
                      : _filteredCars.isEmpty
                          ? _buildNoResultsState()
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
                                  showDeleteButton: false,
                                  onTap: () async {
                                    final result = await context
                                        .push('${Routes.carDetail}/${car.id}');
                                    if (result == true) {
                                      _loadFavorites();
                                      widget.onDataChanged?.call();
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
                onPressed: widget.onNavigateToCollection,
                text: 'Browse Collection',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64.sp,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          AppSpacing.verticalMd,
          Text(
            'No favorites found',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white54,
            ),
          ),
          AppSpacing.verticalSm,
          Text(
            'Try adjusting your filters',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white38,
            ),
          ),
          AppSpacing.verticalLg,
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Clear Filters',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
