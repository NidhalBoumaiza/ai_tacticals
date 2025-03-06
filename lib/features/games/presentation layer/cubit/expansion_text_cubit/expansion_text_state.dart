// lib/features/standings/presentation_layer/cubit/expansion_state.dart
part of 'expansion_text_cubit.dart';

class ExpansionState extends Equatable {
  final bool isExpanded;

  const ExpansionState({this.isExpanded = false});

  ExpansionState copyWith({bool? isExpanded}) {
    return ExpansionState(isExpanded: isExpanded ?? this.isExpanded);
  }

  @override
  List<Object> get props => [isExpanded];
}
