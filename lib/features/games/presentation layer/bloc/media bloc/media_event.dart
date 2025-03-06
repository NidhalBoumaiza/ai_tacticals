part of 'media_bloc.dart';

abstract class MediaEvent {}

class FetchMedia extends MediaEvent {
  final int playerId;

  FetchMedia(this.playerId);
}
