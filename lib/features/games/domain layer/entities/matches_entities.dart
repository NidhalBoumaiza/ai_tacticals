import 'package:analysis_ai/features/games/domain%20layer/entities/team_standing%20_entity.dart';
import 'package:equatable/equatable.dart';

import 'league_entity.dart';

class MatchEventsPerTeamEntity extends Equatable {
  final Map<String, List<MatchEventEntity>>? tournamentTeamEvents;

  const MatchEventsPerTeamEntity({this.tournamentTeamEvents});

  @override
  List<Object?> get props => [tournamentTeamEvents];
}

class MatchEventEntity {
  final LeagueEntity?
  tournament; // Reusing LeagueEntity instead of TournamentEntity
  final String? customId;
  final StatusEntity? status;
  final int? winnerCode;
  final TeamStandingEntity? homeTeam; // Reusing TeamStandingEntity
  final TeamStandingEntity? awayTeam; // Reusing TeamStandingEntity
  final ScoreEntity? homeScore;
  final ScoreEntity? awayScore;
  final bool? hasXg;
  final int? id;
  final int? startTimestamp;
  final String? slug;
  final bool? finalResultOnly;
  final bool? isLive;
  final TimeEntity? time; // Added TimeEntity field
  final int? seasonId; // Added seasonId
  final int? round; // Added round
  final String? homePrimaryColor; // Added home team primary color
  final String? homeSecondaryColor; // Added home team secondary color
  final String? awayPrimaryColor; // Added away team primary color
  final String? awaySecondaryColor; // Added away team secondary color
  // Computed property to get the current live minutes played
  int? get currentLiveMinutes {
    if (startTimestamp == null || status?.type != "inprogress")
      return null; // Only for live matches
    final now =
        DateTime.now().millisecondsSinceEpoch ~/
        1000; // Current time in seconds
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

  const MatchEventEntity({
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
    this.seasonId,
    this.round,
    this.homePrimaryColor,
    this.homeSecondaryColor,
    this.awayPrimaryColor,
    this.awaySecondaryColor,
  });
}

class StatusEntity {
  final int? code;
  final String? description;
  final String? type;

  const StatusEntity({this.code, this.description, this.type});
}

class ScoreEntity {
  final int? current;
  final int? display;
  final int? period1;
  final int? period2;
  final int? normaltime;

  const ScoreEntity({
    this.current,
    this.display,
    this.period1,
    this.period2,
    this.normaltime,
  });
}

class TimeEntity {
  final int? injuryTime1; // Injury time for first half
  final int? injuryTime2; // Injury time for second half
  final int? currentPeriodStartTimestamp;

  const TimeEntity({
    this.injuryTime1,
    this.injuryTime2,
    this.currentPeriodStartTimestamp,
  });
}
