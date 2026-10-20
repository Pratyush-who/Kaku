import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Cubit for managing authentication state & user actions
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthInitial());

  final AuthRepository _authRepository;

  void toggleMode() {
    final nextMode = state.mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
    emit(AuthInitial(mode: nextMode));
  }

  void setMode(AuthMode mode) {
    if (state.mode != mode) {
      emit(AuthInitial(mode: mode));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      emit(const AuthFailure(
        mode: AuthMode.signIn,
        errorMessage: 'Please enter a valid email address.',
      ));
      return;
    }
    if (password.length < 6) {
      emit(const AuthFailure(
        mode: AuthMode.signIn,
        errorMessage: 'Password must be at least 6 characters.',
      ));
      return;
    }

    emit(const AuthLoading(mode: AuthMode.signIn, message: 'Signing in to Kaku...'));

    try {
      final user = await _authRepository.login(
        email: cleanEmail,
        password: password,
      );
      emit(AuthSuccess(mode: AuthMode.signIn, user: user));
    } catch (e) {
      emit(AuthFailure(
        mode: AuthMode.signIn,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cleanName = fullName.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      emit(const AuthFailure(
        mode: AuthMode.signUp,
        errorMessage: 'Please enter your name.',
      ));
      return;
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      emit(const AuthFailure(
        mode: AuthMode.signUp,
        errorMessage: 'Please enter a valid email address.',
      ));
      return;
    }
    if (password.length < 8) {
      emit(const AuthFailure(
        mode: AuthMode.signUp,
        errorMessage: 'Password must be at least 8 characters.',
      ));
      return;
    }

    emit(const AuthLoading(mode: AuthMode.signUp, message: 'Creating your workspace...'));

    try {
      final user = await _authRepository.register(
        name: cleanName,
        email: cleanEmail,
        password: password,
        displayName: cleanName,
      );
      emit(AuthSuccess(mode: AuthMode.signUp, user: user));
    } catch (e) {
      emit(AuthFailure(
        mode: AuthMode.signUp,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signInWithSocial(String provider) async {
    emit(AuthLoading(mode: state.mode, message: 'Connecting to $provider...'));
    final email = '${provider.toLowerCase()}.user@kaku.workspace';
    final password = 'KakuSocialPassword123!';
    try {
      // Try login first
      final user = await _authRepository.login(email: email, password: password);
      emit(AuthSuccess(mode: state.mode, user: user));
    } catch (_) {
      try {
        // If not found, register automatically
        final user = await _authRepository.register(
          name: '$provider User',
          email: email,
          password: password,
          displayName: '$provider Explorer',
        );
        emit(AuthSuccess(mode: state.mode, user: user));
      } catch (e) {
        emit(AuthFailure(mode: state.mode, errorMessage: e.toString()));
      }
    }
  }
}
