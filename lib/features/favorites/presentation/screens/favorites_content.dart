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
import '../../providers/favorites_providers.dart';

class FavoritesContent extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToCollection;
  final VoidCallback? onDataChanged;

  const FavoritesContent({
    super.key,
    this.onNavigateToCollection,
    this.onDataChanged,
  });

  @override
  ConsumerState<FavoritesContent> createState() => _FavoritesContentState();
}

class _FavoritesContentState extends ConsumerState<FavoritesContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortOptions() {
    final state = ref.read(favoritesProvider);
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

  Widget _buildSortOption(String title, SortField field, SortOrder order, FavoritesState state) {
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
        ref.read(favoritesProvider.notifier).setSortOptions(field, order);
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
          final state = ref.watch(favoritesProvider);
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
                          ref.read(favoritesProvider.notifier).clearAllFilters();
                          _searchController.clear();
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
                                    ref.read(favoritesProvider.notifier)
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
                        if (state.availableSegments.isNotEmpty) ...[
                          _buildFilterSection(
                            title: 'Segment',
                            icon: Icons.category_rounded,
                            child: Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: state.availableSegments.map((segment) {
                                final isSelected = state.selectedSegment == segment;
                                return FilterChip(
                                  label: Text(segment),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    ref.read(favoritesProvider.notifier)
                                        .setSegmentFilter(selected ? segment : null);
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
                                    ref.read(favoritesProvider.notifier)
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
                                    ref.read(favoritesProvider.notifier)
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
                          AppSpacing.verticalLg,
                        ],
                        if (state.availableHuntTypes.isNotEmpty) ...[
                          _buildFilterSection(
                            title: 'Type',
                            icon: Icons.local_fire_department_rounded,
                            child: Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: state.availableHuntTypes.map((huntType) {
                                final isSelected = state.selectedHuntType == huntType;
                                return FilterChip(
                                  label: Text(_getHuntTypeLabel(huntType)),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    ref.read(favoritesProvider.notifier)
                                        .setHuntTypeFilter(selected ? huntType : null);
                                  },
                                  backgroundColor: AppColors.primary,
                                  selectedColor: huntType == HuntType.sth
                                      ? const Color(0xFFFFD700)
                                      : huntType == HuntType.rth
                                          ? AppColors.success
                                          : AppColors.tertiary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? (huntType == HuntType.sth ? Colors.black87 : Colors.white)
                                        : Colors.white70,
                                  ),
                                  checkmarkColor: huntType == HuntType.sth ? Colors.black87 : Colors.white,
                                  side: BorderSide(
                                    color: isSelected
                                        ? (huntType == HuntType.sth
                                            ? const Color(0xFFFFD700)
                                            : huntType == HuntType.rth
                                                ? AppColors.success
                                                : AppColors.tertiary)
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
          );
        },
      ),
    );
  }

  String _getHuntTypeLabel(HuntType type) {
    switch (type) {
      case HuntType.normal:
        return 'Normal';
      case HuntType.rth:
        return 'RTH';
      case HuntType.sth:
        return 'STH';
    }
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesProvider);

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
                            '${state.filteredCars.length} favorite${state.filteredCars.length == 1 ? '' : 's'}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      if (state.favoriteCars.isNotEmpty)
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
            if (state.favoriteCars.isNotEmpty) ...[
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
                          onChanged: (query) {
                            ref.read(favoritesProvider.notifier).setSearchQuery(query);
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
                            ref.read(favoritesProvider.notifier).setSearchQuery('');
                          },
                        ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalMd,
            ],
            Expanded(
              child: state.favoriteCars.isEmpty && !state.isLoading
                  ? _buildEmptyState()
                  : state.filteredCars.isEmpty && !state.isLoading
                      ? _buildNoResultsState()
                      : PaginatedCarGrid(
                          cars: state.filteredCars,
                          isLoading: state.isLoading,
                          isLoadingMore: state.isLoadingMore,
                          hasReachedEnd: state.hasReachedEnd,
                          showDeleteButton: false,
                          duplicateCounts: state.duplicateCounts,
                          onLoadMore: () {
                            ref.read(favoritesProvider.notifier).loadMoreFavorites();
                          },
                          onRefresh: () async {
                            await ref.read(favoritesProvider.notifier).refresh();
                          },
                          onCarTap: (car) async {
                            final result = await context
                                .push('${Routes.carDetail}/${car.id}');
                            if (result == true) {
                              ref.read(favoritesProvider.notifier).refresh();
                              widget.onDataChanged?.call();
                            }
                          },
                          onFavoriteToggle: (car) async {
                            await ref.read(favoritesProvider.notifier)
                                .toggleFavorite(car.id, !car.isFavorite);
                            widget.onDataChanged?.call();
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
            onPressed: () {
              ref.read(favoritesProvider.notifier).clearAllFilters();
              _searchController.clear();
            },
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
