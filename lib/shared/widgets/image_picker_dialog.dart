import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../styles/app_spacing.dart';

class ImagePickerDialog extends StatelessWidget {
  final String title;
  final bool hasExistingImage;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  const ImagePickerDialog({
    super.key,
    this.title = 'Add Photo',
    this.hasExistingImage = false,
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
  });

  static Future<ImageSource?> show(
    BuildContext context, {
    String title = 'Add Photo',
    bool hasExistingImage = false,
  }) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.tertiary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => _ImagePickerContent(
        title: title,
        hasExistingImage: hasExistingImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          AppSpacing.verticalLg,
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
            title: Text(
              'Take Photo',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
            ),
            onTap: onCamera,
          ),
          ListTile(
            leading:
                const Icon(Icons.photo_library_rounded, color: Colors.white),
            title: Text(
              'Choose from Gallery',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
            ),
            onTap: onGallery,
          ),
          if (hasExistingImage && onRemove != null)
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: Text(
                'Remove Photo',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
              ),
              onTap: onRemove,
            ),
          AppSpacing.verticalMd,
        ],
      ),
    );
  }
}

class _ImagePickerContent extends StatelessWidget {
  final String title;
  final bool hasExistingImage;

  const _ImagePickerContent({
    required this.title,
    required this.hasExistingImage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          AppSpacing.verticalLg,
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
            title: Text(
              'Take Photo',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
            ),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading:
                const Icon(Icons.photo_library_rounded, color: Colors.white),
            title: Text(
              'Choose from Gallery',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
            ),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          if (hasExistingImage)
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: Text(
                'Remove Photo',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(context, null),
            ),
          AppSpacing.verticalMd,
        ],
      ),
    );
  }
}
