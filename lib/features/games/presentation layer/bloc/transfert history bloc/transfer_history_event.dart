part of 'transfer_history_bloc.dart';

abstract class TransferHistoryEvent {}

class FetchTransferHistory extends TransferHistoryEvent {
  final int playerId;

  FetchTransferHistory(this.playerId);
}
