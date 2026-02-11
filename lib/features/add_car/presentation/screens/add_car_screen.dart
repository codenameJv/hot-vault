import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
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
      );

      await _carRepository.insertCar(car);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${car.name} added to collection!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Car',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSpacing.verticalMd,
                  // Image Picker
                  SoftCard(
                    padding: AppSpacing.paddingLg,
                    color: AppColors.primary,
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    onTap: _showImageSourceDialog,
                    child: Column(
                      children: [
                        if (_selectedImage != null)
                          ClipRRect(
                            borderRadius: AppSpacing.borderRadiusMd,
                            child: Image.file(
                              _selectedImage!,
                              height: 200.h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 150.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  size: 48.sp,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                AppSpacing.verticalSm,
                                Text(
                                  'Tap to add photo',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_selectedImage != null) ...[
                          AppSpacing.verticalSm,
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
                  AppSpacing.verticalMd,
                  // Name Field
                  SoftCard(
                    padding: AppSpacing.paddingLg,
                    color: AppColors.primary,
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Car Name *',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        AppSpacing.verticalSm,
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
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
                  ),
                  AppSpacing.verticalMd,
                  // Series and Year Row
                  Row(
                    children: [
                      Expanded(
                        child: SoftCard(
                          padding: AppSpacing.paddingLg,
                          color: AppColors.primary,
                          elevation: 8,
                          shadowColor: AppColors.primary.withValues(alpha: 0.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Series',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              AppSpacing.verticalSm,
                              TextFormField(
                                controller: _seriesController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('e.g. Mainline'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.horizontalMd,
                      Expanded(
                        child: SoftCard(
                          padding: AppSpacing.paddingLg,
                          color: AppColors.primary,
                          elevation: 8,
                          shadowColor: AppColors.primary.withValues(alpha: 0.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Year',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              AppSpacing.verticalSm,
                              TextFormField(
                                controller: _yearController,
                                style: const TextStyle(color: Colors.white),
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
                  ),
                  AppSpacing.verticalMd,
                  // Condition Dropdown
                  SoftCard(
                    padding: AppSpacing.paddingLg,
                    color: AppColors.primary,
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Condition',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        AppSpacing.verticalSm,
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCondition,
                          dropdownColor: AppColors.tertiary,
                          style: const TextStyle(color: Colors.white),
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
                  ),
                  AppSpacing.verticalMd,
                  // Acquired Date
                  SoftCard(
                    padding: AppSpacing.paddingLg,
                    color: AppColors.primary,
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    onTap: _selectDate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acquired Date',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        AppSpacing.verticalSm,
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 20.sp,
                            ),
                            AppSpacing.horizontalMd,
                            Text(
                              _acquiredDate != null
                                  ? '${_acquiredDate!.month}/${_acquiredDate!.day}/${_acquiredDate!.year}'
                                  : 'Tap to select date',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: _acquiredDate != null
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalMd,
                  // Notes
                  SoftCard(
                    padding: AppSpacing.paddingLg,
                    color: AppColors.primary,
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        AppSpacing.verticalSm,
                        TextFormField(
                          controller: _notesController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Add any notes...'),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalXl,
                  // Save Button
                  SoftButton.primary(
                    onPressed: _isSaving ? null : _saveCar,
                    text: 'Add to Collection',
                    isLoading: _isSaving,
                  ),
                  AppSpacing.verticalLg,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) =>
      InputDecorationHelper.soft(hint: hint);
}
