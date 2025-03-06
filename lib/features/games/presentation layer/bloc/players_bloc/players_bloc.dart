// players_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/player_entity.dart';
import '../../../domain layer/usecases/get_all_players_infos_use_case.dart';

part 'players_event.dart';
part 'players_state.dart';

class PlayersBloc extends Bloc<PlayersEvent, PlayersState> {
  final GetAllPlayersInfos getAllPlayersInfos;

  PlayersBloc({required this.getAllPlayersInfos}) : super(PlayersInitial()) {
    on<GetAllPlayersEvent>(_handleGetPlayers);
  }

  Future<void> _handleGetPlayers(
    GetAllPlayersEvent event,
    Emitter<PlayersState> emit,
  ) async {
    emit(PlayersLoading());
    final result = await getAllPlayersInfos(event.teamId);
    result.fold(
      (failure) => emit(PlayersError(mapFailureToMessage(failure))),
      (players) => emit(PlayersLoaded(players: players)),
    );
  }
}
