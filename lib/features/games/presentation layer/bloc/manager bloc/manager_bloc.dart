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
  final Map<int, Map<String, ManagerEntity?>> _managersCache = {};

  ManagerBloc({required this.repository}) : super(ManagerInitial()) {
    on<GetManagers>(_getManagers);
  }

  Future<void> _getManagers(
    GetManagers event,
    Emitter<ManagerState> emit,
  ) async {
    // Check cache first
    if (_managersCache.containsKey(event.matchId)) {
      final cachedManagers = _managersCache[event.matchId]!;
      // Filter out null values and cast to non-nullable type
      final nonNullManagers = <String, ManagerEntity>{
        for (var entry in cachedManagers.entries)
          if (entry.value != null) entry.key: entry.value!,
      };
      emit(ManagerSuccess(managers: nonNullManagers));
      return;
    }

    emit(ManagerLoading());
    final failureOrManagers = await repository.getManagersPerMatch(
      event.matchId,
    );
    failureOrManagers.fold(
      (failure) => emit(ManagerError(message: mapFailureToMessage(failure))),
      (managers) {
        _managersCache[event.matchId] = managers;
        // Filter out null values for emission
        final nonNullManagers = <String, ManagerEntity>{
          for (var entry in managers.entries)
            if (entry.value != null) entry.key: entry.value!,
        };
        emit(ManagerSuccess(managers: nonNullManagers));
      },
    );
  }

  bool isMatchCached(int matchId) => _managersCache.containsKey(matchId);

  Map<String, ManagerEntity?>? getCachedManagers(int matchId) =>
      _managersCache[matchId];
}
