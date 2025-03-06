// player_entity.dart
import 'package:equatable/equatable.dart';

class PlayerEntity extends Equatable {
  final int? id;
  final String? name;
  final int? shirtNumber;
  final int? age;
  final String? countryAlpha2;
  final String? countryAlpha2Lower;
  final String? countryAlpha3;
  final String? position;

  const PlayerEntity({
    this.id,
    this.name,
    this.shirtNumber,
    this.age,
    this.countryAlpha2,
    this.countryAlpha2Lower,
    this.countryAlpha3,
    this.position,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    shirtNumber,
    age,
    countryAlpha2,
    countryAlpha2Lower,
    countryAlpha3,
    position,
  ];
}
