import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../../core/error/exceptions.dart';
import '../../models/matches_models.dart';

abstract class MatchesRemoteDataSource {
  Future<List<MatchEventModel>> getMatchesPerTeam(
    int uniqueTournamentId,
    int seasonId,
  );

  Future<List<MatchEventModel>> getHomeMatches(String date);

  Future<List<MatchEventModel>> getMatchesPerRound(
    int leagueId,
    int seasonId,
    int round,
  );
}

class MatchesRemoteDataSourceImpl implements MatchesRemoteDataSource {
  final http.Client client;

  MatchesRemoteDataSourceImpl({required this.client});

  @override
  Future<List<MatchEventModel>> getMatchesPerTeam(
    int uniqueTournamentId,
    int seasonId,
  ) async {
    final url = Uri.parse(
      'https://www.sofascore.com/api/v1/unique-tournament/$uniqueTournamentId/season/$seasonId/team-events/total',
    );

    try {
      final response = await client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final events = json['tournamentTeamEvents'] as Map<String, dynamic>?;

        // Flatten nested structure into a list
        final List<MatchEventModel> matchList = [];
        if (events != null) {
          events.forEach((outerKey, innerMap) {
            if (innerMap is Map<String, dynamic>) {
              innerMap.forEach((teamId, matches) {
                final matchEvents =
                    (matches as List<dynamic>?)
                        ?.map(
                          (e) => MatchEventModel.fromJson(
                            e as Map<String, dynamic>,
                          ),
                        )
                        .toList() ??
                    [];
                matchList.addAll(matchEvents);
              });
            }
          });
        }

        return matchList;
      } else {
        throw ServerException('Failed to load matches: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      print('Error in getMatchesPerTeam: $e');
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<MatchEventModel>> getHomeMatches(String date) async {
    final url = Uri.parse(
      'https://www.sofascore.com/api/v1/sport/football/scheduled-events/$date',
    );

    try {
      final response = await client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final events = json['events'] as List<dynamic>?;

        if (events == null || events.isEmpty) {
          return [];
        }

        return events
            .map((e) => MatchEventModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Failed to load home matches: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      print('Error in getHomeMatches: $e');
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  Future<List<MatchEventModel>> getMatchesPerRound(
    int leagueId,
    int seasonId,
    int round,
  ) async {
    final url = Uri.parse(
      'https://www.sofascore.com/api/v1/unique-tournament/$leagueId/season/$seasonId/events/round/$round',
    );
    print('Fetching URL: $url');
    try {
      final response = await client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final events = json['events'] as List<dynamic>? ?? [];
        print('Parsed ${events.length} events');
        return events
            .map((e) => MatchEventModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Failed to load matches per round: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getMatchesPerRound: $e');
      throw ServerException('An unexpected error occurred: $e');
    }
  }
}
