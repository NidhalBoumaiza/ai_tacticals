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
  final Map<String, StandingsEntity> _standingsCache = {};

  StandingBloc({required this.getStandings}) : super(StandingsInitial()) {
    on<GetStanding>(_getStandings);
  }

  Future<void> _getStandings(
    GetStanding event,
    Emitter<StandingsState> emit,
  ) async {
    // Create a unique key for this leagueId and seasonId combination
    final cacheKey = '${event.leagueId}_${event.seasonId}';

    // Check cache first
    if (_standingsCache.containsKey(cacheKey)) {
      emit(StandingsSuccess(standings: _standingsCache[cacheKey]!));
      return;
    }

    emit(StandingsLoading());
    final failureOrStandings = await getStandings(
      event.leagueId,
      event.seasonId,
    );
    failureOrStandings.fold(
      (failure) => emit(StandingsError(message: mapFailureToMessage(failure))),
      (standings) {
        _standingsCache[cacheKey] = standings;
        emit(StandingsSuccess(standings: standings));
      },
    );
  }

  bool isStandingCached(int leagueId, int seasonId) {
    return _standingsCache.containsKey('${leagueId}_$seasonId');
  }

  StandingsEntity? getCachedStanding(int leagueId, int seasonId) {
    return _standingsCache['${leagueId}_$seasonId'];
  }
}
