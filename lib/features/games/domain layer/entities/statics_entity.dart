class StatsEntity {
  final AttackingStats? attacking;
  final DefensiveStats? defensive;
  final PassingStats? passing;
  final DisciplineStats? discipline;
  final SetPieceStats? setPieces;
  final GeneralStats? general;

  const StatsEntity({
    this.attacking,
    this.defensive,
    this.passing,
    this.discipline,
    this.setPieces,
    this.general,
  });
}

class AttackingStats {
  final int? goalsScored;
  final int? shots;
  final int? shotsOnTarget;
  final int? bigChances;

  const AttackingStats({
    this.goalsScored,
    this.shots,
    this.shotsOnTarget,
    this.bigChances,
  });
}

class DefensiveStats {
  final int? goalsConceded;
  final int? tackles;
  final int? interceptions;
  final int? cleanSheets;

  const DefensiveStats({
    this.goalsConceded,
    this.tackles,
    this.interceptions,
    this.cleanSheets,
  });
}

class PassingStats {
  final int? totalPasses;
  final double? passAccuracy;
  final double? crossAccuracy;
  final int? longBalls;

  const PassingStats({
    this.totalPasses,
    this.passAccuracy,
    this.crossAccuracy,
    this.longBalls,
  });
}

class DisciplineStats {
  final int? fouls;
  final int? yellowCards;
  final int? redCards;
  final int? offsides;

  const DisciplineStats({
    this.fouls,
    this.yellowCards,
    this.redCards,
    this.offsides,
  });
}

class SetPieceStats {
  final int? corners;
  final int? freeKicks;
  final int? penaltyGoals;
  final int? penaltiesTaken;

  const SetPieceStats({
    this.corners,
    this.freeKicks,
    this.penaltyGoals,
    this.penaltiesTaken,
  });
}

class GeneralStats {
  final int? matches;
  final double? posession;
  final double? avgRating;

  const GeneralStats({this.matches, this.posession, this.avgRating});
}
