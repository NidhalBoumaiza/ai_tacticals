import '../../domain layer/entities/league_entity.dart';
import '../../domain layer/entities/matches_entities.dart';
import '../../domain layer/entities/team_standing _entity.dart';

// matches_models.dart (partial update)
class MatchEventsPerTeamModel {
  final Map<String, List<MatchEventModel>>? tournamentTeamEvents;
  final List<MatchEventModel>? events;

  MatchEventsPerTeamModel({this.tournamentTeamEvents, this.events});

  factory MatchEventsPerTeamModel.fromJson(Map<String, dynamic> json) {
    final tournamentTeamEventsData =
        json['tournamentTeamEvents'] as Map<String, dynamic>?;
    Map<String, List<MatchEventModel>>? parsedTournamentTeamEvents;
    if (tournamentTeamEventsData != null) {
      parsedTournamentTeamEvents = {};
      tournamentTeamEventsData.forEach((outerKey, innerMap) {
        if (innerMap is Map<String, dynamic>) {
          innerMap.forEach((teamId, matchList) {
            parsedTournamentTeamEvents![teamId] =
                (matchList as List<dynamic>?)?.map((e) {
                  return MatchEventModel.fromJson(e as Map<String, dynamic>);
                }).toList() ??
                [];
          });
        }
      });
    }

    final eventsData = json['events'] as List<dynamic>?;
    List<MatchEventModel>? parsedEvents;
    if (eventsData != null) {
      parsedEvents =
          eventsData
              .map((e) => MatchEventModel.fromJson(e as Map<String, dynamic>))
              .toList();
    }

    return MatchEventsPerTeamModel(
      tournamentTeamEvents: parsedTournamentTeamEvents,
      events: parsedEvents,
    );
  }

  MatchEventsPerTeamEntity toEntity() {
    if (events != null && events!.isNotEmpty) {
      // Handle events from getHomeMatches
      final Map<String, List<MatchEventEntity>> groupedByTeam = {};
      for (var match in events!) {
        final matchEntity = match.toEntity();
        // Add the match to both teams, but we'll deduplicate in the UI
        final homeTeamId = match.homeTeam?.id.toString() ?? 'unknown';
        final awayTeamId = match.awayTeam?.id.toString() ?? 'unknown';

        groupedByTeam.putIfAbsent(homeTeamId, () => []).add(matchEntity);
        groupedByTeam.putIfAbsent(awayTeamId, () => []).add(matchEntity);
      }
      return MatchEventsPerTeamEntity(tournamentTeamEvents: groupedByTeam);
    }

    // Process tournamentTeamEvents
    final Map<String, List<MatchEventEntity>> deduplicatedTeamEvents = {};
    tournamentTeamEvents?.forEach((teamId, matchList) {
      if (!deduplicatedTeamEvents.containsKey(teamId)) {
        deduplicatedTeamEvents[teamId] = [];
      }
      final uniqueMatches = <String, MatchEventEntity>{};
      for (var match in matchList) {
        final matchEntity = match.toEntity();
        final matchKey =
            '${matchEntity.homeTeam?.id}_${matchEntity.awayTeam?.id}_${matchEntity.startTimestamp}_${matchEntity.status?.type}';
        if (!uniqueMatches.containsKey(matchKey)) {
          uniqueMatches[matchKey] = matchEntity;
        }
      }
      deduplicatedTeamEvents[teamId]!.addAll(uniqueMatches.values);
      // Sort by startTimestamp and limit to 5 matches
      deduplicatedTeamEvents[teamId]!.sort(
        (a, b) => (a.startTimestamp ?? 0).compareTo(b.startTimestamp ?? 0),
      );
      deduplicatedTeamEvents[teamId] =
          deduplicatedTeamEvents[teamId]!.take(5).toList();
    });

    return MatchEventsPerTeamEntity(
      tournamentTeamEvents: deduplicatedTeamEvents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournamentTeamEvents': tournamentTeamEvents?.map(
        (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
      ),
      'events': events?.map((e) => e.toJson()).toList(),
    };
  }
}

class MatchEventModel {
  final LeagueEntity? tournament;
  final String? customId;
  final StatusModel? status;
  final int? winnerCode;
  final TeamStandingEntity? homeTeam;
  final TeamStandingEntity? awayTeam;
  final ScoreModel? homeScore;
  final ScoreModel? awayScore;
  final bool? hasXg;
  final int? id;
  final int? startTimestamp;
  final String? slug;
  final bool? finalResultOnly;
  final bool? isLive;
  final TimeModel? time;

  int? get currentLiveMinutes {
    if (startTimestamp == null || !isLive!)
      return null; // Only for live matches
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsedSeconds = now - startTimestamp!;
    final totalMinutes = (elapsedSeconds / 60).floor();

    if (time?.currentPeriodStartTimestamp != null) {
      final periodElapsedSeconds = now - time!.currentPeriodStartTimestamp!;
      final periodMinutes = (periodElapsedSeconds / 60).floor();
      final timeSinceStart =
          (time!.currentPeriodStartTimestamp! - startTimestamp!) ~/ 60;

      if (timeSinceStart >= 45) {
        // Second half
        final baseMinutes =
            45 + (time?.injuryTime1 ?? 0); // First half duration
        return baseMinutes + periodMinutes;
      } else {
        // First half
        return totalMinutes;
      }
    }

    // Fallback: Use total time if period info is missing
    final firstHalfMax = 45 + (time?.injuryTime1 ?? 0);
    final fullTimeMax =
        90 + (time?.injuryTime1 ?? 0) + (time?.injuryTime2 ?? 0);
    if (totalMinutes <= firstHalfMax) {
      return totalMinutes; // First half
    } else if (totalMinutes <= fullTimeMax) {
      return totalMinutes; // Second half
    } else {
      return fullTimeMax; // Cap at full time
    }
  }

  MatchEventModel({
    this.tournament,
    this.customId,
    this.status,
    this.winnerCode,
    this.homeTeam,
    this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.hasXg,
    this.id,
    this.startTimestamp,
    this.slug,
    this.finalResultOnly,
    this.isLive,
    this.time,
  });

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    try {
      final tournamentData = json['tournament'] as Map<String, dynamic>?;
      LeagueEntity? tournamentEntity;
      if (tournamentData != null) {
        final uniqueTournamentData =
            tournamentData['uniqueTournament'] as Map<String, dynamic>?;
        tournamentEntity = LeagueEntity(
          id:
              uniqueTournamentData != null
                  ? uniqueTournamentData['id'] as int?
                  : tournamentData['id'] as int?,
          name: tournamentData['name'] as String?,
        );
      }

      final statusData = json['status'] as Map<String, dynamic>?;
      final statusType = statusData?['type'] as String?;
      final isLive = statusType == 'inprogress';

      return MatchEventModel(
        tournament: tournamentEntity,
        customId: json['customId'] as String?,
        status: statusData != null ? StatusModel.fromJson(statusData) : null,
        winnerCode: json['winnerCode'] as int?,
        homeTeam:
            json['homeTeam'] != null
                ? TeamStandingEntity(
                  shortName:
                      (json['homeTeam'] as Map<String, dynamic>?)?['shortName']
                          as String?,
                  id:
                      (json['homeTeam'] as Map<String, dynamic>?)?['id']
                          as int?,
                  teamColors:
                      json['homeTeam']?['teamColors'] != null
                          ? TeamColorsEntity(
                            primary:
                                (json['homeTeam']['teamColors']
                                        as Map<String, dynamic>?)?['primary']
                                    as String?,
                            secondary:
                                (json['homeTeam']['teamColors']
                                        as Map<String, dynamic>?)?['secondary']
                                    as String?,
                            text:
                                (json['homeTeam']['teamColors']
                                        as Map<String, dynamic>?)?['text']
                                    as String?,
                          )
                          : null,
                  fieldTranslations:
                      json['homeTeam']?['fieldTranslations'] != null
                          ? FieldTranslationsEntity(
                            nameTranslationAr:
                                ((json['homeTeam']['fieldTranslations']
                                            as Map<
                                              String,
                                              dynamic
                                            >?)?['nameTranslation']
                                        as Map<String, dynamic>?)?['ar']
                                    as String?,
                            shortNameTranslationAr:
                                ((json['homeTeam']['fieldTranslations']
                                            as Map<
                                              String,
                                              dynamic
                                            >?)?['shortNameTranslation']
                                        as Map<String, dynamic>?)?['ar']
                                    as String?,
                          )
                          : null,
                  countryAlpha2:
                      (json['tournament']?['category']
                              as Map<String, dynamic>?)?['alpha2']
                          as String?,
                )
                : null,
        awayTeam:
            json['awayTeam'] != null
                ? TeamStandingEntity(
                  shortName:
                      (json['awayTeam'] as Map<String, dynamic>?)?['shortName']
                          as String?,
                  id:
                      (json['awayTeam'] as Map<String, dynamic>?)?['id']
                          as int?,
                  teamColors:
                      json['awayTeam']?['teamColors'] != null
                          ? TeamColorsEntity(
                            primary:
                                (json['awayTeam']['teamColors']
                                        as Map<String, dynamic>?)?['primary']
                                    as String?,
                            secondary:
                                (json['awayTeam']['teamColors']
                                        as Map<String, dynamic>?)?['secondary']
                                    as String?,
                            text:
                                (json['awayTeam']['teamColors']
                                        as Map<String, dynamic>?)?['text']
                                    as String?,
                          )
                          : null,
                  fieldTranslations:
                      json['awayTeam']?['fieldTranslations'] != null
                          ? FieldTranslationsEntity(
                            nameTranslationAr:
                                ((json['awayTeam']['fieldTranslations']
                                            as Map<
                                              String,
                                              dynamic
                                            >?)?['nameTranslation']
                                        as Map<String, dynamic>?)?['ar']
                                    as String?,
                            shortNameTranslationAr:
                                ((json['awayTeam']['fieldTranslations']
                                            as Map<
                                              String,
                                              dynamic
                                            >?)?['shortNameTranslation']
                                        as Map<String, dynamic>?)?['ar']
                                    as String?,
                          )
                          : null,
                  countryAlpha2:
                      (json['tournament']?['category']
                              as Map<String, dynamic>?)?['alpha2']
                          as String?,
                )
                : null,
        homeScore:
            json['homeScore'] != null
                ? ScoreModel.fromJson(json['homeScore'] as Map<String, dynamic>)
                : null,
        awayScore:
            json['awayScore'] != null
                ? ScoreModel.fromJson(json['awayScore'] as Map<String, dynamic>)
                : null,
        hasXg: json['hasXg'] as bool?,
        // Note: Not in JSON, might be unused
        id: json['id'] as int?,
        startTimestamp: json['startTimestamp'] as int?,
        slug: json['slug'] as String?,
        finalResultOnly: json['finalResultOnly'] as bool?,
        isLive: isLive,
        time:
            json['time'] != null
                ? TimeModel.fromJson(json['time'] as Map<String, dynamic>)
                : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  MatchEventEntity toEntity() {
    return MatchEventEntity(
      tournament: tournament,
      customId: customId,
      status: status?.toEntity(),
      winnerCode: winnerCode,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: homeScore?.toEntity(),
      awayScore: awayScore?.toEntity(),
      hasXg: hasXg,
      id: id,
      startTimestamp: startTimestamp,
      slug: slug,
      finalResultOnly: finalResultOnly,
      isLive: isLive,
      time: time?.toEntity(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournament':
          tournament != null
              ? {'id': tournament!.id, 'name': tournament!.name}
              : null,
      'customId': customId,
      'status': status?.toJson(),
      'winnerCode': winnerCode,
      'homeTeam':
          homeTeam != null
              ? {
                'shortName': homeTeam!.shortName,
                'id': homeTeam!.id,
                'teamColors': homeTeam!.teamColors?.toJson(),
                'fieldTranslations': homeTeam!.fieldTranslations?.toJson(),
                'countryAlpha2': homeTeam!.countryAlpha2,
              }
              : null,
      'awayTeam':
          awayTeam != null
              ? {
                'shortName': awayTeam!.shortName,
                'id': awayTeam!.id,
                'teamColors': awayTeam!.teamColors?.toJson(),
                'fieldTranslations': awayTeam!.fieldTranslations?.toJson(),
                'countryAlpha2': awayTeam!.countryAlpha2,
              }
              : null,
      'homeScore': homeScore?.toJson(),
      'awayScore': awayScore?.toJson(),
      'hasXg': hasXg,
      'id': id,
      'startTimestamp': startTimestamp,
      'slug': slug,
      'finalResultOnly': finalResultOnly,
      'isLive': isLive,
      'time': time?.toJson(),
    };
  }
}

class StatusModel {
  final int? code;
  final String? description;
  final String? type;

  StatusModel({this.code, this.description, this.type});

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      code: json['code'] as int?,
      description: json['description'] as String?,
      type: json['type'] as String?,
    );
  }

  StatusEntity toEntity() {
    return StatusEntity(code: code, description: description, type: type);
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'description': description, 'type': type};
  }
}

class ScoreModel {
  final int? current;
  final int? display;
  final int? period1;
  final int? period2;
  final int? normaltime;

  ScoreModel({
    this.current,
    this.display,
    this.period1,
    this.period2,
    this.normaltime,
  });

  factory ScoreModel.fromJson(Map<String, dynamic> json) {
    return ScoreModel(
      current: json['current'] as int?,
      display: json['display'] as int?,
      period1: json['period1'] as int?,
      period2: json['period2'] as int?,
      normaltime: json['normaltime'] as int?,
    );
  }

  ScoreEntity toEntity() {
    return ScoreEntity(
      current: current,
      display: display,
      period1: period1,
      period2: period2,
      normaltime: normaltime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'display': display,
      'period1': period1,
      'period2': period2,
      'normaltime': normaltime,
    };
  }
}

class TimeModel {
  final int? injuryTime1;
  final int? injuryTime2;
  final int? currentPeriodStartTimestamp;

  TimeModel({
    this.injuryTime1,
    this.injuryTime2,
    this.currentPeriodStartTimestamp,
  });

  factory TimeModel.fromJson(Map<String, dynamic> json) {
    return TimeModel(
      injuryTime1: json['injuryTime1'] as int?,
      injuryTime2: json['injuryTime2'] as int?,
      currentPeriodStartTimestamp: json['currentPeriodStartTimestamp'] as int?,
    );
  }

  TimeEntity toEntity() {
    return TimeEntity(
      injuryTime1: injuryTime1,
      injuryTime2: injuryTime2,
      currentPeriodStartTimestamp: currentPeriodStartTimestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'injuryTime1': injuryTime1,
      'injuryTime2': injuryTime2,
      'currentPeriodStartTimestamp': currentPeriodStartTimestamp,
    };
  }
}

extension TeamStandingEntityExtension on TeamStandingEntity {
  Map<String, dynamic> toJson() {
    return {
      'shortName': shortName,
      'id': id,
      'teamColors': teamColors?.toJson(),
      'fieldTranslations': fieldTranslations?.toJson(),
      'countryAlpha2': countryAlpha2,
    };
  }
}

extension TeamColorsEntityExtension on TeamColorsEntity {
  Map<String, dynamic> toJson() {
    return {'primary': primary, 'secondary': secondary, 'text': text};
  }
}

extension FieldTranslationsEntityExtension on FieldTranslationsEntity {
  Map<String, dynamic> toJson() {
    return {
      'nameTranslation': {'ar': nameTranslationAr},
      'shortNameTranslation': {'ar': shortNameTranslationAr},
    };
  }
}
