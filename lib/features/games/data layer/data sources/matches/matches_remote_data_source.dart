import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/web view/web_view_api_call.dart';
import '../../models/matches_models.dart';

abstract class MatchesRemoteDataSource {
  Future<MatchEventsPerTeamModel> getMatchesPerTeam(
      int uniqueTournamentId,
      int seasonId,
      );

  Future<MatchEventsPerTeamModel> getHomeMatches(String date);

  Future<List<MatchEventModel>> getMatchesPerRound(
      int leagueId,
      int seasonId,
      int round,
      );
}

class MatchesRemoteDataSourceImpl implements MatchesRemoteDataSource {
  final WebViewApiCall webViewApiCall;

  MatchesRemoteDataSourceImpl({required this.webViewApiCall});

  @override
  Future<MatchEventsPerTeamModel> getMatchesPerTeam(
      int uniqueTournamentId, int seasonId) async {
    final url =
        'https://www.sofascore.com/api/v1/unique-tournament/$uniqueTournamentId/season/$seasonId/team-events/total';

    try {
      final json = await webViewApiCall.fetchJsonFromWebView(url);
      final events = json['tournamentTeamEvents'] as Map<String, dynamic>?;

      if (events == null) {
        return MatchEventsPerTeamModel(tournamentTeamEvents: {});
      }

      final Map<String, List<MatchEventModel>> teamMatches = {};
      events.forEach((outerKey, innerMap) {
        if (innerMap is Map<String, dynamic>) {
          innerMap.forEach((teamId, matches) {
            final teamIdStr = teamId.toString();
            if (!teamMatches.containsKey(teamIdStr)) {
              teamMatches[teamIdStr] = [];
            }

            final matchList = (matches as List<dynamic>?)
                ?.map((e) => MatchEventModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
                [];

            final uniqueMatches = <String, MatchEventModel>{};
            for (var match in matchList) {
              final matchKey =
                  '${match.homeTeam?.id}_${match.awayTeam?.id}_${match.startTimestamp}_${match.status?.type}';
              if (!uniqueMatches.containsKey(matchKey)) {
                uniqueMatches[matchKey] = match;
              }
            }

            teamMatches[teamIdStr]!.addAll(uniqueMatches.values);
          });
        }
      });

      teamMatches.forEach((teamId, matches) {
        matches.sort((a, b) => (a.startTimestamp ?? 0).compareTo(b.startTimestamp ?? 0));
        teamMatches[teamId] = matches.take(5).toList();
      });

      return MatchEventsPerTeamModel(tournamentTeamEvents: teamMatches);
    } catch (e) {
      throw ServerException('Failed to load matches: $e');
    }
  }

  @override
  Future<MatchEventsPerTeamModel> getHomeMatches(String date) async {
    final url =
        'https://www.sofascore.com/api/v1/sport/football/scheduled-events/$date';

    try {
      final json = await webViewApiCall.fetchJsonFromWebView(url);
      final events = json['events'] as List<dynamic>?;

      if (events == null || events.isEmpty) {
        return MatchEventsPerTeamModel(tournamentTeamEvents: {});
      }

      final Map<String, List<MatchEventModel>> teamMatches = {};
      for (var event in events) {
        final match = MatchEventModel.fromJson(event as Map<String, dynamic>);
        final homeTeamId = match.homeTeam?.id.toString() ?? 'unknown';
        final awayTeamId = match.awayTeam?.id.toString() ?? 'unknown';

        if (!teamMatches.containsKey(homeTeamId)) {
          teamMatches[homeTeamId] = [];
        }
        if (!teamMatches[homeTeamId]!.any((m) => m.id == match.id)) {
          teamMatches[homeTeamId]!.add(match);
        }

        if (!teamMatches.containsKey(awayTeamId)) {
          teamMatches[awayTeamId] = [];
        }
        if (!teamMatches[awayTeamId]!.any((m) => m.id == match.id)) {
          teamMatches[awayTeamId]!.add(match);
        }
      }

      return MatchEventsPerTeamModel(tournamentTeamEvents: teamMatches);
    } catch (e) {
      throw ServerException('Failed to load home matches: $e');
    }
  }

  @override
  Future<List<MatchEventModel>> getMatchesPerRound(
      int leagueId, int seasonId, int round) async {
    final url =
        'https://www.sofascore.com/api/v1/unique-tournament/$leagueId/season/$seasonId/events/round/$round';

    try {
      final json = await webViewApiCall.fetchJsonFromWebView(url);
      final events = json['events'] as List<dynamic>? ?? [];

      return events
          .map((e) => MatchEventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to load matches per round: $e');
    }
  }
}