import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/user_credential_params.dart';
import 'auth_state.dart';

/// Cubit for managing authentication state & user actions (Rule 7, 8, 9).
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

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
    if (email.trim().isEmpty || !email.contains('@')) {
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

    // Simulated network authentication delay
    await Future.delayed(const Duration(milliseconds: 1400));

    emit(AuthSuccess(
      mode: AuthMode.signIn,
      user: UserModel(
        id: 'usr_01',
        email: email,
        name: email.split('@').first,
      ),
    ));
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (fullName.trim().isEmpty) {
      emit(const AuthFailure(
        mode: AuthMode.signUp,
        errorMessage: 'Please enter your name.',
      ));
      return;
    }
    if (email.trim().isEmpty || !email.contains('@')) {
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

    // Simulated network registration delay
    await Future.delayed(const Duration(milliseconds: 1500));

    emit(AuthSuccess(
      mode: AuthMode.signUp,
      user: UserModel(
        id: 'usr_new',
        email: email,
        name: fullName,
      ),
    ));
  }

  Future<void> signInWithSocial(String provider) async {
    emit(AuthLoading(mode: state.mode, message: 'Connecting to $provider...'));
    await Future.delayed(const Duration(milliseconds: 1200));

    emit(AuthSuccess(
      mode: state.mode,
      user: UserModel(
        id: 'usr_social',
        email: 'collaborator@kaku.workspace',
        name: '$provider User',
      ),
    ));
  }
}
