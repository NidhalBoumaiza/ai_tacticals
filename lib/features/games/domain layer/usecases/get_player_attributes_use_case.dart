import 'package:analysis_ai/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/player_statics_entity.dart';
import '../repositories/player_details_repository.dart';

class GetPlayerAttributesUseCase {
  final PlayerDetailsRepository repository;

  GetPlayerAttributesUseCase(this.repository);

  Future<Either<Failure, PlayerAttributesEntity>> call(int playerId) async {
    return await repository.getPlayerAttributes(playerId);
  }
}
