import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/country_model.dart';

abstract class GamesRemoteDataSource {
  /// Fetches all countries (categories) from the remote API.
  Future<List<CountryModel>> getAllCountries();
}

class GamesRemoteDataSourceImpl implements GamesRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'https://www.sofascore.com/api/v1/sport/football';

  GamesRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CountryModel>> getAllCountries() async {
    try {
      final response = await client
          .get(Uri.parse('$baseUrl/categories'))
          .timeout(
            const Duration(seconds: 12),
          ); // Timeout after 12 seconds (matches your template)

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> categories = responseBody['categories'] as List;
        final List<CountryModel> countries =
            categories.map((category) {
              return CountryModel.fromJson(category as Map<String, dynamic>);
            }).toList();
        return countries;
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage =
            responseBody['message'] as String? ?? 'Failed to fetch countries';
        throw UnauthorizedException(errorMessage);
      } else if (response.statusCode == 404) {
        throw ServerMessageException('Resource not found');
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
