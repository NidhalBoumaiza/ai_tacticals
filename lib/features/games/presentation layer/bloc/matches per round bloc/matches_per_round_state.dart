part of 'matches_per_round_bloc.dart';

abstract class MatchesPerRoundState extends Equatable {
  const MatchesPerRoundState();

  @override
  List<Object?> get props => [];
}

class MatchesPerRoundInitial extends MatchesPerRoundState {}

class MatchesPerRoundLoading extends MatchesPerRoundState {}

class MatchesPerRoundLoaded extends MatchesPerRoundState {
  final Map<int, List<MatchEventEntity>> matches; // Still used for caching
  final int currentRound; // Last played round
  final int nextRound; // Next unplayed round
  final bool isLoadingMore;

  const MatchesPerRoundLoaded({
    required this.matches,
    required this.currentRound,
    required this.nextRound,
    this.isLoadingMore = false,
  });

  MatchesPerRoundLoaded copyWith({
    Map<int, List<MatchEventEntity>>? matches,
    int? currentRound,
    int? nextRound,
    bool? isLoadingMore,
  }) {
    return MatchesPerRoundLoaded(
      matches: matches ?? this.matches,
      currentRound: currentRound ?? this.currentRound,
      nextRound: nextRound ?? this.nextRound,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [matches, currentRound, nextRound, isLoadingMore];
}

class MatchesPerRoundError extends MatchesPerRoundState {
  final String message;

  const MatchesPerRoundError({required this.message});

  @override
  List<Object?> get props => [message];
}
