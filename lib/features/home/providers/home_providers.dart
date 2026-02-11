import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

/// State class for Home screen
class HomeState {
  final int totalCount;
  final int totalSeries;
  final int favoritesCount;
  final List<HotWheelsCar> recentActivity;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.totalCount = 0,
    this.totalSeries = 0,
    this.favoritesCount = 0,
    this.recentActivity = const [],
    this.isLoading = true,
    this.error,
  });

  HomeState copyWith({
    int? totalCount,
    int? totalSeries,
    int? favoritesCount,
    List<HotWheelsCar>? recentActivity,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      totalCount: totalCount ?? this.totalCount,
      totalSeries: totalSeries ?? this.totalSeries,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      recentActivity: recentActivity ?? this.recentActivity,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for Home screen state
class HomeNotifier extends StateNotifier<HomeState> {
  final CarRepository _carRepository;

  HomeNotifier(this._carRepository) : super(const HomeState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final count = await _carRepository.getTotalCount();
      final recentCars = await _carRepository.getRecentCars(limit: 5);
      final allSeries = await _carRepository.getAllSeries();
      final favoritesCount = await _carRepository.getFavoritesCount();

      state = state.copyWith(
        totalCount: count,
        totalSeries: allSeries.length,
        favoritesCount: favoritesCount,
        recentActivity: recentCars,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadData();
  }
}

/// Provider for Home screen state
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final carRepository = ref.watch(carRepositoryProvider);
  return HomeNotifier(carRepository);
});
