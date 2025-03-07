// one_match_local_data_source.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../domain layer/entities/one_match_statics_entity.dart';


// Abstract class
abstract class OneMatchLocalDataSource {
  Future<void> cacheMatchDetails(
      MatchEventEntity event, MatchStatisticsEntity stats, int matchId);
  Future<MatchEventEntity> getLastMatchEvent(int matchId);
  Future<MatchStatisticsEntity> getLastMatchStatistics(int matchId);
}

// Implementation
class OneMatchLocalDataSourceImpl implements OneMatchLocalDataSource {
  final SharedPreferences sharedPreferences;

  OneMatchLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheMatchDetails(
      MatchEventEntity event, MatchStatisticsEntity stats, int matchId) async {
    final eventJson = json.encode(event.toJson());
    final statsJson = json.encode(stats.toJson());
    await sharedPreferences.setString('match_event_$matchId', eventJson);
    await sharedPreferences.setString('match_stats_$matchId', statsJson);
  }

  @override
  Future<MatchEventEntity> getLastMatchEvent(int matchId) async {
    final jsonString = sharedPreferences.getString('match_event_$matchId');
    if (jsonString != null) {
      return MatchEventEntity.fromJson(json.decode(jsonString));
    } else {
      throw EmptyCacheException('No cached match event found for matchId: $matchId');
    }
  }

  @override
  Future<MatchStatisticsEntity> getLastMatchStatistics(int matchId) async {
    final jsonString = sharedPreferences.getString('match_stats_$matchId');
    if (jsonString != null) {
      return MatchStatisticsEntity.fromJson(json.decode(jsonString));
    } else {
      throw EmptyCacheException('No cached match statistics found for matchId: $matchId');
    }
  }
}

// Add toJson methods to entities (you'll need these for caching)
extension MatchEventEntityExtension on MatchEventEntity {
  Map<String, dynamic> toJson() => {
    'tournament': tournament.toJson(),
    'season': season.toJson(),
    'roundInfo': roundInfo.toJson(),
    'status': status.toJson(),
    'winnerCode': winnerCode,
    'attendance': attendance,
    'venue': venue.toJson(),
    'referee': referee.toJson(),
    'homeTeam': homeTeam.toJson(),
    'awayTeam': awayTeam.toJson(),
    'homeScore': homeScore.toJson(),
    'awayScore': awayScore.toJson(),
    'time': time.toJson(),
    'id': id,
    'startTimestamp': startTimestamp,
  };
}

extension TournamentEntityExtension on TournamentEntity {
  Map<String, dynamic> toJson() => {
    'name': name,
    'uniqueTournament': uniqueTournament.toJson(),
  };
}

extension UniqueTournamentEntityExtension on UniqueTournamentEntity {
  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
  };
}

extension SeasonEntityExtension on SeasonEntity {
  Map<String, dynamic> toJson() => {
    'name': name,
    'year': year,
  };
}

extension RoundInfoEntityExtension on RoundInfoEntity {
  Map<String, dynamic> toJson() => {
    'round': round,
  };
}

extension StatusEntityExtension on StatusEntity {
  Map<String, dynamic> toJson() => {
    'code': code,
    'description': description,
    'type': type,
  };
}

extension VenueEntityExtension on VenueEntity {
  Map<String, dynamic> toJson() => {
    'city': city.toJson(),
    'name': name,
    'capacity': capacity,
  };
}

extension CityEntityExtension on CityEntity {
  Map<String, dynamic> toJson() => {
    'name': name,
  };
}

extension RefereeEntityExtension on RefereeEntity {
  Map<String, dynamic> toJson() => {
    'name': name,
  };
}

extension TeamEntityExtension on TeamEntity {
  Map<String, dynamic> toJson() => {
    'name': name,
    'shortName': shortName,
    'manager': manager.toJson(),
    'venue': venue.toJson(),
    'nameCode': nameCode,
  };
}

extension ManagerEntityExtension on ManagerEntity {
  Map<String, dynamic> toJson() => {
    'name': name,
  };
}

extension ScoreEntityExtension on ScoreEntity {
  Map<String, dynamic> toJson() => {
    'current': current,
    'period1': period1,
    'period2': period2,
    'normaltime': normaltime,
  };
}

extension TimeEntityExtension on TimeEntity {
  Map<String, dynamic> toJson() => {
    'injuryTime1': injuryTime1,
    'injuryTime2': injuryTime2,
  };
}

extension MatchStatisticsEntityExtension on MatchStatisticsEntity {
  Map<String, dynamic> toJson() => {
    'statistics': statistics.map((e) => e.toJson()).toList(),
  };
}

extension StatisticsPeriodEntityExtension on StatisticsPeriodEntity {
  Map<String, dynamic> toJson() => {
    'period': period,
    'groups': groups.map((e) => e.toJson()).toList(),
  };
}

extension StatisticsGroupEntityExtension on StatisticsGroupEntity {
  Map<String, dynamic> toJson() => {
    'groupName': groupName,
    'statisticsItems': statisticsItems.map((e) => e.toJson()).toList(),
  };
}

extension StatisticsItemEntityExtension on StatisticsItemEntity {
  Map<String, dynamic> toJson() => {
    'name': name,
    'home': home,
    'away': away,
    'compareCode': compareCode,
    'statisticsType': statisticsType,
    'valueType': valueType,
    'homeValue': homeValue,
    'awayValue': awayValue,
    'homeTotal': homeTotal,
    'awayTotal': awayTotal,
  };
}