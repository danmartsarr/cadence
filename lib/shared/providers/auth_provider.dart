import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserProfile? user, bool? isLoading, String? error, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Please fill in all fields');
      return false;
    }

    // Mock successful login
    state = state.copyWith(
      isLoading: false,
      user: UserProfile(
        id: 'user_001',
        username: email.split('@').first,
        email: email,
        reviewCount: 42,
        friendIds: ['friend_001', 'friend_002'],
      ),
    );
    return true;
  }

  Future<bool> signUp(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800));

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Please fill in all fields');
      return false;
    }

    state = state.copyWith(
      isLoading: false,
      user: UserProfile(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        reviewCount: 0,
      ),
    );
    return true;
  }

  void signOut() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
