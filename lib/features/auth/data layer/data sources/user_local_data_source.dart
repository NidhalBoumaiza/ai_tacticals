import 'package:dartz/dartz.dart';

import '../models/user_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class UserLocalDataSource {
  /// Caches the user data locally.
  Future<Unit> cacheUser(UserModel user);

  /// Retrieves the cached user data.
  Future<UserModel> getUser();

  /// Clears cached user data and token (signs out locally).
  Future<Unit> signOut();

  /// Saves the authentication token.
  Future<Unit> saveToken(String token);

  /// Retrieves the authentication token.
  Future<String?> getToken();
}


class UserLocalDataSourceImpl implements UserLocalDataSource {
  final SharedPreferences sharedPreferences;

  UserLocalDataSourceImpl({required this.sharedPreferences});

  static const String USER_KEY = 'CACHED_USER';
  static const String TOKEN_KEY = 'TOKEN';

  @override
  Future<Unit> cacheUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await sharedPreferences.setString(USER_KEY, userJson);
    return Future.value(unit);
  }

  @override
  Future<UserModel> getUser() async {
    final userJson = sharedPreferences.getString(USER_KEY);
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } else {
      throw EmptyCacheException();
    }
  }

  @override
  Future<Unit> signOut() async {
    await sharedPreferences.remove(USER_KEY);
    await sharedPreferences.remove(TOKEN_KEY);
    return Future.value(unit);
  }

  @override
  Future<Unit> saveToken(String token) async {
    await sharedPreferences.setString(TOKEN_KEY, token);
    return Future.value(unit);
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(TOKEN_KEY);
  }
}
