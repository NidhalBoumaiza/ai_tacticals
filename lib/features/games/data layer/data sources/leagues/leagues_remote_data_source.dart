import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../../core/web view/web_view_api_call.dart'; // Adjust path to WebViewApiCall
import '../../../../../core/error/exceptions.dart';
import '../../models/league_model.dart';
import '../../models/season_model.dart';

abstract class LeaguesRemoteDataSource {
  Future<List<LeagueModel>> getLeaguesByCountryId(int countryId);
  Future<List<SeasonModel>> getSeasonsByTournamentId(int uniqueTournamentId);
}

class LeaguesRemoteDataSourceImpl implements LeaguesRemoteDataSource {
  final WebViewApiCall webViewApiCall;

  LeaguesRemoteDataSourceImpl({required this.webViewApiCall});

  @override
  Future<List<LeagueModel>> getLeaguesByCountryId(int countryId) async {
    const baseUrl = 'https://www.sofascore.com/api/v1/category';
    final url = '$baseUrl/$countryId/unique-tournaments';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      // Since WebViewApiCall returns parsed JSON, cast it directly
      final responseBody = jsonData as Map<String, dynamic>;
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
      int uniqueTournamentId) async {
    final url =
        'https://www.sofascore.com/api/v1/unique-tournament/$uniqueTournamentId/seasons';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      // Since WebViewApiCall returns parsed JSON, cast it directly
      final responseBody = jsonData as Map<String, dynamic>;
      final List<dynamic> seasonsJson = responseBody['seasons'] as List;
      return seasonsJson
          .map(
            (season) => SeasonModel.fromJson(season as Map<String, dynamic>),
      )
          .toList();
    } on TimeoutException {
      throw ServerMessageException('Something very wrong happened');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }
}