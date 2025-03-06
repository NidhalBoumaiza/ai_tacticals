part of 'last_year_summary_bloc.dart';

abstract class LastYearSummaryState {}

class LastYearSummaryInitial extends LastYearSummaryState {}

class LastYearSummaryLoading extends LastYearSummaryState {}

class LastYearSummaryLoaded extends LastYearSummaryState {
  final List<MatchPerformanceEntity> summary;

  LastYearSummaryLoaded({required this.summary});
}

class LastYearSummaryError extends LastYearSummaryState {
  final String message;

  LastYearSummaryError({required this.message});
}
