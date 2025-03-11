import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../domain layer/entities/matches_entities.dart';
import '../../models/matches_models.dart';

abstract class MatchesLocalDataSource {
  Future<MatchEventsPerTeamEntity> getLastMatchesPerTeam(
    int uniqueTournamentId,
    int seasonId,
  );

  Future<void> cacheMatchesPerTeam(
    MatchEventsPerTeamEntity matches,
    int uniqueTournamentId,
    int seasonId,
  );

  Future<MatchEventsPerTeamEntity> getLastHomeMatches(String date);

  Future<void> cacheHomeMatches(MatchEventsPerTeamEntity matches, String date);
}

class MatchesLocalDataSourceImpl implements MatchesLocalDataSource {
  final SharedPreferences sharedPreferences;

  MatchesLocalDataSourceImpl({required this.sharedPreferences});

  static const String cacheKeyPrefix = 'MATCHES_PER_TEAM_';
  static const String homeCacheKeyPrefix = 'HOME_MATCHES_';

  @override
  Future<MatchEventsPerTeamEntity> getLastMatchesPerTeam(
    int uniqueTournamentId,
    int seasonId,
  ) async {
    final key = '$cacheKeyPrefix${uniqueTournamentId}_$seasonId';
    final jsonString = sharedPreferences.getString(key);

    if (jsonString != null) {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final model = MatchEventsPerTeamModel.fromJson(json);
      return model.toEntity();
    } else {
      throw EmptyCacheException("No cache found");
    }
  }

  @override
  Future<void> cacheMatchesPerTeam(
    MatchEventsPerTeamEntity matches,
    int uniqueTournamentId,
    int seasonId,
  ) async {
    final key = '$cacheKeyPrefix${uniqueTournamentId}_$seasonId';
    final model = MatchEventsPerTeamModel(
      tournamentTeamEvents: matches.tournamentTeamEvents?.map(
        (key, value) => MapEntry(
          key,
          value
              .map(
                (e) => MatchEventModel(
                  tournament: e.tournament,
                  customId: e.customId,
                  status:
                      e.status != null
                          ? StatusModel(
                            code: e.status!.code,
                            description: e.status!.description,
                            type: e.status!.type,
                          )
                          : null,
                  winnerCode: e.winnerCode,
                  homeTeam: e.homeTeam,
                  awayTeam: e.awayTeam,
                  homeScore:
                      e.homeScore != null
                          ? ScoreModel(
                            current: e.homeScore!.current,
                            display: e.homeScore!.display,
                            period1: e.homeScore!.period1,
                            period2: e.homeScore!.period2,
                            normaltime: e.homeScore!.normaltime,
                          )
                          : null,
                  awayScore:
                      e.awayScore != null
                          ? ScoreModel(
                            current: e.awayScore!.current,
                            display: e.awayScore!.display,
                            period1: e.awayScore!.period1,
                            period2: e.awayScore!.period2,
                            normaltime: e.awayScore!.normaltime,
                          )
                          : null,
                  hasXg: e.hasXg,
                  id: e.id,
                  startTimestamp: e.startTimestamp,
                  slug: e.slug,
                  finalResultOnly: e.finalResultOnly,
                ),
              )
              .toList(),
        ),
      ),
    );
    final jsonString = jsonEncode(model.toJson());
    await sharedPreferences.setString(key, jsonString);
  }

  @override
  Future<MatchEventsPerTeamEntity> getLastHomeMatches(String date) async {
    final key = '$homeCacheKeyPrefix$date';
    final jsonString = sharedPreferences.getString(key);

    if (jsonString != null) {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final model = MatchEventsPerTeamModel.fromJson(json);
      return model.toEntity();
    } else {
      throw EmptyCacheException("No cache found for home matches on $date");
    }
  }

  @override
  Future<void> cacheHomeMatches(
    MatchEventsPerTeamEntity matches,
    String date,
  ) async {
    final key = '$homeCacheKeyPrefix$date';
    final model = MatchEventsPerTeamModel(
      tournamentTeamEvents: matches.tournamentTeamEvents?.map(
        (key, value) => MapEntry(
          key,
          value
              .map(
                (e) => MatchEventModel(
                  tournament: e.tournament,
                  customId: e.customId,
                  status:
                      e.status != null
                          ? StatusModel(
                            code: e.status!.code,
                            description: e.status!.description,
                            type: e.status!.type,
                          )
                          : null,
                  winnerCode: e.winnerCode,
                  homeTeam: e.homeTeam,
                  awayTeam: e.awayTeam,
                  homeScore:
                      e.homeScore != null
                          ? ScoreModel(
                            current: e.homeScore!.current,
                            display: e.homeScore!.display,
                            period1: e.homeScore!.period1,
                            period2: e.homeScore!.period2,
                            normaltime: e.homeScore!.normaltime,
                          )
                          : null,
                  awayScore:
                      e.awayScore != null
                          ? ScoreModel(
                            current: e.awayScore!.current,
                            display: e.awayScore!.display,
                            period1: e.awayScore!.period1,
                            period2: e.awayScore!.period2,
                            normaltime: e.awayScore!.normaltime,
                          )
                          : null,
                  hasXg: e.hasXg,
                  id: e.id,
                  startTimestamp: e.startTimestamp,
                  slug: e.slug,
                  finalResultOnly: e.finalResultOnly,
                ),
              )
              .toList(),
        ),
      ),
    );
    final jsonString = jsonEncode(model.toJson());
    await sharedPreferences.setString(key, jsonString);
  }
}
