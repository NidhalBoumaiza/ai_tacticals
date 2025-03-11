import 'package:analysis_ai/core/utils/map_failure_to_message.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain layer/entities/matches_entities.dart';
import '../../../domain layer/usecases/get_home_matches_use_case.dart';

part 'home_matches_event.dart';
part 'home_matches_state.dart';

class HomeMatchesBloc extends Bloc<HomeMatchesEvent, HomeMatchesState> {
  final GetHomeMatchesUseCase getHomeMatchesUseCase;

  HomeMatchesBloc({required this.getHomeMatchesUseCase})
    : super(HomeMatchesInitial()) {
    on<FetchHomeMatches>(_onFetchHomeMatches);
  }

  Future<void> _onFetchHomeMatches(
    FetchHomeMatches event,
    Emitter<HomeMatchesState> emit,
  ) async {
    emit(HomeMatchesLoading());

    final failureOrMatches = await getHomeMatchesUseCase(event.date);
    failureOrMatches.fold(
      (failure) {
        final errorMessage = mapFailureToMessage(failure);
        emit(HomeMatchesError(message: errorMessage));
      },
      (matches) {
        emit(HomeMatchesLoaded(matches: matches));
      },
    );
  }
}
