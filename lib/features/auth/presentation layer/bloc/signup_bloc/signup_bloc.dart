import 'package:analysis_ai/features/auth/domain%20layer/entities/userEntity.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain layer/usecases/signup_usecase.dart';

part 'signup_event.dart';

part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final SignUpUseCase signup;

  SignupBloc({required this.signup}) : super(SignupInitial()) {
    on<SignupEvent>((event, emit) {});
    on<SignupEventWithAllInfos>(_signupWithAllInfos);
  }

  void _signupWithAllInfos(
    SignupEventWithAllInfos event,
    Emitter<SignupState> emit,
  ) async {
    emit(SignupLoading());
    final failureOrUser = await signup(event.user);
    failureOrUser.fold(
      (failure) => emit(SignupError(message: mapFailureToMessage(failure))),
      (user) => emit(SignupSuccess()),
    );
  }
}
