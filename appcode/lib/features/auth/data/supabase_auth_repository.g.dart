// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'f62ab297b398ab67b94a2c6d28cd41ffe7077cc2';

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

final class AuthStateProvider extends $FunctionalProvider<AsyncValue<AuthState>,
        AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  AuthStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authStateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'5b6ce11eb4ed4d4001a3e5b734c234d4ad7ecf6c';

@ProviderFor(registrationStatus)
final registrationStatusProvider = RegistrationStatusProvider._();

final class RegistrationStatusProvider
    extends $FunctionalProvider<AsyncValue<String>, String, Stream<String>>
    with $FutureModifier<String>, $StreamProvider<String> {
  RegistrationStatusProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'registrationStatusProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$registrationStatusHash();

  @$internal
  @override
  $StreamProviderElement<String> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String> create(Ref ref) {
    return registrationStatus(ref);
  }
}

String _$registrationStatusHash() =>
    r'29aceab738d037382912102993dfbff9f140f496';
