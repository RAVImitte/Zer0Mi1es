import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/supabase_couple_repository.dart';

part 'couple_view_model.g.dart';

// Represents the state of the couple creation/join UI
class CoupleState {
  final bool isLoading;
  final String? errorMessage;
  final String? generatedToken; // The token to show to the partner

  const CoupleState({
    this.isLoading = false,
    this.errorMessage,
    this.generatedToken,
  });

  CoupleState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? generatedToken,
  }) {
    return CoupleState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      generatedToken: generatedToken ?? this.generatedToken,
    );
  }
}

@riverpod
class CoupleViewModel extends _$CoupleViewModel {
  @override
  CoupleState build() {
    return const CoupleState();
  }

  Future<void> createCouple() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(coupleRepositoryProvider);
      final token = await repo.createCouple();
      state = state.copyWith(isLoading: false, generatedToken: token);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> joinCouple(String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(coupleRepositoryProvider);
      await repo.joinCouple(token);
      state = state.copyWith(isLoading: false);
      // Once successful, activeCoupleId stream will update and route the user away
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
