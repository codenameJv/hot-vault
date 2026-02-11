import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../styles/app_spacing.dart';

class SoftLoadingBar extends StatefulWidget {
  const SoftLoadingBar({
    super.key,
    this.value,
    this.height,
    this.width,
    this.backgroundColor,
    this.progressColor,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  /// If null, shows an indeterminate animated loading bar.
  /// If provided (0.0 to 1.0), shows a determinate progress bar.
  final double? value;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final Color? progressColor;
  final BorderRadius? borderRadius;
  final Duration animationDuration;

  @override
  State<SoftLoadingBar> createState() => _SoftLoadingBarState();
}

class _SoftLoadingBarState extends State<SoftLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.value == null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SoftLoadingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && _controller.isAnimating) {
      _controller.stop();
    } else if (widget.value == null && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        widget.borderRadius ?? AppSpacing.borderRadiusFull;
    final backgroundColor =
        widget.backgroundColor ?? AppColors.secondary.withValues(alpha: 0.3);
    final progressColor = widget.progressColor ?? AppColors.secondary;

    final effectiveHeight = widget.height ?? 8.h;

    return Container(
      height: effectiveHeight,
      width: widget.width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveBorderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.value != null
          ? _buildDeterminateBar(progressColor, effectiveBorderRadius)
          : _buildIndeterminateBar(progressColor, effectiveBorderRadius, effectiveHeight),
    );
  }

  Widget _buildDeterminateBar(Color color, BorderRadius borderRadius) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widget.value!.clamp(0.0, 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildIndeterminateBar(Color color, BorderRadius borderRadius, double height) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _IndeterminateLoadingPainter(
            progress: _animation.value,
            color: color,
            borderRadius: height / 2,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _IndeterminateLoadingPainter extends CustomPainter {
  _IndeterminateLoadingPainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
  });

  final double progress;
  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create a smooth loading animation that moves across the bar
    const barWidthRatio = 0.4;
    final barWidth = size.width * barWidthRatio;

    // Calculate position with smooth easing
    final totalTravel = size.width + barWidth;
    final startX = -barWidth + (totalTravel * progress);

    final rect = RRect.fromLTRBR(
      startX.clamp(0.0, size.width),
      0,
      (startX + barWidth).clamp(0.0, size.width),
      size.height,
      Radius.circular(borderRadius),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_IndeterminateLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
