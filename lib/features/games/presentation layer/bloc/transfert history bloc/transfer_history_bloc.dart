import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/player_statics_entity.dart';
import '../../../domain layer/usecases/get_transfert_history_use_case.dart';

part 'transfer_history_event.dart';
part 'transfer_history_state.dart';

class TransferHistoryBloc
    extends Bloc<TransferHistoryEvent, TransferHistoryState> {
  final GetTransferHistoryUseCase getTransferHistoryUseCase;

  TransferHistoryBloc({required this.getTransferHistoryUseCase})
    : super(TransferHistoryInitial()) {
    on<FetchTransferHistory>((event, emit) async {
      emit(TransferHistoryLoading());
      final result = await getTransferHistoryUseCase(event.playerId);
      result.fold(
        (failure) =>
            emit(TransferHistoryError(message: mapFailureToMessage(failure))),
        (transfers) => emit(TransferHistoryLoaded(transfers: transfers)),
      );
    });
  }
}
