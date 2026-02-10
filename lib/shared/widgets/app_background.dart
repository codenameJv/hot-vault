import 'package:flutter/material.dart';

import '../../core/assets/assets.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.mainBackground),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
