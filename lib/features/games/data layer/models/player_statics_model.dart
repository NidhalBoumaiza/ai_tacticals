// player_details_model.dart
import '../../domain layer/entities/player_statics_entity.dart';

class PlayerDetailsModel {
  final PlayerAttributesModel? attributes;
  final NationalTeamModel? nationalTeam;
  final List<MatchPerformanceModel>? lastYearSummary;
  final List<TransferModel>? transfers;
  final List<MediaModel>? media;

  const PlayerDetailsModel({
    this.attributes,
    this.nationalTeam,
    this.lastYearSummary,
    this.transfers,
    this.media,
  });

  factory PlayerDetailsModel.fromJson(Map<String, dynamic> json) =>
      PlayerDetailsModel(
        attributes: _parseAttributes(json['attributeOverviews']),
        nationalTeam: _parseNationalTeam(json['nationalTeamStatistics']),
        lastYearSummary: _parseSummary(json['lastYearSummary']),
        transfers: _parseTransfers(json['transferHistory']),
        media: _parseMedia(json['media']),
      );

  PlayerDetailsEntity toEntity() => PlayerDetailsEntity(
    attributes: attributes?.toEntity(),
    nationalTeam: nationalTeam?.toEntity(),
    lastYearSummary: lastYearSummary?.map((e) => e.toEntity()).toList(),
    transfers: transfers?.map((e) => e.toEntity()).toList(),
    media: media?.map((e) => e.toEntity()).toList(),
  );

  static PlayerAttributesModel? _parseAttributes(Map<String, dynamic>? json) =>
      json != null ? PlayerAttributesModel.fromJson(json) : null;

  static NationalTeamModel? _parseNationalTeam(Map<String, dynamic>? json) =>
      json != null ? NationalTeamModel.fromJson(json) : null;

  static List<MatchPerformanceModel>? _parseSummary(
    Map<String, dynamic>? json,
  ) =>
      (json?['summary'] as List?)
          ?.map((e) => MatchPerformanceModel.fromJson(e))
          .toList();

  static List<TransferModel>? _parseTransfers(Map<String, dynamic>? json) =>
      (json?['transferHistory'] as List?)
          ?.map((e) => TransferModel.fromJson(e))
          .toList();

  static List<MediaModel>? _parseMedia(Map<String, dynamic>? json) =>
      (json?['media'] as List?)?.map((e) => MediaModel.fromJson(e)).toList();

  Map<String, dynamic> toJson() => {
    'attributeOverviews': attributes?.toJson(),
    'nationalTeamStatistics': nationalTeam?.toJson(),
    'lastYearSummary': lastYearSummary?.map((e) => e.toJson()).toList(),
    'transferHistory': transfers?.map((e) => e.toJson()).toList(),
    'media': media?.map((e) => e.toJson()).toList(),
  };
}

class PlayerAttributesModel {
  final List<PlayerAttributeModel>? averageAttributes;
  final List<PlayerAttributeModel>? playerAttributes;

  const PlayerAttributesModel({this.averageAttributes, this.playerAttributes});

  factory PlayerAttributesModel.fromJson(Map<String, dynamic> json) =>
      PlayerAttributesModel(
        averageAttributes: _parseAttributes(json['averageAttributeOverviews']),
        playerAttributes: _parseAttributes(json['playerAttributeOverviews']),
      );

  PlayerAttributesEntity toEntity() => PlayerAttributesEntity(
    averageAttributes: averageAttributes?.map((e) => e.toEntity()).toList(),
    playerAttributes: playerAttributes?.map((e) => e.toEntity()).toList(),
  );

  static List<PlayerAttributeModel>? _parseAttributes(List<dynamic>? list) =>
      list?.map((e) => PlayerAttributeModel.fromJson(e)).toList();

  Map<String, dynamic> toJson() => {
    'averageAttributeOverviews':
        averageAttributes?.map((e) => e.toJson()).toList(),
    'playerAttributeOverviews':
        playerAttributes?.map((e) => e.toJson()).toList(),
  };
}

class PlayerAttributeModel {
  final int? attacking;
  final int? technical;
  final int? tactical;
  final int? defending;
  final int? creativity;
  final String? position;
  final int? yearShift;
  final String? id;

  const PlayerAttributeModel({
    this.attacking,
    this.technical,
    this.tactical,
    this.defending,
    this.creativity,
    this.position,
    this.yearShift,
    this.id,
  });

  factory PlayerAttributeModel.fromJson(Map<String, dynamic> json) =>
      PlayerAttributeModel(
        attacking: json['attacking'] as int?,
        technical: json['technical'] as int?,
        tactical: json['tactical'] as int?,
        defending: json['defending'] as int?,
        creativity: json['creativity'] as int?,
        position: json['position'] as String?,
        yearShift: json['yearShift'] as int?,
        id: json['id']?.toString(),
      );

  PlayerAttributeEntity toEntity() => PlayerAttributeEntity(
    attacking: attacking,
    technical: technical,
    tactical: tactical,
    defending: defending,
    creativity: creativity,
    position: position,
    yearShift: yearShift,
    id: id,
  );

  Map<String, dynamic> toJson() => {
    'attacking': attacking,
    'technical': technical,
    'tactical': tactical,
    'defending': defending,
    'creativity': creativity,
    'position': position,
    'yearShift': yearShift,
    'id': id,
  };
}

class NationalTeamModel {
  final TeamModel? team;
  final int? appearances;
  final int? goals;
  final DateTime? debutDate;

  const NationalTeamModel({
    this.team,
    this.appearances,
    this.goals,
    this.debutDate,
  });

  factory NationalTeamModel.fromJson(Map<String, dynamic> json) =>
      NationalTeamModel(
        team: TeamModel.fromJson(json['statistics']?[0]['team'] ?? {}),
        appearances: json['statistics']?[0]['appearances'] as int?,
        goals: json['statistics']?[0]['goals'] as int?,
        debutDate: _parseDate(json['statistics']?[0]['debutTimestamp']),
      );

  NationalTeamEntity toEntity() => NationalTeamEntity(
    team: team?.toEntity(),
    appearances: appearances,
    goals: goals,
    debutDate: debutDate,
  );

  static DateTime? _parseDate(int? timestamp) =>
      timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
          : null;

  Map<String, dynamic> toJson() => {
    'statistics': [
      {
        'team': team?.toJson(),
        'appearances': appearances,
        'goals': goals,
        'debutTimestamp': debutDate!.millisecondsSinceEpoch ~/ 1000,
      },
    ],
  };
}

class TeamModel {
  final String? name;
  final String? slug;
  final String? shortName;
  final int? id;
  final TeamColorsModel? colors;

  const TeamModel({this.name, this.slug, this.shortName, this.id, this.colors});

  factory TeamModel.fromJson(Map<String, dynamic> json) => TeamModel(
    name: json['name'] as String?,
    slug: json['slug'] as String?,
    shortName: json['shortName'] as String?,
    id: json['id'] as int?,
    colors: TeamColorsModel.fromJson(json['teamColors'] ?? {}),
  );

  TeamEntity toEntity() => TeamEntity(
    name: name,
    slug: slug,
    shortName: shortName,
    id: id,
    colors: colors?.toEntity(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'slug': slug,
    'shortName': shortName,
    'id': id,
    'teamColors': colors?.toJson(),
  };
}

class TeamColorsModel {
  final String? primary;
  final String? secondary;
  final String? text;

  const TeamColorsModel({this.primary, this.secondary, this.text});

  factory TeamColorsModel.fromJson(Map<String, dynamic> json) =>
      TeamColorsModel(
        primary: json['primary'] as String?,
        secondary: json['secondary'] as String?,
        text: json['text'] as String?,
      );

  TeamColorsEntity toEntity() =>
      TeamColorsEntity(primary: primary, secondary: secondary, text: text);

  Map<String, dynamic> toJson() => {
    'primary': primary,
    'secondary': secondary,
    'text': text,
  };
}

class MatchPerformanceModel {
  final String? type;
  final DateTime? date;
  final double? rating;
  final int? tournamentId;

  const MatchPerformanceModel({
    this.type,
    this.date,
    this.rating,
    this.tournamentId,
  });

  factory MatchPerformanceModel.fromJson(Map<String, dynamic> json) =>
      MatchPerformanceModel(
        type: json['type'] as String?,
        date: _parseDate(json['timestamp']),
        rating: (json['value'] as String?)?.tryParseDouble(),
        tournamentId: json['uniqueTournamentId'] as int?,
      );

  MatchPerformanceEntity toEntity() => MatchPerformanceEntity(
    type: type,
    date: date,
    rating: rating,
    tournamentId: tournamentId,
  );

  static DateTime? _parseDate(int? timestamp) =>
      timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
          : null;

  Map<String, dynamic> toJson() => {
    'type': type,
    'timestamp': date!.millisecondsSinceEpoch ~/ 1000,
    'value': rating?.toString(),
    'uniqueTournamentId': tournamentId,
  };
}

class TransferModel {
  final TeamModel? fromTeam;
  final TeamModel? toTeam;
  final int? fee;
  final String? currency;
  final DateTime? date;

  const TransferModel({
    this.fromTeam,
    this.toTeam,
    this.fee,
    this.currency,
    this.date,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) => TransferModel(
    fromTeam: TeamModel.fromJson(json['transferFrom'] ?? {}),
    toTeam: TeamModel.fromJson(json['transferTo'] ?? {}),
    fee: (json['transferFeeRaw'] as Map?)?['value'] as int?,
    currency:
        (json['transferFeeRaw'] as Map?)?.cast<String, dynamic>()['currency']
            as String?,
    date: _parseDate(json['transferDateTimestamp']),
  );

  TransferEntity toEntity() => TransferEntity(
    fromTeam: fromTeam?.toEntity(),
    toTeam: toTeam?.toEntity(),
    fee: fee,
    currency: currency,
    date: date,
  );

  static DateTime? _parseDate(int? timestamp) =>
      timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
          : null;

  Map<String, dynamic> toJson() => {
    'transferFrom': fromTeam?.toJson(),
    'transferTo': toTeam?.toJson(),
    'transferFeeRaw': {'value': fee, 'currency': currency},
    'transferDateTimestamp': date!.millisecondsSinceEpoch ~/ 1000,
  };
}

class MediaModel {
  final String? title;
  final String? url;
  final String? thumbnailUrl;
  final DateTime? createdAt;

  const MediaModel({this.title, this.url, this.thumbnailUrl, this.createdAt});

  factory MediaModel.fromJson(Map<String, dynamic> json) => MediaModel(
    title: json['title'] as String?,
    url: json['url'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    createdAt: _parseDate(json['createdAtTimestamp']),
  );

  MediaEntity toEntity() => MediaEntity(
    title: title,
    url: url,
    thumbnailUrl: thumbnailUrl,
    createdAt: createdAt,
  );

  static DateTime? _parseDate(int? timestamp) =>
      timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
          : null;

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'createdAtTimestamp': createdAt!.millisecondsSinceEpoch ~/ 1000,
  };
}

extension DoubleParsing on String {
  double? tryParseDouble() => double.tryParse(this);
}
