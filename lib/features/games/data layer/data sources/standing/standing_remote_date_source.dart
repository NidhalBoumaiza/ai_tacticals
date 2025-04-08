import 'dart:async';
import 'dart:io';

import 'package:analysis_ai/core/web view/web_view_api_call.dart'; // Adjust path to WebViewApiCall
import 'package:analysis_ai/core/error/exceptions.dart';

import '../../models/season_model.dart';
import '../../models/standing_model.dart';

abstract class StandingsRemoteDataSource {
  Future<StandingsModel> getStandings(int leagueId, int seasonId);
  Future<List<SeasonModel>> getSeasonsByTournamentId(int uniqueTournamentId);
}

class StandingsRemoteDataSourceImpl implements StandingsRemoteDataSource {
  final WebViewApiCall webViewApiCall;

  StandingsRemoteDataSourceImpl({required this.webViewApiCall});

  @override
  Future<StandingsModel> getStandings(int leagueId, int seasonId) async {
    final url = 'https://www.sofascore.com/api/v1/unique-tournament/$leagueId/season/$seasonId/standings/total';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      if (jsonData == null || jsonData.isEmpty) {
        throw ServerException('Invalid standings data received');
      }

      final standings = StandingsModel.fromJson(jsonData);

      // Debug print for a sample team name from standings (assuming standings contains team data)
     // final sampleTeamName = standings.standings?.first.rows?.first.team?.name ?? 'Unknown';
     //  print('StandingsRemoteDataSource: Team name raw: $sampleTeamName');
     //  print('StandingsRemoteDataSource: Team name code units: ${sampleTeamName.codeUnits}');

      return standings;
    } on TimeoutException {
      throw ServerException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('Failed to load standings: $e');
    }
  }

  @override
  Future<List<SeasonModel>> getSeasonsByTournamentId(int uniqueTournamentId) async {
    final url = 'https://www.sofascore.com/api/v1/unique-tournament/$uniqueTournamentId/seasons';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      if (jsonData == null || jsonData.isEmpty) {
        throw ServerException('Invalid seasons data received');
      }

      final seasonsJson = jsonData['seasons'] as List<dynamic>? ?? [];
      final seasons = seasonsJson
          .map((season) => SeasonModel.fromJson(season as Map<String, dynamic>))
          .toList();

      // Debug print for a sample season name (if applicable)
      if (seasons.isNotEmpty) {
        //final sampleSeasonName = seasons.first.name ?? 'Unknown';
        // print('StandingsRemoteDataSource: Season name raw: $sampleSeasonName');
        // print('StandingsRemoteDataSource: Season name code units: ${sampleSeasonName.codeUnits}');
      }

      return seasons;
    } on TimeoutException {
      throw ServerException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('Failed to load seasons: $e');
    }
  }
}