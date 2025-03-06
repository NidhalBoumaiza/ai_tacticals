import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/entities/player_statics_entity.dart';
import '../../../domain layer/usecases/get_media_use_case.dart';

part 'media_event.dart';
part 'media_state.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final GetMediaUseCase getMediaUseCase;

  MediaBloc({required this.getMediaUseCase}) : super(MediaInitial()) {
    on<FetchMedia>((event, emit) async {
      emit(MediaLoading());
      final result = await getMediaUseCase(event.playerId);
      result.fold(
        (failure) => emit(MediaError(message: mapFailureToMessage(failure))),
        (media) => emit(MediaLoaded(media: media)),
      );
    });
  }
}
