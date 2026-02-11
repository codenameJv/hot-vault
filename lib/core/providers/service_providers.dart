import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';

/// Provider for ImageService singleton
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});
