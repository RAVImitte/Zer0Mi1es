import '../constants/app_constants.dart';
import 'app_routes.dart';

/// Auth/registration gate. Returns a location, or null to stay.
String? resolveRedirect({
  required bool hasSession,
  required String matchedLocation,
  bool startupLoading = false,
  bool passwordRecovering = false,
  bool statusLoading = false,
  String? registrationStatus,
}) {
  if (startupLoading) return AppRoutes.splash;

  if (!hasSession) {
    return matchedLocation == AppRoutes.auth ? null : AppRoutes.auth;
  }

  if (passwordRecovering) {
    return matchedLocation == AppRoutes.auth ? null : AppRoutes.auth;
  }

  if (statusLoading) {
    return matchedLocation == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final status = registrationStatus ?? RegistrationStatus.signedUp;

  if (status == RegistrationStatus.signedUp) {
    return matchedLocation == AppRoutes.profileSetup
        ? null
        : AppRoutes.profileSetup;
  }

  if (status == RegistrationStatus.nameEntered ||
      status == RegistrationStatus.allDone) {
    final isSetupRoute = matchedLocation == AppRoutes.splash ||
        matchedLocation == AppRoutes.auth ||
        matchedLocation == AppRoutes.profileSetup;
    if (isSetupRoute) {
      return AppRoutes.home;
    }
  }

  return null;
}
