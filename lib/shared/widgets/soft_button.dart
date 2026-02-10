import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../styles/app_spacing.dart';

enum SoftButtonVariant { primary, secondary, outline, ghost }

class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = SoftButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height = 56,
    this.padding,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final SoftButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;

  factory SoftButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double height = 56,
    Widget? icon,
  }) {
    return SoftButton(
      key: key,
      onPressed: onPressed,
      variant: SoftButtonVariant.primary,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      height: height,
      icon: icon,
      child: Text(text),
    );
  }

  factory SoftButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double height = 56,
    Widget? icon,
  }) {
    return SoftButton(
      key: key,
      onPressed: onPressed,
      variant: SoftButtonVariant.secondary,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      height: height,
      icon: icon,
      child: Text(text),
    );
  }

  factory SoftButton.outline({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double height = 56,
    Widget? icon,
  }) {
    return SoftButton(
      key: key,
      onPressed: onPressed,
      variant: SoftButtonVariant.outline,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      height: height,
      icon: icon,
      child: Text(text),
    );
  }

  factory SoftButton.ghost({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double height = 56,
    Widget? icon,
  }) {
    return SoftButton(
      key: key,
      onPressed: onPressed,
      variant: SoftButtonVariant.ghost,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      height: height,
      icon: icon,
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isDisabled || isLoading ? null : onPressed;

    return SizedBox(
      width: width,
      height: height,
      child: _buildButton(context, effectiveOnPressed),
    );
  }

  Widget _buildButton(BuildContext context, VoidCallback? effectiveOnPressed) {
    final buttonStyle = _getButtonStyle();
    final buttonChild = _buildChild(context);

    switch (variant) {
      case SoftButtonVariant.primary:
      case SoftButtonVariant.secondary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: buttonChild,
        );
      case SoftButtonVariant.outline:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: buttonChild,
        );
      case SoftButtonVariant.ghost:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: buttonChild,
        );
    }
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: variant == SoftButtonVariant.primary
              ? AppColors.secondary
              : AppColors.primary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          AppSpacing.horizontalSm,
          child,
        ],
      );
    }

    return child;
  }

  ButtonStyle _getButtonStyle() {
    switch (variant) {
      case SoftButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.secondary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.secondary.withValues(alpha: 0.7),
          elevation: 0,
          padding: padding ?? AppSpacing.paddingMd,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        );
      case SoftButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.tertiary,
          foregroundColor: AppColors.secondary,
          disabledBackgroundColor: AppColors.tertiary.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.secondary.withValues(alpha: 0.7),
          elevation: 0,
          padding: padding ?? AppSpacing.paddingMd,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        );
      case SoftButtonVariant.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.primary.withValues(alpha: 0.5),
          padding: padding ?? AppSpacing.paddingMd,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        );
      case SoftButtonVariant.ghost:
        return TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.primary.withValues(alpha: 0.5),
          padding: padding ?? AppSpacing.paddingMd,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }
}
