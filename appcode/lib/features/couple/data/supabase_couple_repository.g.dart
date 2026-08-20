// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_couple_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(coupleRepository)
final coupleRepositoryProvider = CoupleRepositoryProvider._();

final class CoupleRepositoryProvider extends $FunctionalProvider<
    CoupleRepository,
    CoupleRepository,
    CoupleRepository> with $Provider<CoupleRepository> {
  CoupleRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'coupleRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$coupleRepositoryHash();

  @$internal
  @override
  $ProviderElement<CoupleRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoupleRepository create(Ref ref) {
    return coupleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoupleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoupleRepository>(value),
    );
  }
}

String _$coupleRepositoryHash() => r'44ebc4f113e78d6df82154cc6b4033fa33085ac6';

@ProviderFor(activeCoupleId)
final activeCoupleIdProvider = ActiveCoupleIdProvider._();

final class ActiveCoupleIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  ActiveCoupleIdProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'activeCoupleIdProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$activeCoupleIdHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return activeCoupleId(ref);
  }
}

String _$activeCoupleIdHash() => r'd6df1291255e658c24f0bd89438fac2202bf7d02';

@ProviderFor(partnerName)
final partnerNameProvider = PartnerNameProvider._();

final class PartnerNameProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  PartnerNameProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'partnerNameProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$partnerNameHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return partnerName(ref);
  }
}

String _$partnerNameHash() => r'16eb2152536496404c6759b4c1ef434d03d0727d';

@ProviderFor(partnerRole)
final partnerRoleProvider = PartnerRoleProvider._();

final class PartnerRoleProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  PartnerRoleProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'partnerRoleProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$partnerRoleHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return partnerRole(ref);
  }
}

String _$partnerRoleHash() => r'a3dd889ae3af08cf1515184f7c13f24e6669b3a5';
