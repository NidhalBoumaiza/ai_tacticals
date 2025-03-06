// lib/features/standings/presentation_layer/cubit/expansion_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'expansion_text_state.dart';

class ExpansionCubit extends Cubit<ExpansionState> {
  ExpansionCubit() : super(const ExpansionState());

  void toggleExpansion() {
    emit(state.copyWith(isExpanded: !state.isExpanded));
  }
}
