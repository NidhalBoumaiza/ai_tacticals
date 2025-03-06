// features/players/domain/usecases/get_transfer_history_usecase.dart
import 'package:analysis_ai/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/player_statics_entity.dart';
import '../repositories/player_details_repository.dart';

class GetTransferHistoryUseCase {
  final PlayerDetailsRepository repository;

  GetTransferHistoryUseCase(this.repository);

  Future<Either<Failure, List<TransferEntity>>> call(int playerId) async {
    return await repository.getTransferHistory(playerId);
  }
}
