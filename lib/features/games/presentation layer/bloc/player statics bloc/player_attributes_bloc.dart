// features/players/presentation/bloc/player_attributes/player_attributes_bloc.dart
import 'package:analysis_ai/core/error/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain layer/entities/player_statics_entity.dart';
import '../../../domain layer/usecases/get_player_attributes_use_case.dart';

part 'player_attributes_event.dart';
part 'player_attributes_state.dart';

class PlayerAttributesBloc
    extends Bloc<PlayerAttributesEvent, PlayerAttributesState> {
  final GetPlayerAttributesUseCase getPlayerAttributesUseCase;

  PlayerAttributesBloc({required this.getPlayerAttributesUseCase})
    : super(PlayerAttributesInitial()) {
    on<FetchPlayerAttributes>((event, emit) async {
      emit(PlayerAttributesLoading());
      final result = await getPlayerAttributesUseCase(event.playerId);
      result.fold(
        (failure) =>
            emit(PlayerAttributesError(message: _mapFailureToMessage(failure))),
        (attributes) => emit(PlayerAttributesLoaded(attributes: attributes)),
      );
    });
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case OfflineFailure:
        return 'No internet connection';
      default:
        return 'Unexpected error';
    }
  }
}
