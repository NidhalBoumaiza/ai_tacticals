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
  final Map<String, StatsEntity> _statsCache = {};

  StatsBloc({required this.repository}) : super(StatsInitial()) {
    on<GetStats>(_onGetStats);
  }

  Future<void> _onGetStats(GetStats event, Emitter<StatsState> emit) async {
    // Create a unique key for this teamId, tournamentId, and seasonId combination
    final cacheKey = '${event.teamId}_${event.tournamentId}_${event.seasonId}';

    // Check cache first
    if (_statsCache.containsKey(cacheKey)) {
      emit(StatsLoaded(_statsCache[cacheKey]!));
      return;
    }

    emit(StatsLoading());
    final failureOrStats = await repository.getTeamStats(
      event.teamId,
      event.tournamentId,
      event.seasonId,
    );

    failureOrStats.fold(
      (failure) => emit(StatsError(mapFailureToMessage(failure))),
      (stats) {
        _statsCache[cacheKey] = stats;
        emit(StatsLoaded(stats));
      },
    );
  }

  bool isStatsCached(int teamId, int tournamentId, int seasonId) {
    return _statsCache.containsKey('${teamId}_$tournamentId$seasonId');
  }

  StatsEntity? getCachedStats(int teamId, int tournamentId, int seasonId) {
    return _statsCache['${teamId}_$tournamentId$seasonId'];
  }
}
