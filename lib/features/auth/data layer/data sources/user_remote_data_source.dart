import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../data sources/user_local_data_source.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> login(String email, String password);

  Future<UserModel> signUp(UserModel userModel);

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
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['token'] != null) {
          await localDataSource.saveToken(responseBody['token']);
        }
        final userJson = responseBody['user'];
        final user = UserModel.fromJson(userJson);
        await localDataSource.cacheUser(user);
        return user;
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final responseBody = jsonDecode(response.body);
        final errorMessage =
            responseBody['message'] as String? ?? 'Login failed';

        throw UnauthorizedException();
      } else {
        throw ServerException('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ServerMessageException('Something very wrong happened');
    }
  }

  @override
  Future<UserModel> signUp(UserModel userModel) async {
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': userModel.name,
              'email': userModel.email,
              'password': userModel.password,
              'password_confirmation': userModel.passwordConfirm,
            }),
          )
          .timeout(const Duration(seconds: 12)); // Timeout after 10 seconds
      if (response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        final userJson = responseBody['user'];
        final user = UserModel.fromJson(userJson);
        await localDataSource.cacheUser(user);
        return user;
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        final errorMessage =
            responseBody['message'] as String? ?? 'Signup failed';
        throw ServerMessageException(errorMessage);
      } else {
        throw ServerException('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ServerMessageException('Something very wrong happened');
    }
  }

  @override
  Future<Unit> logout() async {
    final token = await localDataSource.getToken();
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${token ?? ''}',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await localDataSource.signOut();
        return unit;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access');
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] as String;
        throw ServerMessageException(errorMessage);
      } else {
        throw ServerException('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ServerMessageException('Something very wrong happened');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }
}
