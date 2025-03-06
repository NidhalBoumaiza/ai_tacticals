import '../../domain layer/entities/statics_entity.dart';

class StatsModel extends StatsEntity {
  const StatsModel({
    super.attacking,
    super.defensive,
    super.passing,
    super.discipline,
    super.setPieces,
    super.general,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'] as Map<String, dynamic>? ?? {};

    return StatsModel(
      attacking: _parseAttackingStats(stats),
      defensive: _parseDefensiveStats(stats),
      passing: _parsePassingStats(stats),
      discipline: _parseDisciplineStats(stats),
      setPieces: _parseSetPieceStats(stats),
      general: _parseGeneralStats(stats),
    );
  }

  @override
  StatsEntity toEntity() => StatsEntity(
    attacking:
        attacking != null
            ? AttackingStats(
              goalsScored: attacking?.goalsScored,
              shots: attacking?.shots,
              shotsOnTarget: attacking?.shotsOnTarget,
              bigChances: attacking?.bigChances,
            )
            : null,
    defensive:
        defensive != null
            ? DefensiveStats(
              goalsConceded: defensive?.goalsConceded,
              tackles: defensive?.tackles,
              interceptions: defensive?.interceptions,
              cleanSheets: defensive?.cleanSheets,
            )
            : null,
    passing:
        passing != null
            ? PassingStats(
              totalPasses: passing?.totalPasses,
              passAccuracy: passing?.passAccuracy,
              crossAccuracy: passing?.crossAccuracy,
              longBalls: passing?.longBalls,
            )
            : null,
    discipline:
        discipline != null
            ? DisciplineStats(
              fouls: discipline?.fouls,
              yellowCards: discipline?.yellowCards,
              redCards: discipline?.redCards,
              offsides: discipline?.offsides,
            )
            : null,
    setPieces:
        setPieces != null
            ? SetPieceStats(
              corners: setPieces?.corners,
              freeKicks: setPieces?.freeKicks,
              penaltyGoals: setPieces?.penaltyGoals,
              penaltiesTaken: setPieces?.penaltiesTaken,
            )
            : null,
    general:
        general != null
            ? GeneralStats(
              matches: general?.matches,
              posession: general?.posession,
              avgRating: general?.avgRating,
            )
            : null,
  );

  Map<String, dynamic> toJson() => {
    'statistics': {
      'attacking': {
        'goalsScored': attacking?.goalsScored,
        'shots': attacking?.shots,
        'shotsOnTarget': attacking?.shotsOnTarget,
        'bigChances': attacking?.bigChances,
      },
      'defensive': {
        'goalsConceded': defensive?.goalsConceded,
        'tackles': defensive?.tackles,
        'interceptions': defensive?.interceptions,
        'cleanSheets': defensive?.cleanSheets,
      },
      'passing': {
        'totalPasses': passing?.totalPasses,
        'passAccuracy': passing?.passAccuracy,
        'crossAccuracy': passing?.crossAccuracy,
        'longBalls': passing?.longBalls,
      },
      'discipline': {
        'fouls': discipline?.fouls,
        'yellowCards': discipline?.yellowCards,
        'redCards': discipline?.redCards,
        'offsides': discipline?.offsides,
      },
      'setPieces': {
        'corners': setPieces?.corners,
        'freeKicks': setPieces?.freeKicks,
        'penaltyGoals': setPieces?.penaltyGoals,
        'penaltiesTaken': setPieces?.penaltiesTaken,
      },
      'general': {
        'matches': general?.matches,
        'possession': general?.posession,
        'avgRating': general?.avgRating,
      },
    },
  };

  // Existing parsing methods remain the same...
  static AttackingStats? _parseAttackingStats(Map<String, dynamic> stats) {
    return AttackingStats(
      goalsScored: stats['goalsScored'] as int?,
      shots: stats['shots'] as int?,
      shotsOnTarget: stats['shotsOnTarget'] as int?,
      bigChances: stats['bigChances'] as int?,
    );
  }

  static DefensiveStats? _parseDefensiveStats(Map<String, dynamic> stats) {
    return DefensiveStats(
      goalsConceded: stats['goalsConceded'] as int?,
      tackles: stats['tackles'] as int?,
      interceptions: stats['interceptions'] as int?,
      cleanSheets: stats['cleanSheets'] as int?,
    );
  }

  static PassingStats? _parsePassingStats(Map<String, dynamic> stats) {
    return PassingStats(
      totalPasses: stats['totalPasses'] as int?,
      passAccuracy: (stats['passAccuracy'] as num?)?.toDouble(),
      crossAccuracy: (stats['crossAccuracy'] as num?)?.toDouble(),
      longBalls: stats['longBalls'] as int?,
    );
  }

  static DisciplineStats? _parseDisciplineStats(Map<String, dynamic> stats) {
    return DisciplineStats(
      fouls: stats['fouls'] as int?,
      yellowCards: stats['yellowCards'] as int?,
      redCards: stats['redCards'] as int?,
      offsides: stats['offsides'] as int?,
    );
  }

  static SetPieceStats? _parseSetPieceStats(Map<String, dynamic> stats) {
    return SetPieceStats(
      corners: stats['corners'] as int?,
      freeKicks: stats['freeKicks'] as int?,
      penaltyGoals: stats['penaltyGoals'] as int?,
      penaltiesTaken: stats['penaltiesTaken'] as int?,
    );
  }

  static GeneralStats? _parseGeneralStats(Map<String, dynamic> stats) {
    return GeneralStats(
      matches: stats['matches'] as int?,
      posession: (stats['possession'] as num?)?.toDouble(),
      avgRating: (stats['avgRating'] as num?)?.toDouble(),
    );
  }
}
