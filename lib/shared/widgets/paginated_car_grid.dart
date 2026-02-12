import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../core/models/models.dart';
import 'car_card.dart';

class PaginatedCarGrid extends StatefulWidget {
  final List<HotWheelsCar> cars;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;
  final void Function(HotWheelsCar car)? onCarTap;
  final void Function(HotWheelsCar car)? onFavoriteToggle;
  final void Function(HotWheelsCar car)? onDelete;
  final bool showDeleteButton;
  final Widget? emptyWidget;
  final Map<String, int>? duplicateCounts;

  const PaginatedCarGrid({
    super.key,
    required this.cars,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.onLoadMore,
    this.onRefresh,
    this.onCarTap,
    this.onFavoriteToggle,
    this.onDelete,
    this.showDeleteButton = true,
    this.emptyWidget,
    this.duplicateCounts,
  });

  @override
  State<PaginatedCarGrid> createState() => _PaginatedCarGridState();
}

class _PaginatedCarGridState extends State<PaginatedCarGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!widget.isLoadingMore && !widget.hasReachedEnd && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (widget.cars.isEmpty) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    Widget gridView = GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        childAspectRatio: 0.85,
      ),
      itemCount: widget.cars.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.cars.length) {
          return _buildLoadingIndicator();
        }

        final car = widget.cars[index];
        return CarCard(
          car: car,
          showDeleteButton: widget.showDeleteButton,
          duplicateCount: widget.duplicateCounts?[car.name],
          onTap: widget.onCarTap != null ? () => widget.onCarTap!(car) : null,
          onFavoriteToggle: widget.onFavoriteToggle != null
              ? () => widget.onFavoriteToggle!(car)
              : null,
          onDelete: widget.onDelete != null ? () => widget.onDelete!(car) : null,
        );
      },
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        color: AppColors.tertiary,
        backgroundColor: AppColors.primary,
        child: gridView,
      );
    }

    return gridView;
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
