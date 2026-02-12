import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

/// State class for Favorites screen
class FavoritesState {
  final List<HotWheelsCar> favoriteCars;
  final List<HotWheelsCar> filteredCars;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final int currentPage;
  final int pageSize;
  final SortField sortField;
  final SortOrder sortOrder;
  final String searchQuery;
  final String? selectedSeries;
  final String? selectedSegment;
  final String? selectedCondition;
  final int? selectedYear;
  final HuntType? selectedHuntType;
  final List<String> availableSeries;
  final List<String> availableSegments;
  final List<String> availableConditions;
  final List<int> availableYears;
  final List<HuntType> availableHuntTypes;
  final String? error;

  const FavoritesState({
    this.favoriteCars = const [],
    this.filteredCars = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.currentPage = 0,
    this.pageSize = 20,
    this.sortField = SortField.createdAt,
    this.sortOrder = SortOrder.descending,
    this.searchQuery = '',
    this.selectedSeries,
    this.selectedSegment,
    this.selectedCondition,
    this.selectedYear,
    this.selectedHuntType,
    this.availableSeries = const [],
    this.availableSegments = const [],
    this.availableConditions = const [],
    this.availableYears = const [],
    this.availableHuntTypes = const [],
    this.error,
  });

  int get activeFilterCount {
    int count = 0;
    if (selectedSeries != null) count++;
    if (selectedSegment != null) count++;
    if (selectedCondition != null) count++;
    if (selectedYear != null) count++;
    if (selectedHuntType != null) count++;
    return count;
  }

  FavoritesState copyWith({
    List<HotWheelsCar>? favoriteCars,
    List<HotWheelsCar>? filteredCars,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    int? currentPage,
    int? pageSize,
    SortField? sortField,
    SortOrder? sortOrder,
    String? searchQuery,
    String? selectedSeries,
    String? selectedSegment,
    String? selectedCondition,
    int? selectedYear,
    HuntType? selectedHuntType,
    List<String>? availableSeries,
    List<String>? availableSegments,
    List<String>? availableConditions,
    List<int>? availableYears,
    List<HuntType>? availableHuntTypes,
    String? error,
    bool clearSeriesFilter = false,
    bool clearSegmentFilter = false,
    bool clearConditionFilter = false,
    bool clearYearFilter = false,
    bool clearHuntTypeFilter = false,
  }) {
    return FavoritesState(
      favoriteCars: favoriteCars ?? this.favoriteCars,
      filteredCars: filteredCars ?? this.filteredCars,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSeries: clearSeriesFilter ? null : (selectedSeries ?? this.selectedSeries),
      selectedSegment: clearSegmentFilter ? null : (selectedSegment ?? this.selectedSegment),
      selectedCondition: clearConditionFilter ? null : (selectedCondition ?? this.selectedCondition),
      selectedYear: clearYearFilter ? null : (selectedYear ?? this.selectedYear),
      selectedHuntType: clearHuntTypeFilter ? null : (selectedHuntType ?? this.selectedHuntType),
      availableSeries: availableSeries ?? this.availableSeries,
      availableSegments: availableSegments ?? this.availableSegments,
      availableConditions: availableConditions ?? this.availableConditions,
      availableYears: availableYears ?? this.availableYears,
      availableHuntTypes: availableHuntTypes ?? this.availableHuntTypes,
      error: error,
    );
  }
}

/// Notifier for Favorites screen state
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final CarRepository _carRepository;

  FavoritesNotifier(this._carRepository) : super(const FavoritesState()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 0,
      hasReachedEnd: false,
    );

    try {
      final cars = await _carRepository.getFavoriteCarsPaginated(
        limit: state.pageSize,
        offset: 0,
        sortBy: state.sortField,
        order: state.sortOrder,
      );

      // Load all favorites for filter options
      final allCars = await _carRepository.getFavoriteCars(
        sortBy: state.sortField,
        order: state.sortOrder,
      );

      // Extract available filter options from all favorites
      final seriesSet = <String>{};
      final segmentSet = <String>{};
      final conditionSet = <String>{};
      final yearSet = <int>{};
      final huntTypeSet = <HuntType>{};

      for (final car in allCars) {
        if (car.series != null && car.series!.isNotEmpty) {
          seriesSet.add(car.series!);
        }
        if (car.segment != null && car.segment!.isNotEmpty) {
          segmentSet.add(car.segment!);
        }
        if (car.condition != null && car.condition!.isNotEmpty) {
          conditionSet.add(car.condition!);
        }
        if (car.year != null) {
          yearSet.add(car.year!);
        }
        huntTypeSet.add(car.huntType);
      }

      state = state.copyWith(
        favoriteCars: cars,
        availableSeries: seriesSet.toList()..sort(),
        availableSegments: segmentSet.toList()..sort(),
        availableConditions: conditionSet.toList()..sort(),
        availableYears: yearSet.toList()..sort((a, b) => b.compareTo(a)),
        availableHuntTypes: huntTypeSet.toList()..sort((a, b) => a.index.compareTo(b.index)),
        isLoading: false,
        hasReachedEnd: cars.length < state.pageSize,
      );

      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreFavorites() async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final newCars = await _carRepository.getFavoriteCarsPaginated(
        limit: state.pageSize,
        offset: nextPage * state.pageSize,
        sortBy: state.sortField,
        order: state.sortOrder,
      );

      state = state.copyWith(
        favoriteCars: [...state.favoriteCars, ...newCars],
        currentPage: nextPage,
        isLoadingMore: false,
        hasReachedEnd: newCars.length < state.pageSize,
      );

      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void _applyFilters() {
    final query = state.searchQuery.toLowerCase();

    var filtered = state.favoriteCars.where((car) {
      // Text search filter
      if (query.isNotEmpty) {
        final nameLower = car.name.toLowerCase();
        final seriesLower = car.series?.toLowerCase() ?? '';
        final segmentLower = car.segment?.toLowerCase() ?? '';
        if (!nameLower.contains(query) && !seriesLower.contains(query) && !segmentLower.contains(query)) {
          return false;
        }
      }

      // Series filter
      if (state.selectedSeries != null && car.series != state.selectedSeries) {
        return false;
      }

      // Segment filter
      if (state.selectedSegment != null && car.segment != state.selectedSegment) {
        return false;
      }

      // Condition filter
      if (state.selectedCondition != null && car.condition != state.selectedCondition) {
        return false;
      }

      // Year filter
      if (state.selectedYear != null && car.year != state.selectedYear) {
        return false;
      }

      // Hunt type filter
      if (state.selectedHuntType != null && car.huntType != state.selectedHuntType) {
        return false;
      }

      return true;
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      switch (state.sortField) {
        case SortField.name:
          comparison = a.name.compareTo(b.name);
        case SortField.year:
          final aYear = a.year ?? 0;
          final bYear = b.year ?? 0;
          comparison = aYear.compareTo(bYear);
        case SortField.createdAt:
        case SortField.acquiredDate:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return state.sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    state = state.copyWith(filteredCars: filtered);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void setSortOptions(SortField field, SortOrder order) {
    state = state.copyWith(sortField: field, sortOrder: order);
    _applyFilters();
  }

  void setSeriesFilter(String? series) {
    if (series == null) {
      state = state.copyWith(clearSeriesFilter: true);
    } else {
      state = state.copyWith(selectedSeries: series);
    }
    _applyFilters();
  }

  void setSegmentFilter(String? segment) {
    if (segment == null) {
      state = state.copyWith(clearSegmentFilter: true);
    } else {
      state = state.copyWith(selectedSegment: segment);
    }
    _applyFilters();
  }

  void setConditionFilter(String? condition) {
    if (condition == null) {
      state = state.copyWith(clearConditionFilter: true);
    } else {
      state = state.copyWith(selectedCondition: condition);
    }
    _applyFilters();
  }

  void setYearFilter(int? year) {
    if (year == null) {
      state = state.copyWith(clearYearFilter: true);
    } else {
      state = state.copyWith(selectedYear: year);
    }
    _applyFilters();
  }

  void setHuntTypeFilter(HuntType? huntType) {
    if (huntType == null) {
      state = state.copyWith(clearHuntTypeFilter: true);
    } else {
      state = state.copyWith(selectedHuntType: huntType);
    }
    _applyFilters();
  }

  void clearAllFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearSeriesFilter: true,
      clearSegmentFilter: true,
      clearConditionFilter: true,
      clearYearFilter: true,
      clearHuntTypeFilter: true,
    );
    _applyFilters();
  }

  Future<void> toggleFavorite(String carId, bool isFavorite) async {
    await _carRepository.toggleFavorite(carId, isFavorite);
    await loadFavorites();
  }

  Future<void> refresh() async {
    await loadFavorites();
  }
}

/// Provider for Favorites screen state
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  final carRepository = ref.watch(carRepositoryProvider);
  return FavoritesNotifier(carRepository);
});
