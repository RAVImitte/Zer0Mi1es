import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/splash_screen.dart';
import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/profile_setup_screen.dart';
import '../../features/couple/presentation/couple_screen.dart';
import '../../features/daily_photo/presentation/daily_photo_screen.dart';
import '../../features/daily_question/presentation/daily_question_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/outfit/presentation/outfit_screen.dart';
import '../constants/app_constants.dart';
import 'app_routes.dart';
import 'router_notifier.dart';

part 'router.g.dart';

@riverpod
Future<void> appStartup(Ref ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  if (authRepo.currentSession == null) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

@riverpod
GoRouter router(Ref ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final startup = ref.read(appStartupProvider);
      if (startup.isLoading) return AppRoutes.splash;

      final session = ref.read(authRepositoryProvider).currentSession;
      final isAuth = session != null;

      if (!isAuth) {
        return state.matchedLocation == AppRoutes.auth ? null : AppRoutes.auth;
      }

      final registrationStatusStream = ref.read(registrationStatusProvider);
      final isStatusLoading =
          registrationStatusStream.isLoading && !registrationStatusStream.hasValue;
      if (isStatusLoading) {
        return state.matchedLocation == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final status =
          registrationStatusStream.value ?? RegistrationStatus.signedUp;

      if (status == RegistrationStatus.signedUp) {
        return state.matchedLocation == AppRoutes.profileSetup
            ? null
            : AppRoutes.profileSetup;
      }

      if (status == RegistrationStatus.nameEntered ||
          status == RegistrationStatus.allDone) {
        final isSetupRoute = state.matchedLocation == AppRoutes.splash ||
            state.matchedLocation == AppRoutes.auth ||
            state.matchedLocation == AppRoutes.profileSetup;
        if (isSetupRoute) {
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.couple,
        builder: (context, state) => const CoupleScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyQuestion,
        builder: (context, state) => const DailyQuestionScreen(),
      ),
      GoRoute(
        path: AppRoutes.outfit,
        builder: (context, state) => const OutfitScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyPhoto,
        builder: (context, state) => const DailyPhotoScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
