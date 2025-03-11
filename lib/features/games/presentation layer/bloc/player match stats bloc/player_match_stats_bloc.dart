import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/player_entity.dart';
import '../../../domain layer/usecases/get_player_match_stats.dart';

part 'player_match_stats_event.dart';
part 'player_match_stats_state.dart';

class PlayerMatchStatsBloc
    extends Bloc<PlayerMatchStatsEvent, PlayerMatchStatsState> {
  final GetPlayerMatchStats getPlayerMatchStats;

  PlayerMatchStatsBloc({required this.getPlayerMatchStats})
    : super(PlayerMatchStatsInitial()) {
    on<FetchPlayerMatchStats>(_onFetchPlayerMatchStats);
  }

  Future<void> _onFetchPlayerMatchStats(
    FetchPlayerMatchStats event,
    Emitter<PlayerMatchStatsState> emit,
  ) async {
    emit(PlayerMatchStatsLoading());
    final result = await getPlayerMatchStats(
      matchId: event.matchId,
      playerId: event.playerId,
    );
    result.fold(
      (failure) =>
          emit(PlayerMatchStatsError(message: mapFailureToMessage(failure))),
      (playerStats) => emit(PlayerMatchStatsLoaded(playerStats: playerStats)),
    );
  }
}
