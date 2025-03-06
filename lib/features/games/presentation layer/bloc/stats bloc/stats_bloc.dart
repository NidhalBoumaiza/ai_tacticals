import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/statics_entity.dart';
import '../../../domain layer/repositories/statics_repository.dart';

part 'stats_event.dart';
part 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StaticsRepository repository;

  StatsBloc({required this.repository}) : super(StatsInitial()) {
    on<GetStats>(_onGetStats);
  }

  Future<void> _onGetStats(GetStats event, Emitter<StatsState> emit) async {
    emit(StatsLoading());
    final failureOrStats = await repository.getTeamStats(
      event.teamId,
      event.tournamentId,
      event.seasonId,
    );

    failureOrStats.fold(
      (failure) => emit(StatsError(mapFailureToMessage(failure))),
      (stats) => emit(StatsLoaded(stats)),
    );
  }
}
