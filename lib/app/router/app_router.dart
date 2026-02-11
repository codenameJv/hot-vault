import 'package:go_router/go_router.dart';

import '../../features/collection/presentation/screens/car_detail_screen.dart';
import '../../features/collection/presentation/screens/edit_car_screen.dart';
import '../../features/main_tab/presentation/screens/main_tab_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.home,
      name: 'home',
      builder: (context, state) => const MainTabScreen(),
    ),
    GoRoute(
      path: '${Routes.carDetail}/:id',
      name: 'carDetail',
      builder: (context, state) {
        final carId = state.pathParameters['id']!;
        return CarDetailScreen(carId: carId);
      },
    ),
    GoRoute(
      path: '${Routes.editCar}/:id',
      name: 'editCar',
      builder: (context, state) {
        final carId = state.pathParameters['id']!;
        return EditCarScreen(carId: carId);
      },
    ),
  ],
);
