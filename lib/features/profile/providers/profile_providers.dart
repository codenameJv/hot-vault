import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/services.dart';

/// State class for Profile screen
class ProfileState {
  final int totalCars;
  final int totalSeries;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.totalCars = 0,
    this.totalSeries = 0,
    this.isLoading = true,
    this.error,
  });

  ProfileState copyWith({
    int? totalCars,
    int? totalSeries,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      totalCars: totalCars ?? this.totalCars,
      totalSeries: totalSeries ?? this.totalSeries,
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
    loadStats();
  }

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final totalCars = await _carRepository.getTotalCount();
      final allSeries = await _carRepository.getAllSeries();

      state = state.copyWith(
        totalCars: totalCars,
        totalSeries: allSeries.length,
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
