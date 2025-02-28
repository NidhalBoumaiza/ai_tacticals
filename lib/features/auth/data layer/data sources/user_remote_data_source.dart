import 'dart:convert';

import 'package:analysis_ai/features/auth/data%20layer/data%20sources/user_local_data_source.dart';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  /// Registers a new user with the provided user data.
  Future<UserModel> signUp(UserModel userModel);

  /// Logs in a user with the provided email and password.
  Future<UserModel> login(String email, String password);

  /// Logs out the authenticated user.
  Future<Unit> logout();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final http.Client client;
  final UserLocalDataSource localDataSource;
  final String baseUrl = 'https://aitacticalanalysis.com/api';

  UserRemoteDataSourceImpl({
    required this.client,
    required this.localDataSource,
  });

  @override
  Future<UserModel> signUp(UserModel userModel) async {
    final response = await client.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': userModel.name,
        'email': userModel.email,
        'password': userModel.password,
        'password_confirmation': userModel.passwordConfirm,
      }),
    );

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      final userJson = responseBody['user'];
      final user = UserModel.fromJson(userJson);
      await localDataSource.cacheUser(user); // Cache the user
      return user;
    } else if (response.statusCode == 200) {
      //Should be fixed in the backend
      final responseBody = jsonDecode(response.body);
      final errorMessage = responseBody['message'] as String;
      ServerMessageFailure(errorMessage);
      throw ServerMessageException();
    } else {
      throw ServerException();
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['token'] != null) {
        await localDataSource.saveToken(
          responseBody['token'],
        ); // Save token locally
      }
      final userJson = responseBody['user'];
      final user = UserModel.fromJson(userJson);
      await localDataSource.cacheUser(user); // Cache the user
      return user;
    } else if (response.statusCode == 400) {
      final responseBody = jsonDecode(response.body);
      final errorMessage = responseBody['message'] as String;
      ServerMessageFailure(errorMessage);
      throw ServerMessageException();
    } else if (response.statusCode == 401) {
      throw UnauthorizedException();
    } else {
      throw ServerException();
    }
  }

  @override
  Future<Unit> logout() async {
    final token = await localDataSource.getToken();
    final response = await client.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token ?? ''}',
      },
    );

    if (response.statusCode == 200) {
      await localDataSource.signOut(); // Clear user and token
      return unit;
    } else if (response.statusCode == 401) {
      throw UnauthorizedException();
    } else if (response.statusCode == 400) {
      final responseBody = jsonDecode(response.body);
      final errorMessage = responseBody['message'] as String;
      ServerMessageFailure(errorMessage);
      throw ServerMessageException();
    } else {
      throw ServerException();
    }
  }
}
