import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/assets/assets.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/services.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../providers/profile_providers.dart';

class ProfileContent extends ConsumerStatefulWidget {
  const ProfileContent({super.key});

  @override
  ConsumerState<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<ProfileContent> {
  final BackupService _backupService = sl<BackupService>();
  bool _isExporting = false;
  bool _isImporting = false;

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName == 'Collector' ? '' : currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        title: Text(
          'Set Your Name',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(profileProvider.notifier).setCollectorName(name);
              } else {
                ref.read(profileProvider.notifier).setCollectorName('Collector');
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCollection() async {
    setState(() => _isExporting = true);
    try {
      final result = await _backupService.exportCollection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importCollection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    if (!mounted) return;
    final replaceExisting = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        title: Text(
          'Import Collection',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        content: Text(
          'How would you like to import the backup?',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Merge'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Replace All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (replaceExisting == null) return;

    setState(() => _isImporting = true);
    try {
      final importResult = await _backupService.importCollection(
        filePath,
        replaceExisting: replaceExisting,
      );

      if (mounted) {
        String message = importResult.message;
        if (importResult.success) {
          message =
              'Imported ${importResult.carsImported} cars and ${importResult.imagesImported} images';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                importResult.success ? Colors.green : AppColors.error,
          ),
        );
        // Refresh profile stats
        ref.invalidate(profileProvider);
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        title: Text(
          'Delete All Data',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete all cars from your collection? This action cannot be undone.',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllData(context, ref);
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    await ref.read(profileProvider.notifier).deleteAllData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data deleted'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    return AppBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.verticalLg,
              // Header Section
              _buildHeader(state),
              AppSpacing.verticalXl,
              // Stats Cards
              _buildStatsSection(state),
              AppSpacing.verticalLg,
              // Backup Section
              _buildSectionHeader(
                icon: Icons.backup_rounded,
                title: 'Backup',
              ),
              AppSpacing.verticalMd,
              _buildBackupSection(),
              AppSpacing.verticalLg,
              // About Section
              _buildSectionHeader(
                icon: Icons.info_outline_rounded,
                title: 'About',
              ),
              AppSpacing.verticalMd,
              _buildAboutCard(),
              AppSpacing.verticalLg,
              // Danger Zone
              _buildSectionHeader(
                icon: Icons.warning_amber_rounded,
                title: 'Danger Zone',
                color: AppColors.error,
              ),
              AppSpacing.verticalMd,
              _buildDangerZone(),
              AppSpacing.verticalXl,
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ProfileState state) {
    return GestureDetector(
      onTap: () => _showEditNameDialog(context, state.collectorName),
      child: SoftCard(
        padding: EdgeInsets.all(24.w),
        color: AppColors.primary,
        elevation: 10,
        shadowColor: AppColors.primary.withValues(alpha: 0.6),
        child: Row(
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.tertiary,
                    AppColors.primary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tertiary.withValues(alpha: 0.4),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 36.sp,
              ),
            ),
            AppSpacing.horizontalLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          state.collectorName,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppSpacing.horizontalSm,
                      Icon(
                        Icons.edit_rounded,
                        color: Colors.white38,
                        size: 16.sp,
                      ),
                    ],
                  ),
                  AppSpacing.verticalXs,
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      state.isLoading
                          ? '-- cars'
                          : '${state.totalCars} cars collected',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(ProfileState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.directions_car_rounded,
                label: 'Total Cars',
                value: state.isLoading ? '--' : '${state.totalCars}',
                color: AppColors.tertiary,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: _buildStatCard(
                icon: Icons.layers_rounded,
                label: 'Series',
                value: state.isLoading ? '--' : '${state.totalSeries}',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        AppSpacing.verticalMd,
        SizedBox(
          width: double.infinity,
          child: _buildStatCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Total Spent',
            value: state.isLoading ? '--' : '₱${state.totalSpent.toStringAsFixed(2)}',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return SoftCard(
      padding: EdgeInsets.all(20.w),
      color: AppColors.primary,
      elevation: 6,
      shadowColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28.sp,
            ),
          ),
          AppSpacing.verticalMd,
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.verticalXs,
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    return SoftCard(
      padding: EdgeInsets.zero,
      color: AppColors.primary,
      elevation: 6,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      child: Column(
        children: [
          _buildBackupItem(
            icon: _isExporting
                ? Icons.hourglass_empty_rounded
                : Icons.upload_rounded,
            title: 'Export Collection',
            subtitle: 'Save your collection as a backup file',
            onTap: _isExporting || _isImporting ? null : _exportCollection,
          ),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
            indent: 20.w,
            endIndent: 20.w,
          ),
          _buildBackupItem(
            icon: _isImporting
                ? Icons.hourglass_empty_rounded
                : Icons.download_rounded,
            title: 'Import Collection',
            subtitle: 'Restore from a backup file',
            onTap: _isExporting || _isImporting ? null : _importCollection,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? AppColors.tertiary : Colors.white38,
                  size: 24.sp,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isEnabled ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnabled)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Color? color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: color ?? Colors.white70,
            size: 18.sp,
          ),
        ),
        AppSpacing.horizontalMd,
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard() {
    return SoftCard(
      padding: EdgeInsets.all(20.w),
      color: AppColors.primary,
      elevation: 6,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Image.asset(
                  AppLogos.hotwheels,
                  width: 50.w,
                  height: 25.h,
                  fit: BoxFit.contain,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hot Vault',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'v1.0.0',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.verticalMd,
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              'Track and manage your Hot Wheels collection with ease. Add cars, organize by series, and keep your collection at your fingertips.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return SoftCard(
      padding: EdgeInsets.zero,
      color: AppColors.primary,
      elevation: 6,
      shadowColor: AppColors.error.withValues(alpha: 0.2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDeleteConfirmation(context, ref),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1.w,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.error,
                    size: 24.sp,
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete All Data',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        'Permanently remove all cars from your collection',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
