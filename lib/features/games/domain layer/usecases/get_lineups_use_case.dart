// // features/games/domain layer/usecases/get_lineups_use_case.dart
// import 'package:dartz/dartz.dart';
//
// import '../../../../core/error/failures.dart';
// import '../entities/lineup_and_manager_entity.dart';
// import '../repositories/one_match_stats_repository.dart';
//
// class GetLineupsUseCase {
//   final OneMatchStatsRepository repository;
//
//   GetLineupsUseCase(this.repository);
//
//   Future<Either<Failure, LineupEntity>> call(int matchId) async {
//     return await repository.getLineups(matchId);
//   }
// }
