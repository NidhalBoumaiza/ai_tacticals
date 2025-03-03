// lib/features/standings/data_layer/models/season_model.dart
import '../../domain layer/entities/season_entity.dart';

class SeasonModel extends SeasonEntity {
  SeasonModel({required String year, required int id})
    : super(year: year, id: id);

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(year: json['year'] as String, id: json['id'] as int);
  }
}
