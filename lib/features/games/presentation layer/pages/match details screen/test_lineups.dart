import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/widgets/reusable_text.dart';
import 'player_stats_modal.dart'; // Assuming this is a local widget

// Fake Player Entity (simplified for testing)
class PlayerPerMatchEntity {
  final int? id;
  final String? name;
  final String? position;
  final bool substitute;
  final int? jerseyNumber;

  PlayerPerMatchEntity({
    this.id,
    this.name,
    this.position,
    this.substitute = false,
    this.jerseyNumber,
  });

  factory PlayerPerMatchEntity.fromJson(Map<String, dynamic> json) {
    return PlayerPerMatchEntity(
      id: json['id'],
      name: json['name'],
      position: json['position'],
      substitute: json['substitute'] ?? false,
      jerseyNumber: json['jerseyNumber'],
    );
  }
}

// Fake Manager Entity (simplified for testing)
class ManagerEntity {
  final int? id;
  final String name;

  ManagerEntity({this.id, this.name = 'Unknown Manager'});

  factory ManagerEntity.fromJson(Map<String, dynamic> json) {
    return ManagerEntity(
      id: json['id'],
      name: json['name'] ?? 'Unknown Manager',
    );
  }
}

class MatchLineupsScreentets extends StatefulWidget {
  final int matchId;

  const MatchLineupsScreentets({super.key, required this.matchId});

  @override
  State<MatchLineupsScreentets> createState() => _MatchLineupsScreentetsState();
}

class _MatchLineupsScreentetsState extends State<MatchLineupsScreentets> {
  Map<int, Offset> homePlayerPositions = {};
  Map<int, Offset> awayPlayerPositions = {};

  // Fake JSON data
  final String fakeJsonData = '''
  {
    "players": {
      "home": [
        {"id": 1, "name": "Marc-André ter Stegen", "position": "G", "substitute": false, "jerseyNumber": 1},
        {"id": 2, "name": "Jules Koundé", "position": "D", "substitute": false, "jerseyNumber": 23},
        {"id": 3, "name": "Ronald Araújo", "position": "D", "substitute": false, "jerseyNumber": 4},
        {"id": 4, "name": "Frenkie de Jong", "position": "M", "substitute": false, "jerseyNumber": 21},
        {"id": 5, "name": "Pedri", "position": "M", "substitute": false, "jerseyNumber": 8},
        {"id": 6, "name": "Robert Lewandowski", "position": "F", "substitute": false, "jerseyNumber": 9},
        {"id": 7, "name": "Iñaki Peña", "position": "G", "substitute": true, "jerseyNumber": 13}
      ],
      "away": [
        {"id": 8, "name": "Thibaut Courtois", "position": "G", "substitute": false, "jerseyNumber": 1},
        {"id": 9, "name": "Éder Militão", "position": "D", "substitute": false, "jerseyNumber": 3},
        {"id": 10, "name": "Dani Carvajal", "position": "D", "substitute": false, "jerseyNumber": 2},
        {"id": 11, "name": "Toni Kroos", "position": "M", "substitute": false, "jerseyNumber": 8},
        {"id": 12, "name": "Luka Modrić", "position": "M", "substitute": false, "jerseyNumber": 10},
        {"id": 13, "name": "Karim Benzema", "position": "F", "substitute": false, "jerseyNumber": 9},
        {"id": 14, "name": "Andriy Lunin", "position": "G", "substitute": true, "jerseyNumber": 13}
      ]
    },
    "managers": {
      "homeManager": {"id": 1, "name": "Xavi Hernández"},
      "awayManager": {"id": 2, "name": "Carlo Ancelotti"}
    }
  }
  ''';

  late Map<String, List<PlayerPerMatchEntity>> players;
  late Map<String, ManagerEntity?> managers;

  void _initializePlayerPositions(List<PlayerPerMatchEntity> homePlayers, List<PlayerPerMatchEntity> awayPlayers) {
    homePlayerPositions.clear();
    awayPlayerPositions.clear();

    homePlayers.asMap().forEach((index, player) {
      homePlayerPositions[player.id ?? index] = _getDefaultPosition(
          player.position ?? 'M',
          true,
          index,
          homePlayers.where((p) => p.position == player.position).length);
    });

    awayPlayers.asMap().forEach((index, player) {
      awayPlayerPositions[player.id ?? index] = _getDefaultPosition(
          player.position ?? 'M',
          false,
          index,
          awayPlayers.where((p) => p.position == player.position).length);
    });
  }

  Offset _getDefaultPosition(String position, bool isHomeTeam, int index, int totalInPosition) {
    double baseY;
    if (isHomeTeam) {
      switch (position) {
        case 'G':
          baseY = 10.h;
          break;
        case 'D':
          baseY = 250.h;
          break;
        case 'M':
          baseY = 550.h;
          break;
        case 'F':
          baseY = 751.h;
          break;
        default:
          baseY = 550.h;
      }
    } else {
      switch (position) {
        case 'G':
          baseY = 1675.h;
          break;
        case 'D':
          baseY = 1470.h;
          break;
        case 'M':
          baseY = 1230.h;
          break;
        case 'F':
          baseY = 1000.h;
          break;
        default:
          baseY = 1230.h;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width - 310.w;
    const minPadding = 40.0;
    final availableWidth = screenWidth - 2 * minPadding;
    double x = minPadding +
        (index % totalInPosition) * (availableWidth / (totalInPosition - 1).clamp(1, double.infinity));

    return Offset(x, baseY);
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final jsonData = jsonDecode(fakeJsonData);
    players = {
      'home': (jsonData['players']['home'] as List)
          .map((e) => PlayerPerMatchEntity.fromJson(e))
          .toList(),
      'away': (jsonData['players']['away'] as List)
          .map((e) => PlayerPerMatchEntity.fromJson(e))
          .toList(),
    };
    managers = {
      'homeManager': ManagerEntity.fromJson(jsonData['managers']['homeManager']),
      'awayManager': ManagerEntity.fromJson(jsonData['managers']['awayManager']),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(30.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFootballField(
                players['home']!.where((p) => !p.substitute).toList(),
                players['away']!.where((p) => !p.substitute).toList(),
              ),
              SizedBox(height: 60.h),
              _buildSubstitutesSection(
                managers['homeManager'],
                players['home']!.where((p) => p.substitute).toList(),
                managers['awayManager'],
                players['away']!.where((p) => p.substitute).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFootballField(
      List<PlayerPerMatchEntity> homePlayers, List<PlayerPerMatchEntity> awayPlayers) {
    if (homePlayerPositions.isEmpty && awayPlayerPositions.isEmpty) {
      _initializePlayerPositions(homePlayers, awayPlayers);
    }

    return Container(
      height: 2200.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 20.h,
            right: 20.w,
            child: SizedBox(
              height: 120.w,
              width: 120.w,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _initializePlayerPositions(homePlayers, awayPlayers);
                  });
                },
                child: const Icon(Icons.refresh),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 2200.h / 2 - 1,
            child: Container(
              height: 2,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          _buildPenaltyArea(true),
          _buildPenaltyArea(false),
          _buildGoalArea(true),
          _buildGoalArea(false),
          ...homePlayers.map((player) => _positionPlayer(
            player,
            true,
            Colors.blue,
            homePlayers.indexOf(player),
            homePlayers.where((p) => p.position == player.position).length,
            0,
            player.position == 'G',
          )),
          ...awayPlayers.map((player) => _positionPlayer(
            player,
            false,
            Colors.red,
            awayPlayers.indexOf(player),
            awayPlayers.where((p) => p.position == player.position).length,
            0,
            player.position == 'G',
          )),
        ],
      ),
    );
  }

  Widget _buildPenaltyArea(bool isHomeTeam) {
    return Positioned(
      left: 120.w,
      right: 120.w,
      top: isHomeTeam ? -5.h : 1547.h,
      child: Container(
        height: 340.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalArea(bool isHomeTeam) {
    return Positioned(
      left: 270.w,
      right: 270.w,
      top: isHomeTeam ? -5.h : 1718.h,
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _positionPlayer(
      PlayerPerMatchEntity player,
      bool isHomeTeam,
      Color teamColor,
      int index,
      int playersInZone,
      double baseYOffset,
      bool isGoalkeeper) {
    final playerId = player.id ?? index;
    final positions = isHomeTeam ? homePlayerPositions : awayPlayerPositions;
    final initialPosition = positions[playerId] ??
        _getDefaultPosition(player.position ?? 'M', isHomeTeam, index, playersInZone);

    return Positioned(
      left: initialPosition.dx,
      top: initialPosition.dy,
      child: Draggable(
        feedback: Material(
          child: Container(
            width: 110.w,
            height: 110.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border.all(color: teamColor.withOpacity(0.7), width: 2),
            ),
            child: Icon(
              Icons.person,
              size: 60.w,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        childWhenDragging: Container(
          width: 110.w,
          height: 110.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            border: Border.all(color: teamColor.withOpacity(0.3), width: 2),
          ),
        ),
        onDragEnd: (details) {
          setState(() {
            if (isHomeTeam) {
              homePlayerPositions[playerId] = Offset(
                details.offset.dx,
                details.offset.dy - kToolbarHeight,
              );
            } else {
              awayPlayerPositions[playerId] = Offset(
                details.offset.dx,
                details.offset.dy - kToolbarHeight,
              );
            }
          });
        },
        child: GestureDetector(
          onTap: () {
            if (player.id != null) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => PlayerStatsModal(
                  matchId: widget.matchId,
                  playerId: player.id!,
                  playerName: player.name ?? 'Unknown Player',
                ),
              );
            }
          },
          child: Column(
            children: [
              Container(
                width: 110.w,
                height: 110.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  border: Border.all(color: teamColor.withOpacity(0.7), width: 2),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: 'https://img.sofascore.com/api/v1/player/${player.id}/image',
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Theme.of(context).colorScheme.surface,
                      highlightColor: Theme.of(context).colorScheme.surfaceVariant,
                      child: Container(
                        width: 110.w,
                        height: 110.w,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      size: 60.w,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    fit: BoxFit.cover,
                    width: 110.w,
                    height: 110.w,
                    cacheKey: player.id.toString(),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                constraints: BoxConstraints(maxWidth: 150.w),
                child: ReusableText(
                  text: player.name ?? 'N/A',
                  textSize: 80.sp,
                  textColor: Theme.of(context).colorScheme.onSurface,
                  textFontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubstitutesSection(
      ManagerEntity? homeManager,
      List<PlayerPerMatchEntity> homeSubs,
      ManagerEntity? awayManager,
      List<PlayerPerMatchEntity> awaySubs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReusableText(
          text: 'substitutes'.tr,
          textSize: 140.sp,
          textFontWeight: FontWeight.bold,
          textColor: Theme.of(context).colorScheme.onSurface,
        ),
        SizedBox(height: 30.h),
        _buildManagerHeader('home_manager'.tr, homeManager, Colors.blue),
        SizedBox(height: 20.h),
        _buildSubsList('home_substitutes'.tr, homeSubs, Colors.blue),
        SizedBox(height: 60.h),
        _buildManagerHeader('away_manager'.tr, awayManager, Colors.red),
        SizedBox(height: 20.h),
        _buildSubsList('away_substitutes'.tr, awaySubs, Colors.red), // Fixed to use awaySubs
      ],
    );
  }

  Widget _buildManagerHeader(String title, ManagerEntity? manager, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReusableText(
              text: title,
              textSize: 120.sp,
              textColor: color,
              textFontWeight: FontWeight.bold,
            ),
            SizedBox(height: 20.h),
            if (manager == null)
              ReusableText(
                text: 'no_manager_data_available'.tr,
                textSize: 100.sp,
                textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              )
            else
              Row(
                children: [
                  Container(
                    width: 110.w,
                    height: 110.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      border: Border.all(color: color.withOpacity(0.7), width: 2),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: "https://img.sofascore.com/api/v1/manager/${manager.id}/image",
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Theme.of(context).colorScheme.surface,
                          highlightColor: Theme.of(context).colorScheme.surfaceVariant,
                          child: Container(
                            width: 110.w,
                            height: 110.w,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: 60.w,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        fit: BoxFit.cover,
                        width: 110.w,
                        height: 110.w,
                        cacheKey: manager.id.toString(),
                      ),
                    ),
                  ),
                  SizedBox(width: 30.w),
                  Expanded(
                    child: ReusableText(
                      text: manager.name,
                      textSize: 100.sp,
                      textColor: Theme.of(context).colorScheme.onSurface,
                      textFontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubsList(String title, List<PlayerPerMatchEntity> subs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReusableText(
          text: title,
          textSize: 120.sp,
          textFontWeight: FontWeight.bold,
          textColor: color,
        ),
        SizedBox(height: 20.h),
        if (subs.isEmpty)
          ReusableText(
            text: 'no_substitutes_available'.tr,
            textSize: 100.sp,
            textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subs.length,
            itemBuilder: (context, index) => _buildPlayerRow(subs[index], color),
          ),
      ],
    );
  }

  Widget _buildPlayerRow(PlayerPerMatchEntity player, Color teamColor) {
    return GestureDetector(
      onTap: () {
        if (player.id != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PlayerStatsModal(
              matchId: widget.matchId,
              playerId: player.id!,
              playerName: player.name ?? 'Unknown Player',
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        child: Row(
          children: [
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceVariant,
                border: Border.all(color: teamColor.withOpacity(0.7), width: 2),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: 'https://img.sofascore.com/api/v1/player/${player.id}/image',
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.surface,
                    highlightColor: Theme.of(context).colorScheme.surfaceVariant,
                    child: Container(
                      width: 110.w,
                      height: 110.w,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    size: 60.w,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  fit: BoxFit.cover,
                  width: 110.w,
                  height: 110.w,
                  cacheKey: player.id.toString(),
                ),
              ),
            ),
            SizedBox(width: 30.w),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReusableText(
                          text: player.name ?? 'N/A',
                          textSize: 100.sp,
                          textColor: Theme.of(context).colorScheme.onSurface,
                          textFontWeight: FontWeight.w700,
                        ),
                        SizedBox(height: 10.h),
                        ReusableText(
                          text: player.jerseyNumber?.toString() ?? 'N/A',
                          textSize: 90.sp,
                          textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}