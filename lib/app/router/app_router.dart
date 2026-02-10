import 'package:go_router/go_router.dart';

import '../../features/add_car/presentation/screens/add_car_screen.dart';
import '../../features/collection/presentation/screens/car_detail_screen.dart';
import '../../features/collection/presentation/screens/collection_screen.dart';
import '../../features/collection/presentation/screens/edit_car_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
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
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: Routes.addCar,
      name: 'addCar',
      builder: (context, state) => const AddCarScreen(),
    ),
    GoRoute(
      path: Routes.collection,
      name: 'collection',
      builder: (context, state) => const CollectionScreen(),
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
    GoRoute(
      path: Routes.favorites,
      name: 'favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: Routes.profile,
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
