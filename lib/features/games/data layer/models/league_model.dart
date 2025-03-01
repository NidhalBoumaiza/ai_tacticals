import 'package:analysis_ai/features/games/domain%20layer/entities/league_entity.dart';

class LeagueModel extends LeagueEntity {
  LeagueModel({required int id, required String name})
    : super(id: id, name: name);

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    return LeagueModel(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'id': id, 'name': name};
    return data;
  }
}
