import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/player_statics_entity.dart';
import '../../../domain layer/usecases/get _last_year_summary_use_case.dart';

part 'last_year_summary_event.dart';
part 'last_year_summary_state.dart';

class LastYearSummaryBloc
    extends Bloc<LastYearSummaryEvent, LastYearSummaryState> {
  final GetLastYearSummaryUseCase getLastYearSummaryUseCase;

  LastYearSummaryBloc({required this.getLastYearSummaryUseCase})
    : super(LastYearSummaryInitial()) {
    on<FetchLastYearSummary>((event, emit) async {
      emit(LastYearSummaryLoading());
      final result = await getLastYearSummaryUseCase(event.playerId);
      result.fold(
        (failure) =>
            emit(LastYearSummaryError(message: mapFailureToMessage(failure))),
        (summary) => emit(LastYearSummaryLoaded(summary: summary)),
      );
    });
  }
}
