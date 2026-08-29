import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/supabase_auth_repository.dart';

part 'profile_setup_view_model.g.dart';

@riverpod
class ProfileSetupViewModel extends _$ProfileSetupViewModel {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> setupProfile(String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.setupProfile(displayName);
      ref.invalidate(registrationStatusProvider);
    });
  }
}
