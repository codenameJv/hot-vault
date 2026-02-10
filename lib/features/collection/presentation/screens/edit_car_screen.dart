import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/database/database.dart';
import '../../../../core/models/models.dart';
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
  final _notesController = TextEditingController();
  final CarRepository _carRepository = CarRepository();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCondition = 'Mint';
  DateTime? _acquiredDate;
  bool _isSaving = false;
  bool _isLoading = true;
  File? _selectedImage;
  String? _existingImagePath;
  HotWheelsCar? _originalCar;

  final List<String> _conditions = [
    'Mint',
    'Near Mint',
    'Excellent',
    'Good',
    'Fair',
    'Poor',
  ];

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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Photo',
              style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
            ),
            AppSpacing.verticalLg,
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              title: Text(
                'Take Photo',
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
              title: Text(
                'Choose from Gallery',
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null || _existingImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: AppColors.error),
                title: Text(
                  'Remove Photo',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _existingImagePath = null;
                  });
                },
              ),
            AppSpacing.verticalMd,
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _acquiredDate ?? DateTime.now(),
      firstDate: DateTime(1968),
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
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/car_images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final savedImage = await imageFile.copy('${imagesDir.path}/$fileName');

      return savedImage.path;
    } catch (e) {
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
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (_existingImagePath != null) {
      return ClipRRect(
        borderRadius: AppSpacing.borderRadiusMd,
        child: Image.file(
          File(_existingImagePath!),
          height: 200,
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
      height: 150,
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
            size: 48,
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
                  padding: const EdgeInsets.all(20),
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
                                value: _selectedCondition,
                                dropdownColor: AppColors.tertiary,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(null),
                                items: _conditions.map((condition) {
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
                                    size: 20,
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

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: Colors.white54, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
