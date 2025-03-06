import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/matches_entities.dart';
import '../../../domain layer/usecases/get_matches_by_team_use_case.dart';

part 'matches_event.dart';
part 'matches_state.dart';

class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final GetMatchesPerTeam getMatchesPerTeam;

  MatchesBloc({required this.getMatchesPerTeam}) : super(MatchesInitial()) {
    on<GetMatchesEvent>(_onGetMatches);
  }

  Future<void> _onGetMatches(
    GetMatchesEvent event,
    Emitter<MatchesState> emit,
  ) async {
    emit(MatchesLoading());
    final result = await getMatchesPerTeam(
      uniqueTournamentId: event.uniqueTournamentId,
      seasonId: event.seasonId,
    );
    result.fold(
      (failure) => emit(MatchesError(message: mapFailureToMessage(failure))),
      (matches) => emit(MatchesLoaded(matches: matches)),
    );
  }
}
