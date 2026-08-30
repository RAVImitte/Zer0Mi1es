// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AvatarViewModel)
final avatarViewModelProvider = AvatarViewModelProvider._();

final class AvatarViewModelProvider
    extends $NotifierProvider<AvatarViewModel, AnimationState> {
  AvatarViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'avatarViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$avatarViewModelHash();

  @$internal
  @override
  AvatarViewModel create() => AvatarViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnimationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnimationState>(value),
    );
  }
}

String _$avatarViewModelHash() => r'866426b505897414a1aa67e4909d203eaac5ba90';

abstract class _$AvatarViewModel extends $Notifier<AnimationState> {
  AnimationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AnimationState, AnimationState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AnimationState, AnimationState>,
        AnimationState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
