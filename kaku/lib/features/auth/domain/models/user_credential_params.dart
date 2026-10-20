export '../../../../core/models/user_model.dart';

/// Parameter models for Auth operations
class SignInParams {
  const SignInParams({
    required this.email,
    required this.password,
    this.rememberMe = true,
  });

  final String email;
  final String password;
  final bool rememberMe;
}

class SignUpParams {
  const SignUpParams({
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String email;
  final String password;
}
