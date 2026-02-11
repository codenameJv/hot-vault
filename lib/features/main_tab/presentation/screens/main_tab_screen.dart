import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../add_car/presentation/dialogs/add_car_dialog.dart';
import '../../../../core/assets/assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../collection/presentation/screens/collection_content.dart';
import '../../../favorites/presentation/screens/favorites_content.dart';
import '../../../home/presentation/screens/home_content.dart';
import '../../../profile/presentation/screens/profile_content.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final GlobalKey<HomeContentState> _homeKey = GlobalKey<HomeContentState>();
  final GlobalKey<CollectionContentState> _collectionKey =
      GlobalKey<CollectionContentState>();
  final GlobalKey<FavoritesContentState> _favoritesKey =
      GlobalKey<FavoritesContentState>();
  final GlobalKey<ProfileContentState> _profileKey =
      GlobalKey<ProfileContentState>();

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      // Refresh the tab when it becomes visible
      _refreshTab(index);
    }
  }

  void _refreshTab(int index) {
    switch (index) {
      case 0:
        _homeKey.currentState?.refresh();
        break;
      case 1:
        _collectionKey.currentState?.refresh();
        break;
      case 2:
        _favoritesKey.currentState?.refresh();
        break;
      case 3:
        _profileKey.currentState?.refresh();
        break;
    }
  }

  Future<void> _onAddCarPressed() async {
    final autoFavorite = _currentIndex == 2;
    final result = await AddCarDialog.show(context, autoFavorite: autoFavorite);
    if (result == true) {
      _refreshAllTabs();
    }
  }

  void _refreshAllTabs() {
    _homeKey.currentState?.refresh();
    _collectionKey.currentState?.refresh();
    _favoritesKey.currentState?.refresh();
    _profileKey.currentState?.refresh();
  }

  void _onDataChanged() {
    _refreshAllTabs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: AppConstants.toolbarHeight,
        leadingWidth: 120.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Image.asset(
            AppLogos.hotwheels,
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeContent(
            key: _homeKey,
            onNavigateToCollection: () => _onTabSelected(1),
            onNavigateToFavorites: () => _onTabSelected(2),
          ),
          CollectionContent(
            key: _collectionKey,
            onDataChanged: _onDataChanged,
          ),
          FavoritesContent(
            key: _favoritesKey,
            onNavigateToCollection: () => _onTabSelected(1),
            onDataChanged: _onDataChanged,
          ),
          ProfileContent(key: _profileKey),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildFab() {
    return Container(
      height: 56.w,
      width: 56.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'main_tab_add',
        onPressed: _onAddCarPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.add,
          color: AppColors.primary,
          size: 28.sp,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Nav bar pill
          Container(
            height: 64.h,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left side - Home & Collection
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_rounded,
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.grid_view_rounded,
                        index: 1,
                      ),
                    ],
                  ),
                ),
                // Center space for FAB
                SizedBox(width: 72.w),
                // Right side - Favorites & Profile
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.favorite_rounded,
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: Icons.person_rounded,
                        index: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // FAB centered on top
          if (_currentIndex <= 2)
            Positioned(
              top: -12.h,
              child: _buildFab(),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(12.w),
        child: Icon(
          icon,
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.4),
          size: 26.sp,
        ),
      ),
    );
  }
}
