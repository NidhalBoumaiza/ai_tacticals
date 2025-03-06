part of 'last_year_summary_bloc.dart';

abstract class LastYearSummaryEvent {}

class FetchLastYearSummary extends LastYearSummaryEvent {
  final int playerId;

  FetchLastYearSummary(this.playerId);
}
