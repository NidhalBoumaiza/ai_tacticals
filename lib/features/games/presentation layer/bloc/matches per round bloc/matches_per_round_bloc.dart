import 'package:analysis_ai/core/utils/map_failure_to_message.dart';
import 'package:analysis_ai/features/games/domain layer/entities/matches_entities.dart';
import 'package:analysis_ai/features/games/domain layer/usecases/get_matches_per_round_use_case.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'matches_per_round_event.dart';
part 'matches_per_round_state.dart';

class MatchesPerRoundBloc
    extends Bloc<MatchesPerRoundEvent, MatchesPerRoundState> {
  final GetMatchesPerRound getMatchesPerRound;
  final Map<String, Map<int, List<MatchEventEntity>>> _matchesCache = {};

  MatchesPerRoundBloc({required this.getMatchesPerRound})
    : super(MatchesPerRoundInitial()) {
    on<FetchMatchesPerRound>(_onFetchMatchesPerRound);
    on<FetchCurrentAndNextRounds>(_onFetchCurrentAndNextRounds);
  }

  Future<void> _onFetchMatchesPerRound(
    FetchMatchesPerRound event,
    Emitter<MatchesPerRoundState> emit,
  ) async {
    final cacheKey = '${event.leagueId}_${event.seasonId}';
    if (!_matchesCache.containsKey(cacheKey)) {
      _matchesCache[cacheKey] = {};
    }

    if (_matchesCache[cacheKey]!.containsKey(event.round) && !event.isRefresh) {
      if (state is MatchesPerRoundLoaded) {
        final currentState = state as MatchesPerRoundLoaded;
        final updatedMatches = Map<int, List<MatchEventEntity>>.from(
          currentState.matches,
        );
        updatedMatches[event.round] = _matchesCache[cacheKey]![event.round]!;
        emit(
          currentState.copyWith(matches: updatedMatches, isLoadingMore: false),
        );
      }
      return;
    }

    if (state is MatchesPerRoundInitial || event.isRefresh) {
      emit(MatchesPerRoundLoading());
    } else if (state is MatchesPerRoundLoaded) {
      emit((state as MatchesPerRoundLoaded).copyWith(isLoadingMore: true));
    }

    final result = await getMatchesPerRound(
      leagueId: event.leagueId,
      seasonId: event.seasonId,
      round: event.round,
    );

    result.fold(
      (failure) =>
          emit(MatchesPerRoundError(message: mapFailureToMessage(failure))),
      (matches) {
        _matchesCache[cacheKey]![event.round] = matches;
        if (state is MatchesPerRoundLoading ||
            state is MatchesPerRoundInitial ||
            event.isRefresh) {
          emit(
            MatchesPerRoundLoaded(
              matches: {event.round: matches},
              currentRound: event.round,
              nextRound: event.round + 1,
              isLoadingMore: false,
            ),
          );
        } else if (state is MatchesPerRoundLoaded) {
          final currentState = state as MatchesPerRoundLoaded;
          final updatedMatches = Map<int, List<MatchEventEntity>>.from(
            currentState.matches,
          );
          updatedMatches[event.round] = matches;
          emit(
            currentState.copyWith(
              matches: updatedMatches,
              isLoadingMore: false,
            ),
          );
        }
      },
    );
  }

  Future<void> _onFetchCurrentAndNextRounds(
    FetchCurrentAndNextRounds event,
    Emitter<MatchesPerRoundState> emit,
  ) async {
    final cacheKey = '${event.leagueId}_${event.seasonId}';
    if (!_matchesCache.containsKey(cacheKey)) {
      _matchesCache[cacheKey] = {};
    }

    emit(MatchesPerRoundLoading());
    int round = 1;
    int? currentRound;
    int? nextRound;
    final currentTimestamp =
        DateTime.now().millisecondsSinceEpoch ~/
        1000; // Current time in seconds

    // Iterate to find the current and next rounds
    while (round <= 38) {
      List<MatchEventEntity> matches;
      if (_matchesCache[cacheKey]!.containsKey(round)) {
        matches = _matchesCache[cacheKey]![round]!;
      } else {
        final result = await getMatchesPerRound(
          leagueId: event.leagueId,
          seasonId: event.seasonId,
          round: round,
        );

        if (result.isLeft()) {
          emit(
            MatchesPerRoundError(
              message: mapFailureToMessage(result.fold((l) => l, (_) => null)!),
            ),
          );
          return;
        }

        matches = result.getOrElse(() => []);
        _matchesCache[cacheKey]![round] = matches;
      }

      if (matches.isNotEmpty) {
        // Check the first two matches (if available)
        final firstMatch = matches[0];
        final secondMatch = matches.length > 1 ? matches[1] : null;

        bool isFirstMatchPlayed =
            firstMatch.startTimestamp != null &&
            firstMatch.startTimestamp! < currentTimestamp &&
            firstMatch.homeScore?.current != null &&
            firstMatch.awayScore?.current != null;

        bool isSecondMatchPlayed =
            secondMatch != null &&
            secondMatch.startTimestamp != null &&
            secondMatch.startTimestamp! < currentTimestamp &&
            secondMatch.homeScore?.current != null &&
            secondMatch.awayScore?.current != null;

        if (secondMatch != null) {}

        // Check if the entire round is played
        bool allPlayed = matches.every(
          (match) =>
              match.startTimestamp != null &&
              match.startTimestamp! < currentTimestamp &&
              match.homeScore?.current != null &&
              match.awayScore?.current != null,
        );

        // Check if there are any unplayed matches in the round
        bool hasUnplayed = matches.any(
          (match) =>
              match.startTimestamp != null &&
              match.startTimestamp! > currentTimestamp &&
              (match.homeScore?.current == null ||
                  match.awayScore?.current == null),
        );

        if (allPlayed && !hasUnplayed) {
          currentRound = round;
          print('Updated current round to $currentRound (all matches played)');
        } else if (hasUnplayed && currentRound != null) {
          nextRound = round;
          // Keep all matches (played and unplayed) for the next round
          print(
            'Found next round at $nextRound with ${matches.length} matches (including played)',
          );
          break;
        }
      } else {
        print('No matches found for round $round, continuing...');
      }

      round++;
    }

    if (round > 38) {
      print('Exceeded 38 rounds, no valid rounds found');
      emit(
        MatchesPerRoundError(
          message: 'Could not determine rounds after 38 attempts',
        ),
      );
      return;
    }

    if (currentRound == null || nextRound == null) {
      print(
        'No valid current or next round found - current: $currentRound, next: $nextRound',
      );
      emit(MatchesPerRoundError(message: 'No valid rounds found'));
      return;
    }

    final matchesToDisplay = {
      currentRound: _matchesCache[cacheKey]![currentRound] ?? [],
      nextRound: _matchesCache[cacheKey]![nextRound] ?? [],
    };

    emit(
      MatchesPerRoundLoaded(
        matches: matchesToDisplay,
        currentRound: currentRound,
        nextRound: nextRound,
        isLoadingMore: false,
      ),
    );
  }

  bool isRoundCached(int leagueId, int seasonId, int round) {
    final cacheKey = '${leagueId}_$seasonId';
    return _matchesCache.containsKey(cacheKey) &&
        _matchesCache[cacheKey]!.containsKey(round);
  }

  Map<int, List<MatchEventEntity>>? getCachedMatches(
    int leagueId,
    int seasonId,
  ) {
    final cacheKey = '${leagueId}_$seasonId';
    return _matchesCache[cacheKey];
  }
}
