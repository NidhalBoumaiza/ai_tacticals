import 'package:analysis_ai/features/games/domain layer/repositories/games_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/country_entity.dart';

part 'countries_event.dart';
part 'countries_state.dart';

class CountriesBloc extends Bloc<CountriesEvent, CountriesState> {
  final GamesRepository gamesRepository;

  CountriesBloc({required this.gamesRepository}) : super(CountriesInitial()) {
    on<CountriesEvent>((event, emit) {});
    on<GetAllCountries>(_getAllCountries);
  }

  void _getAllCountries(
    GetAllCountries event,
    Emitter<CountriesState> emit,
  ) async {
    emit(CountriesLoading());
    final failureOrCountries = await gamesRepository.getAllCountries();
    failureOrCountries.fold(
      (failure) => emit(CountriesError(message: mapFailureToMessage(failure))),
      (countries) => emit(CountriesSuccess(countries: countries)),
    );
  }
}
