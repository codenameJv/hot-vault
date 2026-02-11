import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/services.dart';
import '../../../../core/utils/utils.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class AddCarDialog extends StatefulWidget {
  final bool autoFavorite;

  const AddCarDialog({
    super.key,
    this.autoFavorite = false,
  });

  static Future<bool?> show(BuildContext context, {bool autoFavorite = false}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddCarDialog(autoFavorite: autoFavorite),
    );
  }

  @override
  State<AddCarDialog> createState() => _AddCarDialogState();
}

class _AddCarDialogState extends State<AddCarDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _seriesController = TextEditingController();
  final _yearController = TextEditingController();
  final _notesController = TextEditingController();
  final CarRepository _carRepository = sl<CarRepository>();
  final ImageService _imageService = sl<ImageService>();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCondition = 'Mint';
  DateTime? _acquiredDate;
  bool _isSaving = false;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _seriesController.dispose();
    _yearController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: AppConstants.imageMaxWidth,
        maxHeight: AppConstants.imageMaxHeight,
        imageQuality: AppConstants.imageQuality,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    final source = await ImagePickerDialog.show(
      context,
      title: 'Add Photo',
      hasExistingImage: _selectedImage != null,
    );

    if (source != null) {
      _pickImage(source);
    } else if (_selectedImage != null) {
      setState(() => _selectedImage = null);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _acquiredDate ?? DateTime.now(),
      firstDate: DateTime(AppConstants.hotWheelsFirstYear),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.tertiary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _acquiredDate = picked);
    }
  }

  Future<String?> _saveImageToAppDir(File imageFile) async {
    try {
      return await _imageService.saveImage(imageFile);
    } catch (e) {
      AppLogger.error('Error saving image', e);
      return null;
    }
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? savedImagePath;
      if (_selectedImage != null) {
        savedImagePath = await _saveImageToAppDir(_selectedImage!);
      }

      final car = HotWheelsCar(
        name: _nameController.text.trim(),
        series: _seriesController.text.trim().isNotEmpty
            ? _seriesController.text.trim()
            : null,
        year: _yearController.text.trim().isNotEmpty
            ? int.tryParse(_yearController.text.trim())
            : null,
        imagePath: savedImagePath,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        condition: _selectedCondition,
        acquiredDate: _acquiredDate,
        isFavorite: widget.autoFavorite,
      );

      await _carRepository.insertCar(car);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${car.name} added to collection!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error saving car', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save car: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight;
    final maxDialogHeight = availableHeight * 0.85;

    return Dialog(
      backgroundColor: AppColors.tertiary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      insetPadding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 24.h,
        bottom: keyboardHeight > 0 ? 8.h : 24.h,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxDialogHeight,
          maxWidth: 400.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 8.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Car',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(Icons.close_rounded, color: Colors.white54, size: 24.sp),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Picker
                      _buildImagePicker(),
                      AppSpacing.verticalMd,
                      // Name Field
                      _buildNameField(),
                      AppSpacing.verticalMd,
                      // Series and Year Row
                      _buildSeriesYearRow(),
                      AppSpacing.verticalMd,
                      // Condition Dropdown
                      _buildConditionDropdown(),
                      AppSpacing.verticalMd,
                      // Acquired Date
                      _buildAcquiredDate(),
                      AppSpacing.verticalMd,
                      // Notes
                      _buildNotesField(),
                      AppSpacing.verticalLg,
                      // Save Button
                      SoftButton.primary(
                        onPressed: _isSaving ? null : _saveCar,
                        text: 'Add to Collection',
                        isLoading: _isSaving,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.file(
                  _selectedImage!,
                  height: 120.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 100.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 32.sp,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'Tap to add photo',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            if (_selectedImage != null) ...[
              AppSpacing.verticalXs,
              Text(
                'Tap to change photo',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Car Name *',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          AppSpacing.verticalXs,
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            decoration: _inputDecoration('Enter car name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a car name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesYearRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Series',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                AppSpacing.verticalXs,
                TextFormField(
                  controller: _seriesController,
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  decoration: _inputDecoration('e.g. Mainline'),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.horizontalSm,
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Year',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                AppSpacing.verticalXs,
                TextFormField(
                  controller: _yearController,
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  decoration: _inputDecoration('e.g. 2024'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Condition',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          AppSpacing.verticalXs,
          DropdownButtonFormField<String>(
            initialValue: _selectedCondition,
            dropdownColor: AppColors.tertiary,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            decoration: _inputDecoration(null),
            items: ConditionHelper.conditions.map((condition) {
              return DropdownMenuItem(
                value: condition,
                child: Text(condition),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCondition = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAcquiredDate() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acquired Date',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
            AppSpacing.verticalXs,
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18.sp,
                ),
                AppSpacing.horizontalSm,
                Text(
                  _acquiredDate != null
                      ? '${_acquiredDate!.month}/${_acquiredDate!.day}/${_acquiredDate!.year}'
                      : 'Tap to select date',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _acquiredDate != null ? Colors.white : Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          AppSpacing.verticalXs,
          TextFormField(
            controller: _notesController,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            decoration: _inputDecoration('Add any notes...'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }
}
