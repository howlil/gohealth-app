class RegisterModel {
  final String name;
  final String email;
  final String password;
  final String? confirmPassword;

  RegisterModel({
    required this.name,
    required this.email,
    required this.password,
    this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      if (confirmPassword != null) 'confirm_password': confirmPassword,
    };
  }

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      confirmPassword: json['confirm_password'] as String?,
    );
  }
}
