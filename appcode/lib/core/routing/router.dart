import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/profile_setup_screen.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/splash_screen.dart';
import '../../features/couple/data/supabase_couple_repository.dart';
import '../../features/couple/presentation/couple_screen.dart';
import '../../features/daily_question/presentation/daily_question_screen.dart';
import '../../features/outfit/presentation/outfit_screen.dart';
import '../../features/daily_photo/presentation/daily_photo_screen.dart';

import 'router_notifier.dart';

part 'router.g.dart';

@riverpod
Future<void> appStartup(Ref ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  if (authRepo.currentSession == null) {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

@riverpod
GoRouter router(Ref ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final startup = ref.read(appStartupProvider);
      if (startup.isLoading) return '/splash';

      final session = ref.read(authRepositoryProvider).currentSession;
      final isAuth = session != null;
      
      if (!isAuth) {
        return state.matchedLocation == '/auth' ? null : '/auth';
      }

      final registrationStatusStream = ref.read(registrationStatusProvider);
      final isStatusLoading = registrationStatusStream.isLoading && !registrationStatusStream.hasValue;
      if (isStatusLoading) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      final status = registrationStatusStream.value ?? 'signed_up';

      if (status == 'signed_up') {
        return state.matchedLocation == '/profile-setup' ? null : '/profile-setup';
      }

      // Allow access to Home Screen if name_entered or all_done
      if (status == 'name_entered' || status == 'all_done') {
        final isSetupRoute = state.matchedLocation == '/splash' || 
                             state.matchedLocation == '/auth' || 
                             state.matchedLocation == '/profile-setup';
                             
        // If they are on a setup route, send them Home. 
        // Note: We no longer force them away from '/couple', so they can visit it anytime to pair!
        if (isSetupRoute) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
      GoRoute(
        path: '/couple',
        builder: (context, state) => const CoupleScreen(),
      ),
      GoRoute(
        path: '/daily_question',
        builder: (context, state) => const DailyQuestionScreen(),
      ),
      GoRoute(
        path: '/outfit',
        builder: (context, state) => const OutfitScreen(),
      ),
      GoRoute(
        path: '/daily_photo',
        builder: (context, state) => const DailyPhotoScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    ],
  );
}
