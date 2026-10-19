import '../../domain/models/user_credential_params.dart';

enum AuthMode { signIn, signUp }

sealed class AuthState {
  const AuthState({this.mode = AuthMode.signIn});
  final AuthMode mode;
}

final class AuthInitial extends AuthState {
  const AuthInitial({super.mode = AuthMode.signIn});
}

final class AuthLoading extends AuthState {
  const AuthLoading({super.mode, this.message = 'Authenticating...'});
  final String message;
}

final class AuthSuccess extends AuthState {
  const AuthSuccess({super.mode, required this.user});
  final UserModel user;
}

final class AuthFailure extends AuthState {
  const AuthFailure({super.mode, required this.errorMessage});
  final String errorMessage;
}
