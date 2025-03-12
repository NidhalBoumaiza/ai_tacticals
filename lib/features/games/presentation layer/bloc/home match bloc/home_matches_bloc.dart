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
    on<FetchLiveMatchUpdates>(
      _onFetchLiveMatchUpdates,
    ); // Add handler for live updates
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

  Future<void> _onFetchLiveMatchUpdates(
    FetchLiveMatchUpdates event,
    Emitter<HomeMatchesState> emit,
  ) async {
    // Only update if already loaded to avoid unnecessary loading states
    if (state is HomeMatchesLoaded) {
      final failureOrMatches = await getHomeMatchesUseCase(event.date);
      failureOrMatches.fold(
        (failure) {
          print('Live update failed: ${mapFailureToMessage(failure)}');
          // Don't emit error state, keep current state
        },
        (matches) {
          emit(HomeMatchesLoaded(matches: matches));
        },
      );
    }
  }
}
