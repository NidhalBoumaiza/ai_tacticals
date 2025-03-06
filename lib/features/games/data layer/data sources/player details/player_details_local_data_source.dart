// features/players/data_layer/data_sources/player_details_local_data_source.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../domain layer/entities/player_statics_entity.dart';
import '../../models/player_statics_model.dart';

abstract class PlayerDetailsLocalDataSource {
  Future<void> cachePlayerAttributes(
    PlayerAttributesEntity attributes,
    int playerId,
  );

  Future<PlayerAttributesEntity> getCachedPlayerAttributes(int playerId);

  Future<void> cacheNationalTeamStats(NationalTeamEntity stats, int playerId);

  Future<NationalTeamEntity> getCachedNationalTeamStats(int playerId);

  Future<void> cacheLastYearSummary(
    List<MatchPerformanceEntity> summary,
    int playerId,
  );

  Future<List<MatchPerformanceEntity>> getCachedLastYearSummary(int playerId);

  Future<void> cacheTransferHistory(
    List<TransferEntity> transfers,
    int playerId,
  );

  Future<List<TransferEntity>> getCachedTransferHistory(int playerId);

  Future<void> cacheMedia(List<MediaEntity> media, int playerId);

  Future<List<MediaEntity>> getCachedMedia(int playerId);
}

class PlayerDetailsLocalDataSourceImpl implements PlayerDetailsLocalDataSource {
  static const String _prefix = 'player_';
  static const String _attributesKey = '${_prefix}attributes_';
  static const String _nationalTeamKey = '${_prefix}national_team_';
  static const String _lastYearSummaryKey = '${_prefix}last_year_summary_';
  static const String _transferHistoryKey = '${_prefix}transfer_history_';
  static const String _mediaKey = '${_prefix}media_';

  @override
  Future<void> cachePlayerAttributes(
    PlayerAttributesEntity attributes,
    int playerId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert PlayerAttributesEntity to PlayerAttributesModel manually
    final model = PlayerAttributesModel(
      averageAttributes:
          attributes.averageAttributes
              ?.map(
                (e) => PlayerAttributeModel(
                  attacking: e.attacking,
                  technical: e.technical,
                  tactical: e.tactical,
                  defending: e.defending,
                  creativity: e.creativity,
                  position: e.position,
                  yearShift: e.yearShift,
                  id: e.id,
                ),
              )
              .toList(),
      playerAttributes:
          attributes.playerAttributes
              ?.map(
                (e) => PlayerAttributeModel(
                  attacking: e.attacking,
                  technical: e.technical,
                  tactical: e.tactical,
                  defending: e.defending,
                  creativity: e.creativity,
                  position: e.position,
                  yearShift: e.yearShift,
                  id: e.id,
                ),
              )
              .toList(),
    );
    final jsonString = jsonEncode(model.toJson());
    await prefs.setString('$_attributesKey$playerId', jsonString);
  }

  @override
  Future<PlayerAttributesEntity> getCachedPlayerAttributes(int playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_attributesKey$playerId');
    if (jsonString == null) {
      throw EmptyCacheException("Empty cache exception");
    }
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final model = PlayerAttributesModel.fromJson(jsonMap);
    return PlayerAttributesEntity(
      averageAttributes:
          model.averageAttributes
              ?.map(
                (m) => PlayerAttributeEntity(
                  attacking: m.attacking,
                  technical: m.technical,
                  tactical: m.tactical,
                  defending: m.defending,
                  creativity: m.creativity,
                  position: m.position,
                  yearShift: m.yearShift,
                  id: m.id,
                ),
              )
              .toList(),
      playerAttributes:
          model.playerAttributes
              ?.map(
                (m) => PlayerAttributeEntity(
                  attacking: m.attacking,
                  technical: m.technical,
                  tactical: m.tactical,
                  defending: m.defending,
                  creativity: m.creativity,
                  position: m.position,
                  yearShift: m.yearShift,
                  id: m.id,
                ),
              )
              .toList(),
    );
  }

  @override
  Future<void> cacheNationalTeamStats(
    NationalTeamEntity stats,
    int playerId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert NationalTeamEntity to NationalTeamModel manually
    final model = NationalTeamModel(
      team:
          stats.team != null
              ? TeamModel(
                name: stats.team!.name,
                slug: stats.team!.slug,
                shortName: stats.team!.shortName,
                id: stats.team!.id,
                colors:
                    stats.team!.colors != null
                        ? TeamColorsModel(
                          primary: stats.team!.colors!.primary,
                          secondary: stats.team!.colors!.secondary,
                          text: stats.team!.colors!.text,
                        )
                        : null,
              )
              : null,
      appearances: stats.appearances,
      goals: stats.goals,
      debutDate: stats.debutDate,
    );
    final jsonString = jsonEncode(model.toJson());
    await prefs.setString('$_nationalTeamKey$playerId', jsonString);
  }

  @override
  Future<NationalTeamEntity> getCachedNationalTeamStats(int playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_nationalTeamKey$playerId');
    if (jsonString == null) {
      throw EmptyCacheException("Empty cache exception");
    }
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final model = NationalTeamModel.fromJson(jsonMap);
    return NationalTeamEntity(
      team:
          model.team != null
              ? TeamEntity(
                name: model.team!.name,
                slug: model.team!.slug,
                shortName: model.team!.shortName,
                id: model.team!.id,
                colors:
                    model.team!.colors != null
                        ? TeamColorsEntity(
                          primary: model.team!.colors!.primary,
                          secondary: model.team!.colors!.secondary,
                          text: model.team!.colors!.text,
                        )
                        : null,
              )
              : null,
      appearances: model.appearances,
      goals: model.goals,
      debutDate: model.debutDate,
    );
  }

  @override
  Future<void> cacheLastYearSummary(
    List<MatchPerformanceEntity> summary,
    int playerId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final models =
        summary
            .map(
              (entity) => MatchPerformanceModel(
                type: entity.type,
                date: entity.date,
                rating: entity.rating,
                tournamentId: entity.tournamentId,
              ),
            )
            .toList();
    final jsonString = jsonEncode({
      'summary': models.map((m) => m.toJson()).toList(),
    });
    await prefs.setString('$_lastYearSummaryKey$playerId', jsonString);
  }

  @override
  Future<List<MatchPerformanceEntity>> getCachedLastYearSummary(
    int playerId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_lastYearSummaryKey$playerId');
    if (jsonString == null) {
      throw EmptyCacheException("Empty cache exception");
    }
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final summaryList =
        (jsonMap['summary'] as List<dynamic>? ?? [])
            .map(
              (json) =>
                  MatchPerformanceModel.fromJson(json as Map<String, dynamic>),
            )
            .map(
              (model) => MatchPerformanceEntity(
                type: model.type,
                date: model.date,
                rating: model.rating,
                tournamentId: model.tournamentId,
              ),
            )
            .toList();
    return summaryList;
  }

  @override
  Future<void> cacheTransferHistory(
    List<TransferEntity> transfers,
    int playerId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final models =
        transfers
            .map(
              (entity) => TransferModel(
                fromTeam:
                    entity.fromTeam != null
                        ? TeamModel(
                          name: entity.fromTeam!.name,
                          slug: entity.fromTeam!.slug,
                          shortName: entity.fromTeam!.shortName,
                          id: entity.fromTeam!.id,
                          colors:
                              entity.fromTeam!.colors != null
                                  ? TeamColorsModel(
                                    primary: entity.fromTeam!.colors!.primary,
                                    secondary:
                                        entity.fromTeam!.colors!.secondary,
                                    text: entity.fromTeam!.colors!.text,
                                  )
                                  : null,
                        )
                        : null,
                toTeam:
                    entity.toTeam != null
                        ? TeamModel(
                          name: entity.toTeam!.name,
                          slug: entity.toTeam!.slug,
                          shortName: entity.toTeam!.shortName,
                          id: entity.toTeam!.id,
                          colors:
                              entity.toTeam!.colors != null
                                  ? TeamColorsModel(
                                    primary: entity.toTeam!.colors!.primary,
                                    secondary: entity.toTeam!.colors!.secondary,
                                    text: entity.toTeam!.colors!.text,
                                  )
                                  : null,
                        )
                        : null,
                fee: entity.fee,
                currency: entity.currency,
                date: entity.date,
              ),
            )
            .toList();
    final jsonString = jsonEncode({
      'transferHistory': models.map((m) => m.toJson()).toList(),
    });
    await prefs.setString('$_transferHistoryKey$playerId', jsonString);
  }

  @override
  Future<List<TransferEntity>> getCachedTransferHistory(int playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_transferHistoryKey$playerId');
    if (jsonString == null) {
      throw EmptyCacheException("Empty cache exception");
    }
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final transferList =
        (jsonMap['transferHistory'] as List<dynamic>? ?? [])
            .map((json) => TransferModel.fromJson(json as Map<String, dynamic>))
            .map(
              (model) => TransferEntity(
                fromTeam:
                    model.fromTeam != null
                        ? TeamEntity(
                          name: model.fromTeam!.name,
                          slug: model.fromTeam!.slug,
                          shortName: model.fromTeam!.shortName,
                          id: model.fromTeam!.id,
                          colors:
                              model.fromTeam!.colors != null
                                  ? TeamColorsEntity(
                                    primary: model.fromTeam!.colors!.primary,
                                    secondary:
                                        model.fromTeam!.colors!.secondary,
                                    text: model.fromTeam!.colors!.text,
                                  )
                                  : null,
                        )
                        : null,
                toTeam:
                    model.toTeam != null
                        ? TeamEntity(
                          name: model.toTeam!.name,
                          slug: model.toTeam!.slug,
                          shortName: model.toTeam!.shortName,
                          id: model.toTeam!.id,
                          colors:
                              model.toTeam!.colors != null
                                  ? TeamColorsEntity(
                                    primary: model.toTeam!.colors!.primary,
                                    secondary: model.toTeam!.colors!.secondary,
                                    text: model.toTeam!.colors!.text,
                                  )
                                  : null,
                        )
                        : null,
                fee: model.fee,
                currency: model.currency,
                date: model.date,
              ),
            )
            .toList();
    return transferList;
  }

  @override
  Future<void> cacheMedia(List<MediaEntity> media, int playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final models =
        media
            .map(
              (entity) => MediaModel(
                title: entity.title,
                url: entity.url,
                thumbnailUrl: entity.thumbnailUrl,
                createdAt: entity.createdAt,
              ),
            )
            .toList();
    final jsonString = jsonEncode({
      'media': models.map((m) => m.toJson()).toList(),
    });
    await prefs.setString('$_mediaKey$playerId', jsonString);
  }

  @override
  Future<List<MediaEntity>> getCachedMedia(int playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_mediaKey$playerId');
    if (jsonString == null) {
      throw EmptyCacheException("Empty cache exception");
    }
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final mediaList =
        (jsonMap['media'] as List<dynamic>? ?? [])
            .map((json) => MediaModel.fromJson(json as Map<String, dynamic>))
            .map(
              (model) => MediaEntity(
                title: model.title,
                url: model.url,
                thumbnailUrl: model.thumbnailUrl,
                createdAt: model.createdAt,
              ),
            )
            .toList();
    return mediaList;
  }
}
