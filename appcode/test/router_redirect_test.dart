import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/core/constants/app_constants.dart';
import 'package:zer0mi1es/core/routing/app_routes.dart';
import 'package:zer0mi1es/core/routing/auth_redirect.dart';

void main() {
  group('resolveRedirect', () {
    test('no session → auth', () {
      expect(
        resolveRedirect(hasSession: false, matchedLocation: AppRoutes.splash),
        AppRoutes.auth,
      );
      expect(
        resolveRedirect(hasSession: false, matchedLocation: AppRoutes.home),
        AppRoutes.auth,
      );
      expect(
        resolveRedirect(hasSession: false, matchedLocation: AppRoutes.auth),
        isNull,
      );
    });

    test('session + signedUp → profile setup', () {
      expect(
        resolveRedirect(
          hasSession: true,
          registrationStatus: RegistrationStatus.signedUp,
          matchedLocation: AppRoutes.splash,
        ),
        AppRoutes.profileSetup,
      );
      expect(
        resolveRedirect(
          hasSession: true,
          registrationStatus: RegistrationStatus.signedUp,
          matchedLocation: AppRoutes.home,
        ),
        AppRoutes.profileSetup,
      );
      expect(
        resolveRedirect(
          hasSession: true,
          registrationStatus: RegistrationStatus.signedUp,
          matchedLocation: AppRoutes.profileSetup,
        ),
        isNull,
      );
    });

    test('session + nameEntered/allDone on splash/auth/profileSetup → home',
        () {
      const ready = [
        RegistrationStatus.nameEntered,
        RegistrationStatus.allDone,
      ];
      const setupRoutes = [
        AppRoutes.splash,
        AppRoutes.auth,
        AppRoutes.profileSetup,
      ];

      for (final status in ready) {
        for (final location in setupRoutes) {
          expect(
            resolveRedirect(
              hasSession: true,
              registrationStatus: status,
              matchedLocation: location,
            ),
            AppRoutes.home,
            reason: '$status on $location',
          );
        }
      }
    });

    test('password recovery holds on auth when session present', () {
      expect(
        resolveRedirect(
          hasSession: true,
          passwordRecovering: true,
          registrationStatus: RegistrationStatus.allDone,
          matchedLocation: AppRoutes.auth,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          hasSession: true,
          passwordRecovering: true,
          registrationStatus: RegistrationStatus.allDone,
          matchedLocation: AppRoutes.home,
        ),
        AppRoutes.auth,
      );
    });
  });
}
