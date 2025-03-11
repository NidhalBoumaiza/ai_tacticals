import '../../domain layer/entities/league_entity.dart';
import '../../domain layer/entities/matches_entities.dart';
import '../../domain layer/entities/team_standing _entity.dart';

class MatchEventsPerTeamModel {
  final Map<String, List<MatchEventModel>>? tournamentTeamEvents;
  final List<MatchEventModel>? events;

  MatchEventsPerTeamModel({this.tournamentTeamEvents, this.events});

  factory MatchEventsPerTeamModel.fromJson(Map<String, dynamic> json) {
    print('Parsing MatchEventsPerTeamModel: $json');

    // Handle "tournamentTeamEvents" (Map<String, dynamic>)
    final tournamentTeamEventsData =
        json['tournamentTeamEvents'] as Map<String, dynamic>?;
    Map<String, List<MatchEventModel>>? parsedTournamentTeamEvents;
    if (tournamentTeamEventsData != null) {
      parsedTournamentTeamEvents = {};
      tournamentTeamEventsData.forEach((outerKey, innerMap) {
        print('Processing outer key: $outerKey with value: $innerMap');
        if (innerMap is Map<String, dynamic>) {
          innerMap.forEach((teamId, matchList) {
            print('Mapping team $teamId with match list: $matchList');
            parsedTournamentTeamEvents![teamId] =
                (matchList as List<dynamic>?)?.map((e) {
                  print('Parsing match event: $e');
                  return MatchEventModel.fromJson(e as Map<String, dynamic>);
                }).toList() ??
                [];
          });
        }
      });
    }

    // Handle "events" (List<dynamic>)
    final eventsData = json['events'] as List<dynamic>?;
    List<MatchEventModel>? parsedEvents;
    if (eventsData != null) {
      parsedEvents =
          eventsData.map((e) {
            print('Parsing match event: $e');
            return MatchEventModel.fromJson(e as Map<String, dynamic>);
          }).toList();
    }

    print('Parsed TournamentTeamEvents: $parsedTournamentTeamEvents');
    print('Parsed Events: $parsedEvents');
    return MatchEventsPerTeamModel(
      tournamentTeamEvents: parsedTournamentTeamEvents,
      events: parsedEvents,
    );
  }

  MatchEventsPerTeamEntity toEntity() {
    // If "events" is present, group by team ID (homeTeam or awayTeam) for consistency
    if (events != null && events!.isNotEmpty) {
      final Map<String, List<MatchEventEntity>> groupedByTeam = {};
      for (var match in events!) {
        final homeTeamId = match.homeTeam?.id.toString();
        final awayTeamId = match.awayTeam?.id.toString();
        final matchEntity = match.toEntity();

        if (homeTeamId != null) {
          groupedByTeam.putIfAbsent(homeTeamId, () => []).add(matchEntity);
        }
        if (awayTeamId != null) {
          groupedByTeam.putIfAbsent(awayTeamId, () => []).add(matchEntity);
        }
      }
      return MatchEventsPerTeamEntity(tournamentTeamEvents: groupedByTeam);
    }

    // If "tournamentTeamEvents" is present, convert directly
    return MatchEventsPerTeamEntity(
      tournamentTeamEvents: tournamentTeamEvents?.map(
        (key, value) => MapEntry(key, value.map((e) => e.toEntity()).toList()),
      ),
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
  });

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    print('Parsing MatchEventModel with JSON: $json');
    try {
      return MatchEventModel(
        tournament:
            json['tournament'] != null
                ? LeagueEntity(
                  id:
                      (json['tournament'] as Map<String, dynamic>?)?['id']
                          as int?,
                  name:
                      (json['tournament'] as Map<String, dynamic>?)?['name']
                          as String?,
                )
                : null,
        customId: json['customId'] as String?,
        status:
            json['status'] != null
                ? StatusModel.fromJson(json['status'] as Map<String, dynamic>)
                : null,
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
        id: json['id'] as int?,
        startTimestamp: json['startTimestamp'] as int?,
        slug: json['slug'] as String?,
        finalResultOnly: json['finalResultOnly'] as bool?,
      );
    } catch (e) {
      print('Error in MatchEventModel.fromJson: $e');
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
