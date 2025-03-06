// player_model.dart
import '../../domain layer/entities/player_entity.dart';

class PlayerModel extends PlayerEntity {
  const PlayerModel({
    super.id,
    super.name,
    super.shirtNumber,
    super.age,
    super.countryAlpha2,
    super.countryAlpha2Lower,
    super.countryAlpha3,
    super.position,
  });

  factory PlayerModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerModel();

    final playerData = json['player'] as Map<String, dynamic>? ?? {};
    final country = playerData['country'] as Map<String, dynamic>? ?? {};
    final alpha2 = country['alpha2'] as String? ?? '';
    final alpha3 = country['alpha3'] as String? ?? '';

    return PlayerModel(
      id: playerData['id'] as int?,
      name: playerData['name'] as String?,
      shirtNumber: playerData['shirtNumber'] as int?,
      age: _calculateAge(playerData['dateOfBirthTimestamp'] as int?),
      countryAlpha2: alpha2,
      countryAlpha2Lower: alpha2?.toLowerCase(),
      countryAlpha3: getProperAlpha3(alpha2, alpha3),
      position: _mapPosition(playerData['position'] as String?),
    );
  }

  static String? _mapPosition(String? shortCode) {
    if (shortCode == null) return null;
    return switch (shortCode.toUpperCase()) {
      'F' => 'Forward',
      'M' => 'Midfield',
      'D' => 'Defense',
      'G' => 'Goalkeeper',
      _ => 'Other Position',
    };
  }

  static int? _calculateAge(int? timestamp) {
    if (timestamp == null) return null;
    final dob = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    return now.year -
        dob.year -
        (now.isBefore(DateTime(now.year, dob.month, dob.day)) ? 1 : 0);
  }

  static String? getProperAlpha3(String? alpha2, String? originalAlpha3) {
    if (alpha2 == null || originalAlpha3 == null) return null;
    return alpha2 == 'ES' ? 'ESP' : originalAlpha3;
  }

  Map<String, dynamic> toJson() => {
    'player': {
      'id': id,
      'name': name,
      'shirtNumber': shirtNumber,
      'dateOfBirthTimestamp': _getTimestamp(),
      'position': position,
      'country': {'alpha2': countryAlpha2, 'alpha3': countryAlpha3},
    },
  };

  int? _getTimestamp() {
    if (age == null) return null;
    final now = DateTime.now();
    final dobYear = now.year - age!;
    return DateTime(dobYear).millisecondsSinceEpoch ~/ 1000;
  }

  PlayerEntity toEntity() => PlayerEntity(
    id: id,
    name: name,
    shirtNumber: shirtNumber,
    age: age,
    countryAlpha2: countryAlpha2,
    countryAlpha2Lower: countryAlpha2Lower,
    countryAlpha3: countryAlpha3,
    position: position,
  );
}
