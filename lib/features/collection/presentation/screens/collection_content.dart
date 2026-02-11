import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/database/database.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../providers/collection_providers.dart';

class CollectionContent extends ConsumerStatefulWidget {
  final VoidCallback? onDataChanged;

  const CollectionContent({
    super.key,
    this.onDataChanged,
  });

  @override
  ConsumerState<CollectionContent> createState() => _CollectionContentState();
}

class _CollectionContentState extends ConsumerState<CollectionContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortOptions() {
    final state = ref.read(collectionProvider);
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
            _buildSortOption('Recently Added', SortField.createdAt, SortOrder.descending, state),
            _buildSortOption('Oldest First', SortField.createdAt, SortOrder.ascending, state),
            _buildSortOption('Name (A-Z)', SortField.name, SortOrder.ascending, state),
            _buildSortOption('Name (Z-A)', SortField.name, SortOrder.descending, state),
            _buildSortOption('Year (Newest)', SortField.year, SortOrder.descending, state),
            _buildSortOption('Year (Oldest)', SortField.year, SortOrder.ascending, state),
            AppSpacing.verticalMd,
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, SortField field, SortOrder order, CollectionState state) {
    final isSelected = state.sortField == field && state.sortOrder == order;
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      onTap: () {
        ref.read(collectionProvider.notifier).setSortOptions(field, order);
        Navigator.pop(context);
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tertiary,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(collectionProvider);
          return DraggableScrollableSheet(
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
                          ref.read(collectionProvider.notifier).clearAllFilters();
                        },
                        child: Text(
                          'Clear All',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalMd,
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        if (state.availableSeries.isNotEmpty) ...[
                          _buildFilterSection(
                            title: 'Series',
                            icon: Icons.layers_rounded,
                            child: Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: state.availableSeries.map((series) {
                                final isSelected = state.selectedSeries == series;
                                return FilterChip(
                                  label: Text(series),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    ref.read(collectionProvider.notifier)
                                        .setSeriesFilter(selected ? series : null);
                                  },
                                  backgroundColor: AppColors.primary,
                                  selectedColor: AppColors.tertiary,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                  checkmarkColor: Colors.white,
                                  side: BorderSide(
                                    color: isSelected ? AppColors.tertiary : Colors.white24,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          AppSpacing.verticalLg,
                        ],
                        if (state.availableConditions.isNotEmpty) ...[
                          _buildFilterSection(
                            title: 'Condition',
                            icon: Icons.stars_rounded,
                            child: Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: state.availableConditions.map((condition) {
                                final isSelected = state.selectedCondition == condition;
                                return FilterChip(
                                  label: Text(condition),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    ref.read(collectionProvider.notifier)
                                        .setConditionFilter(selected ? condition : null);
                                  },
                                  backgroundColor: AppColors.primary,
                                  selectedColor: AppColors.tertiary,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                  checkmarkColor: Colors.white,
                                  side: BorderSide(
                                    color: isSelected ? AppColors.tertiary : Colors.white24,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          AppSpacing.verticalLg,
                        ],
                        if (state.availableYears.isNotEmpty) ...[
                          _buildFilterSection(
                            title: 'Year',
                            icon: Icons.calendar_today_rounded,
                            child: Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: state.availableYears.map((year) {
                                final isSelected = state.selectedYear == year;
                                return FilterChip(
                                  label: Text(year.toString()),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    ref.read(collectionProvider.notifier)
                                        .setYearFilter(selected ? year : null);
                                  },
                                  backgroundColor: AppColors.primary,
                                  selectedColor: AppColors.tertiary,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                  checkmarkColor: Colors.white,
                                  side: BorderSide(
                                    color: isSelected ? AppColors.tertiary : Colors.white24,
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
          );
        },
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
      await ref.read(collectionProvider.notifier).deleteCar(car);
      widget.onDataChanged?.call();
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
    final state = ref.watch(collectionProvider);

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
                            '${state.filteredCars.length} car${state.filteredCars.length == 1 ? '' : 's'}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showSortOptions,
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
                            onTap: _showFilterOptions,
                            child: SoftCard(
                              padding: EdgeInsets.all(12.w),
                              color: state.activeFilterCount > 0
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
                                  if (state.activeFilterCount > 0)
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
                                          '${state.activeFilterCount}',
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
                        onChanged: (query) {
                          ref.read(collectionProvider.notifier).setSearchQuery(query);
                        },
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
                          ref.read(collectionProvider.notifier).setSearchQuery('');
                        },
                      ),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalMd,
            // Grid
            Expanded(
              child: state.filteredCars.isEmpty && !state.isLoading
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
                            state.searchQuery.isNotEmpty
                                ? 'No cars found'
                                : 'No cars in collection',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                          if (state.searchQuery.isEmpty) ...[
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
                  : PaginatedCarGrid(
                      cars: state.filteredCars,
                      isLoading: state.isLoading,
                      isLoadingMore: state.isLoadingMore,
                      hasReachedEnd: state.hasReachedEnd,
                      onLoadMore: () {
                        ref.read(collectionProvider.notifier).loadMoreCars();
                      },
                      onRefresh: () async {
                        await ref.read(collectionProvider.notifier).refresh();
                      },
                      onCarTap: (car) async {
                        final result = await context
                            .push('${Routes.carDetail}/${car.id}');
                        if (result == true) {
                          ref.read(collectionProvider.notifier).refresh();
                          widget.onDataChanged?.call();
                        }
                      },
                      onFavoriteToggle: (car) async {
                        await ref.read(collectionProvider.notifier)
                            .toggleFavorite(car.id, !car.isFavorite);
                        widget.onDataChanged?.call();
                      },
                      onDelete: _deleteCar,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
