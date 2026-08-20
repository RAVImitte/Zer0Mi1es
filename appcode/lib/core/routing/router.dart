import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/couple/data/supabase_couple_repository.dart';
import '../../features/couple/presentation/couple_screen.dart';
import '../../features/daily_question/presentation/daily_question_screen.dart';
import '../../features/outfit/presentation/outfit_screen.dart';
import '../../features/daily_photo/presentation/daily_photo_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final authStateStream = ref.watch(authStateProvider);
  final activeCoupleIdStream = ref.watch(activeCoupleIdProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authStateStream.isLoading) return null;

      final session = ref.read(authRepositoryProvider).currentSession;
      final isAuth = session != null;
      final isGoingToLogin = state.matchedLocation == '/auth';

      if (!isAuth && !isGoingToLogin) {
        return '/auth';
      }

      if (isAuth) {
        if (activeCoupleIdStream.isLoading) return null;

        final hasCouple = activeCoupleIdStream.value != null;
        final isGoingToCouple = state.matchedLocation == '/couple';

        if (!hasCouple && !isGoingToCouple) {
          return '/couple';
        }

        if (hasCouple && (isGoingToLogin || isGoingToCouple)) {
          return '/';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
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
