import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract final class AppSpacing {
  // Base spacing values
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;

  // Vertical spacing
  static SizedBox get verticalXs => SizedBox(height: 4.h);
  static SizedBox get verticalSm => SizedBox(height: 8.h);
  static SizedBox get verticalMd => SizedBox(height: 16.h);
  static SizedBox get verticalLg => SizedBox(height: 24.h);
  static SizedBox get verticalXl => SizedBox(height: 32.h);

  // Horizontal spacing
  static SizedBox get horizontalXs => SizedBox(width: 4.w);
  static SizedBox get horizontalSm => SizedBox(width: 8.w);
  static SizedBox get horizontalMd => SizedBox(width: 16.w);
  static SizedBox get horizontalLg => SizedBox(width: 24.w);
  static SizedBox get horizontalXl => SizedBox(width: 32.w);

  // Padding
  static EdgeInsets get paddingXs => EdgeInsets.all(4.w);
  static EdgeInsets get paddingSm => EdgeInsets.all(8.w);
  static EdgeInsets get paddingMd => EdgeInsets.all(16.w);
  static EdgeInsets get paddingLg => EdgeInsets.all(24.w);
  static EdgeInsets get paddingXl => EdgeInsets.all(32.w);

  // Border Radius values
  static double get radiusSm => 12.r;
  static double get radiusMd => 16.r;
  static double get radiusLg => 24.r;
  static double get radiusXl => 32.r;
  static double get radiusFull => 999.r;

  // Border Radius - Soft rounded edges
  static BorderRadius get borderRadiusSm => BorderRadius.all(Radius.circular(12.r));
  static BorderRadius get borderRadiusMd => BorderRadius.all(Radius.circular(16.r));
  static BorderRadius get borderRadiusLg => BorderRadius.all(Radius.circular(24.r));
  static BorderRadius get borderRadiusXl => BorderRadius.all(Radius.circular(32.r));
  static BorderRadius get borderRadiusFull => BorderRadius.all(Radius.circular(999.r));
}
