import 'package:analysis_ai/features/games/domain%20layer/entities/season_entity.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../domain layer/usecases/get_season_use_case.dart';

part 'seasons_state.dart';

class SeasonsCubit extends Cubit<SeasonsState> {
  final GetSeasonsUseCase getSeasonsUseCase;

  SeasonsCubit({required this.getSeasonsUseCase}) : super(SeasonsInitial());

  void getSeasons(leagueId) async {
    emit(SeasonsLoading());
    final result = await getSeasonsUseCase(leagueId);
    result.fold(
      (error) => emit(SeasonsError(error.toString())),
      (seasons) => emit(SeasonsLoaded(seasons)),
    );
  }
}
