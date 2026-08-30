// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_setup_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileSetupViewModel)
final profileSetupViewModelProvider = ProfileSetupViewModelProvider._();

final class ProfileSetupViewModelProvider
    extends $NotifierProvider<ProfileSetupViewModel, AsyncValue<void>> {
  ProfileSetupViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profileSetupViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profileSetupViewModelHash();

  @$internal
  @override
  ProfileSetupViewModel create() => ProfileSetupViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$profileSetupViewModelHash() =>
    r'6cfe8f95066e16ffefd5912a2849b2f49b2cb68c';

abstract class _$ProfileSetupViewModel extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
        AsyncValue<void>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
