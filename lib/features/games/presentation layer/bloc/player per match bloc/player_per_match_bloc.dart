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
  final Map<int, Map<String, List<PlayerPerMatchEntity>>> _playersCache = {};

  PlayerPerMatchBloc({required this.repository})
    : super(PlayerPerMatchInitial()) {
    on<GetPlayersPerMatch>(_handleGetPlayersPerMatch);
  }

  Future<void> _handleGetPlayersPerMatch(
    GetPlayersPerMatch event,
    Emitter<PlayerPerMatchState> emit,
  ) async {
    // Check cache first
    if (_playersCache.containsKey(event.matchId)) {
      emit(PlayerPerMatchSuccess(players: _playersCache[event.matchId]!));
      return;
    }

    emit(PlayerPerMatchLoading());
    final failureOrPlayers = await repository.getPlayersPerMatch(event.matchId);
    failureOrPlayers.fold(
      (failure) =>
          emit(PlayerPerMatchError(message: mapFailureToMessage(failure))),
      (players) {
        _playersCache[event.matchId] = players;
        emit(PlayerPerMatchSuccess(players: players));
      },
    );
  }

  bool isMatchCached(int matchId) => _playersCache.containsKey(matchId);

  Map<String, List<PlayerPerMatchEntity>>? getCachedPlayers(int matchId) =>
      _playersCache[matchId];
}
