import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../styles/app_spacing.dart';

class SoftTextField extends StatelessWidget {
  const SoftTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  factory SoftTextField.password({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? label,
    String? hint,
    String? errorText,
    bool enabled = true,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return SoftTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      errorText: errorText,
      enabled: enabled,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: AppColors.primary.withValues(alpha: 0.6),
        ),
        onPressed: onToggleVisibility,
      ),
    );
  }

  factory SoftTextField.search({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? hint,
    bool enabled = true,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
  }) {
    return SoftTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      hint: hint ?? 'Search...',
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      prefixIcon: Icon(
        Icons.search_rounded,
        color: AppColors.primary.withValues(alpha: 0.6),
      ),
      suffixIcon: onClear != null
          ? IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
              onPressed: onClear,
            )
          : null,
    );
  }

  factory SoftTextField.multiline({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? label,
    String? hint,
    String? errorText,
    String? helperText,
    bool enabled = true,
    int minLines = 3,
    int maxLines = 6,
    int? maxLength,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return SoftTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      errorText: errorText,
      helperText: helperText,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppSpacing.borderRadiusMd;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: hasError ? AppColors.error : AppColors.primary,
            ),
          ),
          AppSpacing.verticalSm,
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          validator: validator,
          style: TextStyle(
            fontSize: 16.sp,
            color: enabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 16.sp,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            helperText: helperText,
            helperStyle: TextStyle(
              fontSize: 12.sp,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            errorText: errorText,
            errorStyle: TextStyle(
              fontSize: 12.sp,
              color: AppColors.error,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor ?? AppColors.primary.withValues(alpha: 0.05),
            contentPadding: contentPadding ??
                EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 16.h,
                ),
            border: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2.w,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: AppColors.error,
                width: 1.5.w,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2.w,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
