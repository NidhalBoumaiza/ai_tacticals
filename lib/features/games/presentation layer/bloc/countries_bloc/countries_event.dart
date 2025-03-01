part of 'countries_bloc.dart';

@immutable
sealed class CountriesEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class GetAllCountries extends CountriesEvent {}
