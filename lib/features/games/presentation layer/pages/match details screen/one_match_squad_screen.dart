import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/widgets/reusable_text.dart';
import '../../../domain layer/entities/manager_entity.dart';
import '../../../domain layer/entities/player_per_match_entity.dart';
import '../../bloc/manager bloc/manager_bloc.dart';
import '../../bloc/player per match bloc/player_per_match_bloc.dart';

class MatchLineupsScreen extends StatefulWidget {
  final int matchId;

  const MatchLineupsScreen({super.key, required this.matchId});

  @override
  State<MatchLineupsScreen> createState() => _MatchLineupsScreenState();
}

class _MatchLineupsScreenState extends State<MatchLineupsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PlayerPerMatchBloc>().add(
      GetPlayersPerMatch(matchId: widget.matchId),
    );
    context.read<ManagerBloc>().add(GetManagers(matchId: widget.matchId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerPerMatchBloc, PlayerPerMatchState>(
      builder: (context, playerState) {
        return BlocBuilder<ManagerBloc, ManagerState>(
          builder: (context, managerState) {
            if (playerState is PlayerPerMatchLoading ||
                managerState is ManagerLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (playerState is PlayerPerMatchError) {
              return Center(
                child: Text('Players Error: ${playerState.message}'),
              );
            }
            if (managerState is ManagerError) {
              return Center(
                child: Text('Managers Error: ${managerState.message}'),
              );
            }

            if (playerState is PlayerPerMatchSuccess &&
                managerState is ManagerSuccess) {
              final homePlayers = playerState.players['home'] ?? [];
              final awayPlayers = playerState.players['away'] ?? [];
              final homeManager = managerState.managers['homeManager'];
              final awayManager = managerState.managers['awayManager'];

              final homeStarting =
                  homePlayers.where((p) => !p.substitute).toList();
              final homeSubs = homePlayers.where((p) => p.substitute).toList();
              final awayStarting =
                  awayPlayers.where((p) => !p.substitute).toList();
              final awaySubs = awayPlayers.where((p) => p.substitute).toList();

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFootballField(homeStarting, awayStarting),
                      const SizedBox(height: 24),
                      _buildSubstitutesSection(
                        homeManager,
                        homeSubs,
                        awayManager,
                        awaySubs,
                      ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildFootballField(
    List<PlayerPerMatchEntity> homePlayers,
    List<PlayerPerMatchEntity> awayPlayers,
  ) {
    // Group players by position for dynamic positioning
    final homeGoalkeepers =
        homePlayers.where((p) => p.position == 'G').toList();
    final homeDefenders = homePlayers.where((p) => p.position == 'D').toList();
    final homeMidfielders =
        homePlayers.where((p) => p.position == 'M').toList();
    final homeForwards = homePlayers.where((p) => p.position == 'F').toList();

    final awayGoalkeepers =
        awayPlayers.where((p) => p.position == 'G').toList();
    final awayDefenders = awayPlayers.where((p) => p.position == 'D').toList();
    final awayMidfielders =
        awayPlayers.where((p) => p.position == 'M').toList();
    final awayForwards = awayPlayers.where((p) => p.position == 'F').toList();

    return Container(
      height: 1900.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xff011f28),
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Halfway line
          Positioned(
            left: 0,
            right: 0,
            top: 1900.h / 2 - 1,
            child: Container(height: 2, color: Colors.white),
          ),
          // Center circle
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 185.w,
            top: 1900.h / 2 - 150.h,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          // Center spot
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 40.w,
            top: 1900.h / 2 - 2,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
          // Penalty areas
          _buildPenaltyArea(true), // Home penalty area (top)
          _buildPenaltyArea(false), // Away penalty area (bottom)
          // Goal areas
          _buildGoalArea(true), // Home goal area (top)
          _buildGoalArea(false), // Away goal area (bottom)
          // Corner arcs
          // _buildCornerArc(true, true), // Top-left corner
          // _buildCornerArc(true, false), // Top-right corner
          // _buildCornerArc(false, true), // Bottom-left corner
          // _buildCornerArc(false, false), // Bottom-right corner
          // Home players (top half, attacking downward)
          ...homeGoalkeepers.asMap().entries.map(
            (entry) => _positionPlayer(
              entry.value,
              true,
              Colors.blue,
              entry.key,
              1,
              20.h,
              true,
            ),
          ),
          ...homeDefenders.asMap().entries.map(
            (entry) => _positionPlayer(
              entry.value,
              true,
              Colors.blue,
              entry.key,
              homeDefenders.length,
              250.h,
              false,
            ),
          ),
          ...homeMidfielders.asMap().entries.map(
            (entry) => _positionPlayer(
              entry.value,
              true,
              Colors.blue,
              entry.key,
              homeMidfielders.length,
              550.h,
              false,
            ),
          ),
          ...homeForwards.asMap().entries.map(
            (entry) => _positionPlayer(
              entry.value,
              true,
              Colors.blue,
              entry.key,
              homeForwards.length,
              751.h,
              false,
            ),
          ),
          // Away players (bottom half, attacking upward)
          ...awayGoalkeepers.asMap().entries.map(
            (entry) => _positionPlayer(
              entry.value,
              false,
              Colors.red,
              entry.key,
              1,
              1675.h,
              true,
            ),
          ),
          ...awayDefenders.asMap().entries.map(
            (entry) => _positionPlayer(
              entry.value,
              false,
              Colors.red,
              entry.key,
              awayDefenders.length,
              1470.h,
              false,
            ),
          ),
          ...awayMidfielders.asMap().entries.map(
            (entry) => _positionPlayer(
              entry.value,
              false,
              Colors.red,
              entry.key,
              awayMidfielders.length,
              1230.h,
              false,
            ),
          ),
          ...awayForwards.asMap().entries.map(
            (entry) => _positionPlayer(
              entry.value,
              false,
              Colors.red,
              entry.key,
              awayForwards.length,
              1000.h,
              false,
            ),
          ),
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
          border: Border.all(color: Colors.white, width: 2),
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
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildCornerArc(bool isTop, bool isLeft) {
    return Positioned(
      left: isLeft ? 0 : MediaQuery.of(context).size.width - 20,
      top: isTop ? 0 : 580,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.only(
            topRight: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            // Top-left corner rounds top-right
            topLeft: isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
            // Top-right corner rounds top-left
            bottomRight:
                !isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            // Bottom-left corner rounds bottom-right
            bottomLeft:
                !isTop && !isLeft
                    ? const Radius.circular(20)
                    : Radius.zero, // Bottom-right corner rounds bottom-left
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
    bool isGoalkeeper,
  ) {
    double xOffset;
    double yOffset = baseYOffset;

    if (isGoalkeeper) {
      xOffset =
          MediaQuery.of(context).size.width / 2 - 50; // Center the goalkeeper
    } else {
      // Adjust horizontal spread based on position and formation
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0; // Reduced padding to allow more space
      const leftShift = 30.0; // Shift all players to the left
      final availableWidth = screenWidth - 2 * minPadding;
      if (playersInZone == 1) {
        xOffset =
            screenWidth / 2 -
            -125.w -
            leftShift; // Center single player with left shift
      } else if (playersInZone == 2) {
        xOffset =
            minPadding +
            (index % playersInZone) * (availableWidth / 10) -
            12 -
            leftShift;
      } else if (playersInZone == 3) {
        xOffset =
            minPadding +
            (index % playersInZone) * (availableWidth / 1.5) -
            0 -
            leftShift;
      } else {
        xOffset =
            minPadding +
            (index % playersInZone) * (availableWidth / 3.1) -
            0 -
            15;
      }
    }

    return Positioned(
      left: xOffset,
      top: yOffset,
      child: Column(
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade800, // Fallback color
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl:
                    'https://img.sofascore.com/api/v1/player/${player.id}/image',
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 110.w,
                        height: 110.w,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(55.w),
                        ),
                      ),
                    ),
                errorWidget: (context, url, error) {
                  print('Error loading player ${player.id} image: $error');
                  return Icon(
                    Icons.person,
                    size: 60.w,
                    color: Colors.grey.shade600,
                  );
                },
                fit: BoxFit.cover,
                width: 110.w,
                height: 110.w,
                cacheKey: player.id.toString(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: teamColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            width: 150.w,
            child: Text(
              player.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstitutesSection(
    ManagerEntity? homeManager,
    List<PlayerPerMatchEntity> homeSubs,
    ManagerEntity? awayManager,
    List<PlayerPerMatchEntity> awaySubs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Substitutes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildManagerHeader('Home Manager', homeManager, Colors.blue),
        _buildSubsList('Home Substitutes', homeSubs, Colors.blue),
        const SizedBox(height: 24),
        _buildManagerHeader('Away Manager', awayManager, Colors.red),
        _buildSubsList('Away Substitutes', awaySubs, Colors.red),
      ],
    );
  }

  Widget _buildManagerHeader(
    String title,
    ManagerEntity? manager,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReusableText(
                text: title,
                textSize: 120.sp,
                textColor: color,
                textFontWeight: FontWeight.bold,
              ),

              const SizedBox(height: 8),
              if (manager == null)
                const Text('No manager data available')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 150.w,
                          height: 150.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade800, // Fallback color
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl:
                                  "https://img.sofascore.com/api/v1/manager/${manager.id}/image",
                              placeholder:
                                  (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      width: 110.w,
                                      height: 110.w,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(
                                          55.w,
                                        ),
                                      ),
                                    ),
                                  ),
                              errorWidget: (context, url, error) {
                                print(
                                  'Error loading player ${manager.id} image: $error',
                                );
                                return Icon(
                                  Icons.person,
                                  size: 60.w,
                                  color: Colors.grey.shade600,
                                );
                              },
                              fit: BoxFit.cover,
                              width: 110.w,
                              height: 110.w,
                              cacheKey: manager.id.toString(),
                            ),
                          ),
                        ),
                        SizedBox(width: 30.w),
                        ReusableText(
                          text: manager.name,
                          textSize: 100.sp,
                          textColor: color,
                          textFontWeight: FontWeight.w800,
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubsList(
    String title,
    List<PlayerPerMatchEntity> subs,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        if (subs.isEmpty)
          const Text('No substitutes available')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subs.length,
            itemBuilder: (context, index) {
              return _buildPlayerRow(subs[index], color);
            },
          ),
      ],
    );
  }

  Widget _buildPlayerRow(PlayerPerMatchEntity player, Color teamColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 110.w,
                  height: 110.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade800, // Fallback color
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl:
                          'https://img.sofascore.com/api/v1/player/${player.id}/image',
                      placeholder:
                          (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: 110.w,
                              height: 110.w,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(55.w),
                              ),
                            ),
                          ),
                      errorWidget: (context, url, error) {
                        print(
                          'Error loading player ${player.id} image: $error',
                        );
                        return Icon(
                          Icons.person,
                          size: 60.w,
                          color: Colors.grey.shade600,
                        );
                      },
                      fit: BoxFit.cover,
                      width: 110.w,
                      height: 110.w,
                      cacheKey: player.id.toString(),
                    ),
                  ),
                ),
                SizedBox(width: 45.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReusableText(
                        text: player.name ?? 'N/A',
                        textSize: 100.sp,
                        textColor: const Color(0xffe4e9ea),
                        textFontWeight: FontWeight.w700,
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: player.jerseyNumber != null ? 45.w : 60.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ReusableText(
                                  text:
                                      player.jerseyNumber != null
                                          ? player.jerseyNumber.toString()
                                          : "N/A",
                                  textSize: 90.sp,
                                  textColor: Colors.white,
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
