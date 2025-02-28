import '../../domain layer/entities/userEntity.dart';

class UserModel extends UserEntity {
  UserModel(
    String? id, // Nullable String?
    String name,
    String email,
    String password,
    String passwordConfirm,
  ) : super(
        id ?? '',
        name,
        email,
        password,
        passwordConfirm,
      ); // Pass all 5 arguments to superclass

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      json['_id'], // Nullable, will be null if not present in JSON
      json['name'] ?? '',
      json['email'] ?? '',
      json['password'] ?? '',
      json['passwordConfirm'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'email': email,
      'password': password,
      'passwordConfirm': passwordConfirm,
    };
    // Only include 'id' if it’s non-null and non-empty
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    return json;
  }
}
