import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/player_per_match_entity.dart';
import '../../../domain layer/repositories/one_match_stats_repository.dart';

part 'player_per_match_event.dart';
part 'player_per_match_state.dart';

class PlayerPerMatchBloc
    extends Bloc<PlayerPerMatchEvent, PlayerPerMatchState> {
  final OneMatchStatsRepository repository;

  PlayerPerMatchBloc({required this.repository})
    : super(PlayerPerMatchInitial()) {
    on<GetPlayersPerMatch>(_getPlayersPerMatch);
  }

  void _getPlayersPerMatch(
    GetPlayersPerMatch event,
    Emitter<PlayerPerMatchState> emit,
  ) async {
    emit(PlayerPerMatchLoading());
    final failureOrPlayers = await repository.getPlayersPerMatch(event.matchId);
    failureOrPlayers.fold(
      (failure) =>
          emit(PlayerPerMatchError(message: mapFailureToMessage(failure))),
      (players) {
        final homePlayers =
            players['home'] as List<PlayerPerMatchEntity>? ?? [];
        final awayPlayers =
            players['away'] as List<PlayerPerMatchEntity>? ?? [];
        emit(
          PlayerPerMatchSuccess(
            players: {'home': homePlayers, 'away': awayPlayers},
          ),
        );
      },
    );
  }
}
