import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/error/exceptions.dart';
import '../../models/country_model.dart';

abstract class GamesLocalDataSource {
  /// Caches the list of countries locally.
  Future<Unit> cacheCountries(List<CountryModel> countries);

  /// Retrieves the cached list of countries.
  Future<List<CountryModel>> getCachedCountries();
}

class GamesLocalDataSourceImpl implements GamesLocalDataSource {
  final SharedPreferences sharedPreferences;

  GamesLocalDataSourceImpl({required this.sharedPreferences});

  static const String COUNTRIES_KEY = 'CACHED_COUNTRIES';

  @override
  Future<Unit> cacheCountries(List<CountryModel> countries) async {
    final countriesJson = jsonEncode(
      countries.map((country) => country.toJson()).toList(),
    );
    await sharedPreferences.setString(COUNTRIES_KEY, countriesJson);
    return unit;
  }

  @override
  Future<List<CountryModel>> getCachedCountries() async {
    final countriesJson = sharedPreferences.getString(COUNTRIES_KEY);
    if (countriesJson != null) {
      try {
        final List<dynamic> decodedJson = jsonDecode(countriesJson) as List;
        final List<CountryModel> countries =
            decodedJson
                .map(
                  (json) => CountryModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();
        return countries;
      } catch (e) {
        throw EmptyCacheException('Failed to parse cached countries: $e');
      }
    } else {
      throw EmptyCacheException('No cached countries found');
    }
  }
}
