import 'package:analysis_ai/features/auth/domain layer/entities/userEntity.dart';
import 'package:analysis_ai/features/auth/domain layer/usecases/login_usecase.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../../core/utils/map_failure_to_message.dart';

part 'login_event.dart';

part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase login;

  LoginBloc({required this.login}) : super(LoginInitial()) {
    on<LoginEvent>((event, emit) {});
    on<LoginWithEmailAndPassword>(_loginWithEmailAndPassword);
  }

  void _loginWithEmailAndPassword(
    LoginWithEmailAndPassword event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    final failureOrUser = await login(event.email, event.password);
    failureOrUser.fold(
      (failure) => emit(LoginError(message: mapFailureToMessage(failure))),
      (user) => emit(LoginSuccess(user: user)),
    );
  }
}
