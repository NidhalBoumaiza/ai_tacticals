import 'package:analysis_ai/features/games/domain layer/entities/country_entity.dart';

class CountryModel extends CountryEntity {
  CountryModel({
    required String name,
    required String slug,
    required int priority,
    required int id,
    required String flag,
    String? alpha2,
  }) : super(
         name: name,
         slug: slug,
         priority: priority,
         id: id,
         flag: flag,
         alpha2: alpha2,
       );

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      name: json['name'] as String,
      slug: json['slug'] as String,
      priority: json['priority'] as int,
      id: json['id'] as int,
      flag: json['flag'] as String,
      alpha2: json['alpha2'] as String?, // Nullable
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'slug': slug,
      'priority': priority,
      'id': id,
      'flag': flag,
    };
    if (alpha2 != null) {
      data['alpha2'] = alpha2;
    }
    return data;
  }
}
