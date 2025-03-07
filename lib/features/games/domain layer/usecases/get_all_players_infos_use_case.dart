import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/player_entity.dart';
import '../repositories/players_repository.dart';

class GetAllPlayersInfos {
  final PlayersRepository playerRepository;

  GetAllPlayersInfos(this.playerRepository);

  Future<Either<Failure, List<PlayerEntityy>>> call(int teamId) async {
    return await playerRepository.getAllPlayersInfos(teamId);
  }
}
