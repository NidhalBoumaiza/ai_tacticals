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
  }

  Future<void> _onFetchMatchesPerRound(
    FetchMatchesPerRound event,
    Emitter<MatchesPerRoundState> emit,
  ) async {
    // Create a unique key for this leagueId and seasonId combination
    final cacheKey = '${event.leagueId}_${event.seasonId}';

    // Ensure cache entry exists
    if (!_matchesCache.containsKey(cacheKey)) {
      _matchesCache[cacheKey] = {};
    }

    // Check if this round is already cached
    if (_matchesCache[cacheKey]!.containsKey(event.round) && !event.isRefresh) {
      if (state is MatchesPerRoundLoaded) {
        final currentState = state as MatchesPerRoundLoaded;
        final updatedMatches = Map<int, List<MatchEventEntity>>.from(
          currentState.matches,
        );
        updatedMatches[event.round] = _matchesCache[cacheKey]![event.round]!;
        emit(
          currentState.copyWith(
            matches: updatedMatches,
            currentRound: event.round,
            isLoadingMore: false,
          ),
        );
      } else {
        emit(
          MatchesPerRoundLoaded(
            matches: {event.round: _matchesCache[cacheKey]![event.round]!},
            currentRound: event.round,
            isLoadingMore: false,
          ),
        );
      }
      return;
    }

    // Emit loading state
    if (state is MatchesPerRoundInitial || event.isRefresh) {
      emit(MatchesPerRoundLoading());
    } else if (state is MatchesPerRoundLoaded) {
      final currentState = state as MatchesPerRoundLoaded;
      emit(currentState.copyWith(isLoadingMore: true));
    }

    // Fetch matches
    final result = await getMatchesPerRound(
      leagueId: event.leagueId,
      seasonId: event.seasonId,
      round: event.round,
    );

    result.fold(
      (failure) {
        emit(MatchesPerRoundError(message: mapFailureToMessage(failure)));
      },
      (matches) {
        try {
          // Cache the fetched matches
          _matchesCache[cacheKey]![event.round] = matches;

          if (state is MatchesPerRoundLoading ||
              state is MatchesPerRoundInitial ||
              event.isRefresh) {
            emit(
              MatchesPerRoundLoaded(
                matches: {event.round: matches},
                currentRound: event.round,
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
                currentRound: event.round,
                isLoadingMore: false,
              ),
            );
          }
        } catch (e) {
          emit(MatchesPerRoundError(message: 'Failed to update state: $e'));
        }
      },
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
