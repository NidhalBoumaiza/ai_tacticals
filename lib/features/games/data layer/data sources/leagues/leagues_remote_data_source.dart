// lib/features/standings/data_layer/data_sources/leagues_remote_data_source.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../../core/error/exceptions.dart';
import '../../models/league_model.dart';
import '../../models/season_model.dart'; // Add this import

abstract class LeaguesRemoteDataSource {
  Future<List<LeagueModel>> getLeaguesByCountryId(int countryId);

  Future<List<SeasonModel>> getSeasonsByTournamentId(int uniqueTournamentId);
}

class LeaguesRemoteDataSourceImpl implements LeaguesRemoteDataSource {
  final http.Client client;

  LeaguesRemoteDataSourceImpl({required this.client});

  @override
  Future<List<LeagueModel>> getLeaguesByCountryId(int countryId) async {
    const baseUrl = 'https://www.sofascore.com/api/v1/category';
    final url = '$baseUrl/$countryId/unique-tournaments';

    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> groups = responseBody['groups'] as List;
        final List<LeagueModel> leagues = [];

        for (var group in groups) {
          final uniqueTournaments = group['uniqueTournaments'] as List;
          for (var tournament in uniqueTournaments) {
            final league = LeagueModel.fromJson(
              tournament as Map<String, dynamic>,
            );
            leagues.add(league);
          }
        }
        return leagues;
      } else {
        throw ServerException(
          'Failed to fetch leagues: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw ServerMessageException('Something very wrong happened');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<SeasonModel>> getSeasonsByTournamentId(
    int uniqueTournamentId,
  ) async {
    final url =
        'https://www.sofascore.com/api/v1/unique-tournament/$uniqueTournamentId/seasons';

    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> seasonsJson = responseBody['seasons'] as List;
        return seasonsJson
            .map(
              (season) => SeasonModel.fromJson(season as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw ServerException(
          'Failed to fetch seasons: ${response.statusCode}',
        );
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
