import 'package:equatable/equatable.dart';

class CountryEntity extends Equatable {
  final String name;
  final String slug;
  final int priority;
  final int id;
  final String flag;
  final String? alpha2; // Nullable, as it might not be provided by the API

  CountryEntity({
    required this.name,
    required this.slug,
    required this.priority,
    required this.id,
    required this.flag,
    this.alpha2, // Optional, defaults to null
  });

  // Optional: Factory constructor for creating an instance with default values or from API data
  factory CountryEntity.create({
    required String name,
    required String slug,
    required int priority,
    required int id,
    required String flag,
    String? alpha2,
  }) {
    return CountryEntity(
      name: name,
      slug: slug,
      priority: priority,
      id: id,
      flag: flag,
      alpha2: alpha2,
    );
  }

  @override
  List<Object?> get props => [name, slug, priority, id, flag, alpha2];
}
