/// Parameter models for Auth operations (Rule 1 & Rule 11).
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

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;
}
