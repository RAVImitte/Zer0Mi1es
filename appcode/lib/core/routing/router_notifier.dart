import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/supabase_auth_repository.dart';
import 'router.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Listen to changes in auth state or registration status and notify GoRouter
    _ref.listen(
      authStateProvider,
      (_, __) => notifyListeners(),
    );

    _ref.listen(
      registrationStatusProvider,
      (_, __) => notifyListeners(),
    );

    _ref.listen(
      appStartupProvider,
      (_, __) => notifyListeners(),
    );
  }
}
