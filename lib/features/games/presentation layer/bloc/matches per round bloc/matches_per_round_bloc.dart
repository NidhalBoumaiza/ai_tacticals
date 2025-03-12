// lib/features/games/presentation/bloc/matches_per_round_bloc/matches_per_round_bloc.dart
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

  MatchesPerRoundBloc({required this.getMatchesPerRound})
    : super(MatchesPerRoundInitial()) {
    on<FetchMatchesPerRound>(_onFetchMatchesPerRound);
  }

  Future<void> _onFetchMatchesPerRound(
    FetchMatchesPerRound event,
    Emitter<MatchesPerRoundState> emit,
  ) async {
    print(
      'Fetching matches: leagueId=${event.leagueId}, seasonId=${event.seasonId}, round=${event.round}',
    );

    if (state is MatchesPerRoundInitial || event.isRefresh) {
      print('Emitting MatchesPerRoundLoading');
      emit(MatchesPerRoundLoading());
    } else if (state is MatchesPerRoundLoaded) {
      final currentState = state as MatchesPerRoundLoaded;
      print('Setting isLoadingMore to true for round ${event.round}');
      emit(currentState.copyWith(isLoadingMore: true));
    }

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
}
