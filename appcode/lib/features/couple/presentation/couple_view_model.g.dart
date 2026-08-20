// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'couple_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CoupleViewModel)
final coupleViewModelProvider = CoupleViewModelProvider._();

final class CoupleViewModelProvider
    extends $NotifierProvider<CoupleViewModel, CoupleState> {
  CoupleViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'coupleViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$coupleViewModelHash();

  @$internal
  @override
  CoupleViewModel create() => CoupleViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoupleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoupleState>(value),
    );
  }
}

String _$coupleViewModelHash() => r'c3e2915af55ffe91d5401a48deec16bacbcd0be5';

abstract class _$CoupleViewModel extends $Notifier<CoupleState> {
  CoupleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CoupleState, CoupleState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<CoupleState, CoupleState>, CoupleState, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
