// lib/features/standings/presentation_layer/bloc/standings_bloc.dart
import 'package:analysis_ai/core/utils/map_failure_to_message.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain layer/entities/standing_entity.dart';
import '../../../domain layer/usecases/get_standing_use_case.dart';

part 'standing_event.dart';
part 'standing_state.dart';

class StandingBloc extends Bloc<StandingEvent, StandingsState> {
  final GetStandingsUseCase getStandings;

  StandingBloc({required this.getStandings}) : super(StandingsInitial()) {
    on<StandingEvent>((event, emit) {});
    on<GetStanding>(_getStandings);
  }

  void _getStandings(GetStanding event, Emitter<StandingsState> emit) async {
    emit(StandingsLoading());
    final failureOrStandings = await getStandings(
      event.leagueId,
      event.seasonId,
    );
    failureOrStandings.fold(
      (failure) => emit(StandingsError(message: mapFailureToMessage(failure))),
      (standings) => emit(StandingsSuccess(standings: standings)),
    );
  }
}
