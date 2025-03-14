import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../data layer/models/one_match_statics_entity.dart';
import '../../../domain layer/usecases/get_match_details_use_case.dart';

part 'match_details_event.dart';
part 'match_details_state.dart';

class MatchDetailsBloc extends Bloc<MatchDetailsEvent, MatchDetailsState> {
  final GetMatchDetailsUseCase getMatchDetailsUseCase;
  final Map<int, MatchDetails> _matchDetailsCache = {};

  MatchDetailsBloc({required this.getMatchDetailsUseCase})
    : super(MatchDetailsInitial()) {
    on<GetMatchDetailsEvent>(_handleGetMatchDetails);
  }

  Future<void> _handleGetMatchDetails(
    GetMatchDetailsEvent event,
    Emitter<MatchDetailsState> emit,
  ) async {
    // Always check cache first
    if (_matchDetailsCache.containsKey(event.matchId)) {
      emit(
        MatchDetailsLoaded(matchDetails: _matchDetailsCache[event.matchId]!),
      );
      return;
    }

    // Only emit loading if we need to fetch
    emit(MatchDetailsLoading());
    final result = await getMatchDetailsUseCase(event.matchId);
    result.fold(
      (failure) => emit(MatchDetailsError(mapFailureToMessage(failure))),
      (matchDetails) {
        _matchDetailsCache[event.matchId] = matchDetails;
        emit(MatchDetailsLoaded(matchDetails: matchDetails));
      },
    );
  }

  // Add method to check if match is cached
  bool isMatchCached(int matchId) => _matchDetailsCache.containsKey(matchId);

  // Add method to get cached match directly
  MatchDetails? getCachedMatch(int matchId) => _matchDetailsCache[matchId];
}
