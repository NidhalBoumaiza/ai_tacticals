part of 'matches_per_round_bloc.dart';

abstract class MatchesPerRoundState extends Equatable {
  const MatchesPerRoundState();

  @override
  List<Object?> get props => [];
}

class MatchesPerRoundInitial extends MatchesPerRoundState {}

class MatchesPerRoundLoading extends MatchesPerRoundState {}

class MatchesPerRoundLoaded extends MatchesPerRoundState {
  final Map<int, List<MatchEventEntity>> matches;
  final int currentRound;
  final bool isLoadingMore;

  const MatchesPerRoundLoaded({
    required this.matches,
    required this.currentRound,
    this.isLoadingMore = false,
  });

  MatchesPerRoundLoaded copyWith({
    Map<int, List<MatchEventEntity>>? matches,
    int? currentRound,
    bool? isLoadingMore,
  }) {
    return MatchesPerRoundLoaded(
      matches: matches ?? this.matches,
      currentRound: currentRound ?? this.currentRound,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [matches, currentRound, isLoadingMore];
}

class MatchesPerRoundError extends MatchesPerRoundState {
  final String message;

  const MatchesPerRoundError({required this.message});

  @override
  List<Object?> get props => [message];
}
