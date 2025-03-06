// features/players/domain/usecases/get_media_usecase.dart
import 'package:analysis_ai/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/player_statics_entity.dart';
import '../repositories/player_details_repository.dart';

class GetMediaUseCase {
  final PlayerDetailsRepository repository;

  GetMediaUseCase(this.repository);

  Future<Either<Failure, List<MediaEntity>>> call(int playerId) async {
    return await repository.getMedia(playerId);
  }
}
