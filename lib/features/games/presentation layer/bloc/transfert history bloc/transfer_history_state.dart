part of 'transfer_history_bloc.dart';

abstract class TransferHistoryState {}

class TransferHistoryInitial extends TransferHistoryState {}

class TransferHistoryLoading extends TransferHistoryState {}

class TransferHistoryLoaded extends TransferHistoryState {
  final List<TransferEntity> transfers;

  TransferHistoryLoaded({required this.transfers});
}

class TransferHistoryError extends TransferHistoryState {
  final String message;

  TransferHistoryError({required this.message});
}
