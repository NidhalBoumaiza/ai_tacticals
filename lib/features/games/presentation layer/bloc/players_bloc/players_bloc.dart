import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/player_entity.dart';
import '../../../domain layer/usecases/get_all_players_infos_use_case.dart';

part 'players_event.dart';
part 'players_state.dart';

class PlayersBloc extends Bloc<PlayersEvent, PlayersState> {
  final GetAllPlayersInfos getAllPlayersInfos;
  final Map<int, List<PlayerEntityy>> _playersCache = {};

  PlayersBloc({required this.getAllPlayersInfos}) : super(PlayersInitial()) {
    on<GetAllPlayersEvent>(_handleGetPlayers);
  }

  Future<void> _handleGetPlayers(
    GetAllPlayersEvent event,
    Emitter<PlayersState> emit,
  ) async {
    // Check cache first
    if (_playersCache.containsKey(event.teamId)) {
      emit(PlayersLoaded(players: _playersCache[event.teamId]!));
      return;
    }

    emit(PlayersLoading());
    final result = await getAllPlayersInfos(event.teamId);
    result.fold((failure) => emit(PlayersError(mapFailureToMessage(failure))), (
      players,
    ) {
      _playersCache[event.teamId] = players;
      emit(PlayersLoaded(players: players));
    });
  }

  bool isTeamCached(int teamId) {
    return _playersCache.containsKey(teamId);
  }

  List<PlayerEntityy>? getCachedPlayers(int teamId) {
    return _playersCache[teamId];
  }
}
