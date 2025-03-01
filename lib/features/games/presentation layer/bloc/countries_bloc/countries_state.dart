part of 'countries_bloc.dart';

@immutable
sealed class CountriesState extends Equatable {
  @override
  List<Object> get props => [];
}

final class CountriesInitial extends CountriesState {}

final class CountriesLoading extends CountriesState {}

final class CountriesSuccess extends CountriesState {
  final List<CountryEntity> countries;

  CountriesSuccess({required this.countries});

  @override
  List<Object> get props => [countries];
}

final class CountriesError extends CountriesState {
  final String message;

  CountriesError({required this.message});

  @override
  List<Object> get props => [message];
}
