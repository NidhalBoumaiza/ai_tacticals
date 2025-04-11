import 'package:equatable/equatable.dart';

abstract class ImageLoadingState extends Equatable {
  const ImageLoadingState();

  @override
  List<Object> get props => [];
}

class ImageLoadingInitial extends ImageLoadingState {}

class ImageLoadingIdle extends ImageLoadingState {}

class ImageLoadingInProgress extends ImageLoadingState {
  final Set<String> currentUrls;

  const ImageLoadingInProgress(this.currentUrls);

  @override
  List<Object> get props => [currentUrls];
}