import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../../core/web view/web_view_api_call.dart'; // Adjust path to WebViewApiCall
import '../../../../../core/error/exceptions.dart';
import '../../models/country_model.dart';

abstract class GamesRemoteDataSource {
  /// Fetches all countries (categories) from the remote API.
  Future<List<CountryModel>> getAllCountries();
}

class GamesRemoteDataSourceImpl implements GamesRemoteDataSource {
  final WebViewApiCall webViewApiCall;
  final String baseUrl = 'https://www.sofascore.com/api/v1/sport/football';

  GamesRemoteDataSourceImpl({required this.webViewApiCall});

  @override
  Future<List<CountryModel>> getAllCountries() async {
    try {
      // Ensure we have internet connection before proceeding
      await InternetAddress.lookup('sofascore.com');

      final jsonData = await webViewApiCall.fetchJsonFromWebView('$baseUrl/categories');

      if (jsonData == null || jsonData['categories'] == null) {
        throw ServerException('Invalid response format');
      }

      final List<dynamic> categories = jsonData['categories'] as List;
      return categories
          .map((category) => CountryModel.fromJson(category as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw OfflineException('No Internet connection');
    } on TimeoutException {
      throw ServerException('Request timed out');
    } catch (e) {
      throw ServerException('Failed to load countries: ${e.toString()}');
    }
  }
}