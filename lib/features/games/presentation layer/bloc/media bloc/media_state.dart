part of 'media_bloc.dart';

abstract class MediaState {}

class MediaInitial extends MediaState {}

class MediaLoading extends MediaState {}

class MediaLoaded extends MediaState {
  final List<MediaEntity> media;

  MediaLoaded({required this.media});
}

class MediaError extends MediaState {
  final String message;

  MediaError({required this.message});
}
