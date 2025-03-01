import 'package:analysis_ai/features/games/domain layer/entities/league_entity.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/usecases/get_leagues_by_country_use_case.dart';

part 'leagues_event.dart';
part 'leagues_state.dart';

class LeaguesBloc extends Bloc<LeaguesEvent, LeaguesState> {
  final GetLeaguesByCountryUseCase getLeaguesByCountry;

  LeaguesBloc({required this.getLeaguesByCountry}) : super(LeaguesInitial()) {
    on<LeaguesEvent>((event, emit) {});
    on<GetLeaguesByCountry>(_getLeaguesByCountry);
  }

  void _getLeaguesByCountry(
    GetLeaguesByCountry event,
    Emitter<LeaguesState> emit,
  ) async {
    emit(LeaguesLoading());
    final failureOrLeagues = await getLeaguesByCountry(event.countryId);
    failureOrLeagues.fold(
      (failure) => emit(LeaguesError(message: mapFailureToMessage(failure))),
      (leagues) => emit(LeaguesSuccess(leagues: leagues)),
    );
  }
}
