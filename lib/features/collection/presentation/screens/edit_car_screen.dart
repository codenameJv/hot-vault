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

class EditCarScreen extends StatefulWidget {
  final String carId;

  const EditCarScreen({super.key, required this.carId});

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _seriesController = TextEditingController();
  final _yearController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _notesController = TextEditingController();
  final CarRepository _carRepository = sl<CarRepository>();
  final ImageService _imageService = sl<ImageService>();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCondition = 'Mint';
  DateTime? _acquiredDate;
  bool _isSaving = false;
  bool _isLoading = true;
  File? _selectedImage;
  String? _existingImagePath;
  HotWheelsCar? _originalCar;

  @override
  void initState() {
    super.initState();
    _loadCar();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seriesController.dispose();
    _yearController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCar() async {
    try {
      final car = await _carRepository.getCarById(widget.carId);
      if (car != null) {
        setState(() {
          _originalCar = car;
          _nameController.text = car.name;
          _seriesController.text = car.series ?? '';
          _yearController.text = car.year?.toString() ?? '';
          _purchasePriceController.text = car.purchasePrice?.toString() ?? '';
          _sellingPriceController.text = car.sellingPrice?.toString() ?? '';
          _notesController.text = car.notes ?? '';
          _selectedCondition = car.condition ?? 'Mint';
          _acquiredDate = car.acquiredDate;
          _existingImagePath = car.imagePath;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Car not found'),
              backgroundColor: AppColors.error,
            ),
          );
          context.pop();
        }
      }
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
    final hasImage = _selectedImage != null || _existingImagePath != null;
    final source = await ImagePickerDialog.show(
      context,
      title: 'Change Photo',
      hasExistingImage: hasImage,
    );

    if (source != null) {
      _pickImage(source);
    } else if (hasImage) {
      setState(() {
        _selectedImage = null;
        _existingImagePath = null;
      });
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

  Future<void> _updateCar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originalCar == null) return;

    setState(() => _isSaving = true);

    try {
      String? imagePath = _existingImagePath;

      if (_selectedImage != null) {
        imagePath = await _saveImageToAppDir(_selectedImage!);
      }

      final updatedCar = _originalCar!.copyWith(
        name: _nameController.text.trim(),
        series: _seriesController.text.trim().isNotEmpty
            ? _seriesController.text.trim()
            : null,
        year: _yearController.text.trim().isNotEmpty
            ? int.tryParse(_yearController.text.trim())
            : null,
        imagePath: imagePath,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        condition: _selectedCondition,
        acquiredDate: _acquiredDate,
        purchasePrice: _purchasePriceController.text.trim().isNotEmpty
            ? double.tryParse(_purchasePriceController.text.trim())
            : null,
        sellingPrice: _sellingPriceController.text.trim().isNotEmpty
            ? double.tryParse(_sellingPriceController.text.trim())
            : null,
      );

      await _carRepository.updateCar(updatedCar);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedCar.name} updated!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update car: $e'),
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

  Widget? _buildCurrentImage() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: AppSpacing.borderRadiusMd,
        child: Image.file(
          _selectedImage!,
          height: 200.h,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (_existingImagePath != null) {
      return ClipRRect(
        borderRadius: AppSpacing.borderRadiusMd,
        child: Image.file(
          File(_existingImagePath!),
          height: 200.h,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        ),
      );
    }
    return null;
  }

  Widget _buildImagePlaceholder() {
    return Container(
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
    );
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
          'Edit Car',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SingleChildScrollView(
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
                              _buildCurrentImage() ?? _buildImagePlaceholder(),
                              AppSpacing.verticalSm,
                              Text(
                                'Tap to change photo',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
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
                        // Price Row
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
                                      'Purchase Price',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    AppSpacing.verticalSm,
                                    TextFormField(
                                      controller: _purchasePriceController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration('\$0.00'),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                      ],
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
                                      'Selling Price',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    AppSpacing.verticalSm,
                                    TextFormField(
                                      controller: _sellingPriceController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration('\$0.00'),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                          onPressed: _isSaving ? null : _updateCar,
                          text: 'Save Changes',
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
