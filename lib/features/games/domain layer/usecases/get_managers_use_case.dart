// // features/games/domain layer/usecases/get_managers_use_case.dart
// import 'package:dartz/dartz.dart';
//
// import '../../../../core/error/failures.dart';
// import '../entities/lineup_and_manager_entity.dart';
// import '../repositories/one_match_stats_repository.dart';
//
// class GetManagersUseCase {
//   final OneMatchStatsRepository repository;
//
//   GetManagersUseCase(this.repository);
//
//   Future<Either<Failure, ManagerEntity>> call(int matchId) async {
//     return await repository.getManagers(matchId);
//   }
// }
