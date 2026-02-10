import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../styles/app_spacing.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.elevation = 0,
    this.shadowColor,
    this.onTap,
    this.border,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final double elevation;
  final Color? shadowColor;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final Gradient? gradient;

  factory SoftCard.elevated({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return SoftCard(
      key: key,
      padding: padding,
      margin: margin,
      color: color,
      borderRadius: borderRadius,
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: onTap,
      child: child,
    );
  }

  factory SoftCard.outlined({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? borderColor,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return SoftCard(
      key: key,
      padding: padding,
      margin: margin,
      color: AppColors.secondary,
      borderRadius: borderRadius,
      border: Border.all(
        color: borderColor ?? AppColors.primary.withValues(alpha: 0.15),
        width: 1.5,
      ),
      onTap: onTap,
      child: child,
    );
  }

  factory SoftCard.gradient({
    Key? key,
    required Widget child,
    required List<Color> colors,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return SoftCard(
      key: key,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      gradient: LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      ),
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppSpacing.borderRadiusMd;
    final effectivePadding = padding ?? AppSpacing.paddingMd;

    Widget cardContent = Container(
      padding: effectivePadding,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.secondary) : null,
        gradient: gradient,
        borderRadius: effectiveBorderRadius,
        border: border,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: shadowColor ?? AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: elevation * 2,
                  spreadRadius: elevation * 0.5,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
