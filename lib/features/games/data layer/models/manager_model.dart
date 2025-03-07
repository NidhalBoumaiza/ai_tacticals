import '../../domain layer/entities/manager_entity.dart';

class ManagerModel extends ManagerEntity {
  ManagerModel({
    required int id,
    required String name,
    required String slug,
    required String shortName,
    Map<String, dynamic>? fieldTranslations,
  }) : super(
         id: id,
         name: name,
         slug: slug,
         shortName: shortName,
         fieldTranslations: fieldTranslations,
       );

  factory ManagerModel.fromJson(Map<String, dynamic> json) {
    return ManagerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      shortName: json['shortName'] as String,
      fieldTranslations: json['fieldTranslations'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'shortName': shortName,
      if (fieldTranslations != null) 'fieldTranslations': fieldTranslations,
    };
  }

  static List<ManagerModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => ManagerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
