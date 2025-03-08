import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/manager_entity.dart';
import '../../../domain layer/repositories/one_match_stats_repository.dart';

part 'manager_event.dart';
part 'manager_state.dart';

class ManagerBloc extends Bloc<ManagerEvent, ManagerState> {
  final OneMatchStatsRepository repository;

  ManagerBloc({required this.repository}) : super(ManagerInitial()) {
    on<ManagerEvent>((event, emit) {});
    on<GetManagers>(_getManagers);
  }

  void _getManagers(GetManagers event, Emitter<ManagerState> emit) async {
    emit(ManagerLoading());
    final failureOrManagers = await repository.getManagersPerMatch(
      event.matchId,
    );
    failureOrManagers.fold(
      (failure) => emit(ManagerError(message: mapFailureToMessage(failure))),
      (managers) => emit(ManagerSuccess(managers: managers)),
    );
  }
}
