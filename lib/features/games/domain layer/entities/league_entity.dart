// lib/features/standings/domain_layer/entities/league_entity.dart
class LeagueEntity {
  final int? id;
  final String? name;

  LeagueEntity({this.id, this.name});

  factory LeagueEntity.create({int? id, String? name}) {
    return LeagueEntity(id: id, name: name);
  }

  @override
  List<Object?> get props => [id, name];
}
