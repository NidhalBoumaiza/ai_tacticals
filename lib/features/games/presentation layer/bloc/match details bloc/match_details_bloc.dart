// match_details_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../data layer/models/one_match_statics_entity.dart';
import '../../../domain layer/usecases/get_match_details_use_case.dart';


part 'match_details_event.dart';
part 'match_details_state.dart';

class MatchDetailsBloc extends Bloc<MatchDetailsEvent, MatchDetailsState> {
  final GetMatchDetailsUseCase getMatchDetailsUseCase;

  MatchDetailsBloc({required this.getMatchDetailsUseCase})
      : super(MatchDetailsInitial()) {
    on<GetMatchDetailsEvent>(_handleGetMatchDetails);
  }

  Future<void> _handleGetMatchDetails(
      GetMatchDetailsEvent event,
      Emitter<MatchDetailsState> emit,
      ) async {
    emit(MatchDetailsLoading());
    final result = await getMatchDetailsUseCase(event.matchId);
    result.fold(
          (failure) => emit(MatchDetailsError(mapFailureToMessage(failure))),
          (matchDetails) => emit(MatchDetailsLoaded(matchDetails: matchDetails)),
    );
  }
}