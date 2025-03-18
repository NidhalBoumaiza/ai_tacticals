import 'dart:async';

import 'package:analysis_ai/core/utils/map_failure_to_message.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain layer/entities/matches_entities.dart';
import '../../../domain layer/usecases/get_home_matches_use_case.dart';

part 'home_matches_event.dart';
part 'home_matches_state.dart';

class HomeMatchesBloc extends Bloc<HomeMatchesEvent, HomeMatchesState> {
  final GetHomeMatchesUseCase getHomeMatchesUseCase;
  final Map<String, MatchEventsPerTeamEntity> _matchesCache = {};

  HomeMatchesBloc({required this.getHomeMatchesUseCase})
    : super(HomeMatchesInitial()) {
    on<FetchHomeMatches>(_onFetchHomeMatches);
    on<FetchLiveMatchUpdates>(_onFetchLiveMatchUpdates);
  }

  List<MatchEventEntity> _deduplicateMatches(List<MatchEventEntity> matches) {
    final seenIds = <String>{};
    final deduplicated =
        matches.where((match) {
          final compositeId =
              '${match.id}-${match.homeTeam?.id}-${match.awayTeam?.id}-${match.startTimestamp}';
          final added = seenIds.add(compositeId);
          if (!added) {}
          return added;
        }).toList();
    return deduplicated;
  }

  Future<void> _onFetchHomeMatches(
    FetchHomeMatches event,
    Emitter<HomeMatchesState> emit,
  ) async {
    final cacheKey = event.date;

    if (_matchesCache.containsKey(cacheKey)) {
      emit(HomeMatchesLoaded(matches: _matchesCache[cacheKey]!));
      return;
    }

    emit(HomeMatchesLoading());

    final failureOrMatches = await getHomeMatchesUseCase(event.date);
    failureOrMatches.fold(
      (failure) {
        final errorMessage = mapFailureToMessage(failure);
        emit(HomeMatchesError(message: errorMessage));
      },
      (matches) {
        // Deduplicate matches before caching
        final allMatches = <MatchEventEntity>[];
        matches.tournamentTeamEvents?.forEach((teamId, matchList) {
          allMatches.addAll(matchList);
        });
        final deduplicatedMatches = _deduplicateMatches(allMatches);

        // Rebuild tournamentTeamEvents with deduplicated matches
        final deduplicatedEvents = <String, List<MatchEventEntity>>{};
        for (var match in deduplicatedMatches) {
          final homeTeamId = match.homeTeam?.id.toString();
          final awayTeamId = match.awayTeam?.id.toString();
          if (homeTeamId != null) {
            deduplicatedEvents.putIfAbsent(homeTeamId, () => []).add(match);
          }
          if (awayTeamId != null && homeTeamId != awayTeamId) {
            deduplicatedEvents.putIfAbsent(awayTeamId, () => []).add(match);
          }
        }

        final deduplicatedEntity = MatchEventsPerTeamEntity(
          tournamentTeamEvents: deduplicatedEvents,
        );
        _matchesCache[cacheKey] = deduplicatedEntity;
        emit(HomeMatchesLoaded(matches: deduplicatedEntity));
      },
    );
  }

  Future<void> _onFetchLiveMatchUpdates(
    FetchLiveMatchUpdates event,
    Emitter<HomeMatchesState> emit,
  ) async {
    final cacheKey = event.date;

    final failureOrMatches = await getHomeMatchesUseCase(event.date);
    failureOrMatches.fold(
      (failure) {
        // Keep current state if live update fails
      },
      (matches) {
        // Deduplicate matches before caching
        final allMatches = <MatchEventEntity>[];
        matches.tournamentTeamEvents?.forEach((teamId, matchList) {
          allMatches.addAll(matchList);
        });
        final deduplicatedMatches = _deduplicateMatches(allMatches);

        // Rebuild tournamentTeamEvents with deduplicated matches
        final deduplicatedEvents = <String, List<MatchEventEntity>>{};
        for (var match in deduplicatedMatches) {
          final homeTeamId = match.homeTeam?.id.toString();
          final awayTeamId = match.awayTeam?.id.toString();
          if (homeTeamId != null) {
            deduplicatedEvents.putIfAbsent(homeTeamId, () => []).add(match);
          }
          if (awayTeamId != null && homeTeamId != awayTeamId) {
            deduplicatedEvents.putIfAbsent(awayTeamId, () => []).add(match);
          }
        }

        final deduplicatedEntity = MatchEventsPerTeamEntity(
          tournamentTeamEvents: deduplicatedEvents,
        );
        _matchesCache[cacheKey] = deduplicatedEntity;
        emit(HomeMatchesLoaded(matches: deduplicatedEntity));
      },
    );
  }

  bool isDateCached(String date) {
    return _matchesCache.containsKey(date);
  }

  MatchEventsPerTeamEntity? getCachedMatches(String date) {
    return _matchesCache[date];
  }
}
