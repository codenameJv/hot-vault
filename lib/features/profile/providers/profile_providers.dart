import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/services.dart';

const _collectorNameKey = 'collector_name';

/// State class for Profile screen
class ProfileState {
  final int totalCars;
  final int totalSeries;
  final double totalSpent;
  final String collectorName;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.totalCars = 0,
    this.totalSeries = 0,
    this.totalSpent = 0.0,
    this.collectorName = 'Collector',
    this.isLoading = true,
    this.error,
  });

  ProfileState copyWith({
    int? totalCars,
    int? totalSeries,
    double? totalSpent,
    String? collectorName,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      totalCars: totalCars ?? this.totalCars,
      totalSeries: totalSeries ?? this.totalSeries,
      totalSpent: totalSpent ?? this.totalSpent,
      collectorName: collectorName ?? this.collectorName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for Profile screen state
class ProfileNotifier extends StateNotifier<ProfileState> {
  final CarRepository _carRepository;
  final ImageService _imageService;

  ProfileNotifier(this._carRepository, this._imageService)
      : super(const ProfileState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadCollectorName();
    await loadStats();
  }

  Future<void> _loadCollectorName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_collectorNameKey) ?? 'Collector';
    state = state.copyWith(collectorName: name);
  }

  Future<void> setCollectorName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collectorNameKey, name);
    state = state.copyWith(collectorName: name);
  }

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final totalCars = await _carRepository.getTotalCount();
      final allSeries = await _carRepository.getAllSeries();
      final totalSpent = await _carRepository.getTotalSpent();

      state = state.copyWith(
        totalCars: totalCars,
        totalSeries: allSeries.length,
        totalSpent: totalSpent,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteAllData() async {
    // Clean up all images (passing empty list means all images are orphaned)
    await _imageService.cleanupOrphanedImages([]);
    await _carRepository.deleteAllCars();
    await loadStats();
  }

  Future<void> refresh() async {
    await loadStats();
  }
}

/// Provider for Profile screen state
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final carRepository = ref.watch(carRepositoryProvider);
  final imageService = ref.watch(imageServiceProvider);
  return ProfileNotifier(carRepository, imageService);
});
