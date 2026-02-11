import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/assets/assets.dart';
import '../../../../shared/styles/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Simulate loading time - replace with actual initialization logic
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              children: [
                const Spacer(flex: 1),
                // Logo
                Image.asset(
                  AppLogos.hotwheels,
                  width: 450.w,
                  fit: BoxFit.contain,
                ),
                const Spacer(flex: 3),
                // Loading bar at the bottom
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  child: SoftLoadingBar(
                    height: 6.h,
                  ),
                ),
                AppSpacing.verticalXl,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
