class LeagueEntity {
  final int id;
  final String name;

  LeagueEntity({required this.id, required this.name});

  factory LeagueEntity.create({required int id, required String name}) {
    return LeagueEntity(id: id, name: name);
  }

  @override
  List<Object?> get props => [id, name];
}
