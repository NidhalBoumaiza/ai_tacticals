// player_details_entity.dart
class PlayerDetailsEntity {
  final PlayerAttributesEntity? attributes;
  final NationalTeamEntity? nationalTeam;
  final List<MatchPerformanceEntity>? lastYearSummary;
  final List<TransferEntity>? transfers;
  final List<MediaEntity>? media;

  const PlayerDetailsEntity({
    this.attributes,
    this.nationalTeam,
    this.lastYearSummary,
    this.transfers,
    this.media,
  });
}

class PlayerAttributesEntity {
  final List<PlayerAttributeEntity>? averageAttributes;
  final List<PlayerAttributeEntity>? playerAttributes;

  const PlayerAttributesEntity({this.averageAttributes, this.playerAttributes});
}

class PlayerAttributeEntity {
  final int? attacking;
  final int? technical;
  final int? tactical;
  final int? defending;
  final int? creativity;
  final String? position;
  final int? yearShift;
  final String? id;

  const PlayerAttributeEntity({
    this.attacking,
    this.technical,
    this.tactical,
    this.defending,
    this.creativity,
    this.position,
    this.yearShift,
    this.id,
  });
}

class NationalTeamEntity {
  final TeamEntity? team;
  final int? appearances;
  final int? goals;
  final DateTime? debutDate;

  const NationalTeamEntity({
    this.team,
    this.appearances,
    this.goals,
    this.debutDate,
  });
}

class TeamEntity {
  final String? name;
  final String? slug;
  final String? shortName;
  final int? id;
  final TeamColorsEntity? colors;

  const TeamEntity({
    this.name,
    this.slug,
    this.shortName,
    this.id,
    this.colors,
  });
}

class TeamColorsEntity {
  final String? primary;
  final String? secondary;
  final String? text;

  const TeamColorsEntity({this.primary, this.secondary, this.text});
}

class MatchPerformanceEntity {
  final String? type;
  final DateTime? date;
  final double? rating;
  final int? tournamentId;

  const MatchPerformanceEntity({
    this.type,
    this.date,
    this.rating,
    this.tournamentId,
  });
}

class TransferEntity {
  final TeamEntity? fromTeam;
  final TeamEntity? toTeam;
  final int? fee;
  final String? currency;
  final DateTime? date;

  const TransferEntity({
    this.fromTeam,
    this.toTeam,
    this.fee,
    this.currency,
    this.date,
  });
}

class MediaEntity {
  final String? title;
  final String? url;
  final String? thumbnailUrl;
  final DateTime? createdAt;

  const MediaEntity({this.title, this.url, this.thumbnailUrl, this.createdAt});
}
