import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/database/database.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class CarDetailScreen extends StatefulWidget {
  final String carId;

  const CarDetailScreen({super.key, required this.carId});

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  final CarRepository _carRepository = CarRepository();
  HotWheelsCar? _car;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCar();
  }

  Future<void> _loadCar() async {
    setState(() => _isLoading = true);
    try {
      final car = await _carRepository.getCarById(widget.carId);
      setState(() {
        _car = car;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load car: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteCar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        title: Text(
          'Delete Car',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${_car?.name}"?',
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

    if (confirmed == true && _car != null) {
      await _carRepository.deleteCar(_car!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_car!.name} deleted'),
            backgroundColor: AppColors.error,
          ),
        );
        context.pop(true);
      }
    }
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _toggleFavorite() async {
    if (_car == null) return;
    await _carRepository.toggleFavorite(_car!.id, !_car!.isFavorite);
    _loadCar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_car != null) ...[
            IconButton(
              icon: Icon(
                _car!.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _car!.isFavorite ? AppColors.error : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () async {
                final result = await context.push(
                  '${Routes.editCar}/${_car!.id}',
                );
                if (result == true) {
                  _loadCar();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: _deleteCar,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _car == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          AppSpacing.verticalMd,
                          Text(
                            'Car not found',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Car Image
                          SoftCard(
                            padding: AppSpacing.paddingLg,
                            color: AppColors.primary,
                            elevation: 8,
                            shadowColor: AppColors.primary.withValues(alpha: 0.5),
                            child: _car!.imagePath != null
                                ? ClipRRect(
                                    borderRadius: AppSpacing.borderRadiusMd,
                                    child: Image.file(
                                      File(_car!.imagePath!),
                                      height: 250,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildImagePlaceholder(),
                                    ),
                                  )
                                : _buildImagePlaceholder(),
                          ),
                          AppSpacing.verticalLg,
                          // Car Name
                          Text(
                            _car!.name,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_car!.series != null || _car!.year != null) ...[
                            AppSpacing.verticalSm,
                            Text(
                              [
                                if (_car!.series != null) _car!.series,
                                if (_car!.year != null) _car!.year.toString(),
                              ].join(' - '),
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          AppSpacing.verticalLg,
                          // Condition Badge
                          if (_car!.condition != null)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _getConditionColor(_car!.condition!),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _car!.condition!,
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          AppSpacing.verticalLg,
                          // Details Card
                          SoftCard(
                            padding: AppSpacing.paddingLg,
                            color: AppColors.primary,
                            elevation: 6,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Details',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppSpacing.verticalMd,
                                if (_car!.acquiredDate != null)
                                  _buildDetailRow(
                                    Icons.calendar_today_rounded,
                                    'Acquired',
                                    _formatDate(_car!.acquiredDate!),
                                  ),
                                _buildDetailRow(
                                  Icons.access_time_rounded,
                                  'Added to Collection',
                                  _formatDate(_car!.createdAt),
                                ),
                                if (_car!.updatedAt != _car!.createdAt)
                                  _buildDetailRow(
                                    Icons.update_rounded,
                                    'Last Updated',
                                    _formatDate(_car!.updatedAt),
                                  ),
                              ],
                            ),
                          ),
                          if (_car!.notes != null && _car!.notes!.isNotEmpty) ...[
                            AppSpacing.verticalMd,
                            // Notes Card
                            SoftCard(
                              padding: AppSpacing.paddingLg,
                              color: AppColors.primary,
                              elevation: 6,
                              shadowColor: AppColors.primary.withValues(alpha: 0.4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notes',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  AppSpacing.verticalMd,
                                  Text(
                                    _car!.notes!,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          AppSpacing.verticalXl,
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          AppSpacing.verticalSm,
          Text(
            'No image',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.6),
            size: 20,
          ),
          AppSpacing.horizontalMd,
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white54,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
