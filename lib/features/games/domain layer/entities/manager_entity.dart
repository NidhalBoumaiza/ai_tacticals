class ManagerEntity {
  final int id;
  final String name;
  final String slug;
  final String shortName;
  final Map<String, dynamic>? fieldTranslations;

  ManagerEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.shortName,
    this.fieldTranslations,
  });
}
