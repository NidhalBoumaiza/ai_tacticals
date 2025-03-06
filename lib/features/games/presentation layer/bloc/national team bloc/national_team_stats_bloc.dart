import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/player_statics_entity.dart';
import '../../../domain layer/usecases/get_national_team_stats_use_case.dart';

part 'national_team_stats_event.dart';
part 'national_team_stats_state.dart';

class NationalTeamStatsBloc
    extends Bloc<NationalTeamStatsEvent, NationalTeamStatsState> {
  final GetNationalTeamStatsUseCase getNationalTeamStatsUseCase;

  NationalTeamStatsBloc({required this.getNationalTeamStatsUseCase})
    : super(NationalTeamStatsInitial()) {
    on<FetchNationalTeamStats>((event, emit) async {
      emit(NationalTeamStatsLoading());
      final result = await getNationalTeamStatsUseCase(event.playerId);
      result.fold(
        (failure) =>
            emit(NationalTeamStatsError(message: mapFailureToMessage(failure))),
        (stats) => emit(NationalTeamStatsLoaded(stats: stats)),
      );
    });
  }
}
