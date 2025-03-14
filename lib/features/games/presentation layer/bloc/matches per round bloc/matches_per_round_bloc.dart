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
      print('Using cached matches for round ${event.round}');
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
      print('Emitting MatchesPerRoundLoading');
      emit(MatchesPerRoundLoading());
    } else if (state is MatchesPerRoundLoaded) {
      final currentState = state as MatchesPerRoundLoaded;
      print('Setting isLoadingMore to true for round ${event.round}');
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
        print('Fetch failed: ${mapFailureToMessage(failure)}');
        emit(MatchesPerRoundError(message: mapFailureToMessage(failure)));
      },
      (matches) {
        print(
          'Fetch succeeded: ${matches.length} matches for round ${event.round}',
        );
        try {
          // Cache the fetched matches
          _matchesCache[cacheKey]![event.round] = matches;

          if (state is MatchesPerRoundLoading ||
              state is MatchesPerRoundInitial ||
              event.isRefresh) {
            print(
              'Emitting initial MatchesPerRoundLoaded with round ${event.round}',
            );
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
            print(
              'Emitting updated MatchesPerRoundLoaded with ${updatedMatches.keys.length} rounds',
            );
            emit(
              currentState.copyWith(
                matches: updatedMatches,
                currentRound: event.round,
                isLoadingMore: false,
              ),
            );
          }
        } catch (e) {
          print('Error emitting state: $e');
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
