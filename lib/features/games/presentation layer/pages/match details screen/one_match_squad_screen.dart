import 'package:analysis_ai/features/games/presentation%20layer/pages/match%20details%20screen/field_edit_screen.dart';
import 'package:analysis_ai/features/games/presentation%20layer/pages/match%20details%20screen/player_stats_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/widgets/field_drawing_painter.dart';
import '../../../../../core/widgets/reusable_text.dart';
import '../../../domain%20layer/entities/manager_entity.dart';
import '../../../domain%20layer/entities/player_per_match_entity.dart';
import '../../bloc/manager%20bloc/manager_bloc.dart';
import '../../bloc/player%20per%20match%20bloc/player_per_match_bloc.dart';
import '../../cubit/lineup drawing cubut/drawing__state.dart';

class MatchLineupsScreen extends StatefulWidget {
  final int matchId;

  const MatchLineupsScreen({
    super.key,
    required this.matchId,
  });

  @override
  State<MatchLineupsScreen> createState() => _MatchLineupsScreenState();
}

class _MatchLineupsScreenState extends State<MatchLineupsScreen> {
  late final PlayerPerMatchBloc _playerBloc;
  late final ManagerBloc _managerBloc;
  List<PlayerPosition> homePlayerPositions = [];
  List<PlayerPosition> awayPlayerPositions = [];
  List<DrawingItem> drawings = [];
  final ValueNotifier<bool> isDialOpen = ValueNotifier(false);
  late final ScrollController _scrollController;
  int? _lastMatchId; // Track the last matchId to detect changes

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _playerBloc = context.read<PlayerPerMatchBloc>();
    _managerBloc = context.read<ManagerBloc>();
    _lastMatchId = widget.matchId;
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    isDialOpen.dispose();
    super.dispose();
  }

  void _initializeData() {
    if (!_playerBloc.isMatchCached(widget.matchId)) {
      _playerBloc.add(GetPlayersPerMatch(matchId: widget.matchId));
    }
    if (!_managerBloc.isMatchCached(widget.matchId)) {
      _managerBloc.add(GetManagers(matchId: widget.matchId));
    }
  }

  void _initializePlayerPositions(
      List<PlayerPerMatchEntity> homePlayers,
      List<PlayerPerMatchEntity> awayPlayers,
      ) {
    homePlayerPositions.clear(); // Clear previous positions
    awayPlayerPositions.clear(); // Clear previous positions

    final homeGoalkeepers = homePlayers.where((p) => p.position == 'G').toList();
    final homeDefenders = homePlayers.where((p) => p.position == 'D').toList();
    final homeMidfielders = homePlayers.where((p) => p.position == 'M').toList();
    final homeForwards = homePlayers.where((p) => p.position == 'F').toList();

    final awayGoalkeepers = awayPlayers.where((p) => p.position == 'G').toList();
    final awayDefenders = awayPlayers.where((p) => p.position == 'D').toList();
    final awayMidfielders = awayPlayers.where((p) => p.position == 'M').toList();
    final awayForwards = awayPlayers.where((p) => p.position == 'F').toList();

    homeGoalkeepers.asMap().forEach((index, player) {
      homePlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'home-gk-$index',
        x: MediaQuery.of(context).size.width / 2 - 50.w,
        y: 20.h,
        isHomeTeam: true,
        teamColor: Colors.blue,
        player: player,
      ));
    });

    homeDefenders.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % homeDefenders.length) *
              (availableWidth / (homeDefenders.length - 1).clamp(1, double.infinity));
      homePlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'home-def-$index',
        x: xOffset,
        y: 250.h,
        isHomeTeam: true,
        teamColor: Colors.blue,
        player: player,
      ));
    });

    homeMidfielders.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % homeMidfielders.length) *
              (availableWidth / (homeMidfielders.length - 1).clamp(1, double.infinity));
      homePlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'home-mid-$index',
        x: xOffset,
        y: 550.h,
        isHomeTeam: true,
        teamColor: Colors.blue,
        player: player,
      ));
    });

    homeForwards.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % homeForwards.length) *
              (availableWidth / (homeForwards.length - 1).clamp(1, double.infinity));
      homePlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'home-fwd-$index',
        x: xOffset,
        y: 751.h,
        isHomeTeam: true,
        teamColor: Colors.blue,
        player: player,
      ));
    });

    awayGoalkeepers.asMap().forEach((index, player) {
      awayPlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'away-gk-$index',
        x: MediaQuery.of(context).size.width / 2 - 50.w,
        y: 1675.h,
        isHomeTeam: false,
        teamColor: Colors.red,
        player: player,
      ));
    });

    awayDefenders.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % awayDefenders.length) *
              (availableWidth / (awayDefenders.length - 1).clamp(1, double.infinity));
      awayPlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'away-def-$index',
        x: xOffset,
        y: 1470.h,
        isHomeTeam: false,
        teamColor: Colors.red,
        player: player,
      ));
    });

    awayMidfielders.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % awayMidfielders.length) *
              (availableWidth / (awayMidfielders.length - 1).clamp(1, double.infinity));
      awayPlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'away-mid-$index',
        x: xOffset,
        y: 1230.h,
        isHomeTeam: false,
        teamColor: Colors.red,
        player: player,
      ));
    });

    awayForwards.asMap().forEach((index, player) {
      final screenWidth = MediaQuery.of(context).size.width - 310.w;
      const minPadding = 40.0;
      final availableWidth = screenWidth - 2 * minPadding;
      final xOffset = minPadding +
          (index % awayForwards.length) *
              (availableWidth / (awayForwards.length - 1).clamp(1, double.infinity));
      awayPlayerPositions.add(PlayerPosition(
        playerId: player.id?.toString() ?? 'away-fwd-$index',
        x: xOffset,
        y: 1000.h,
        isHomeTeam: false,
        teamColor: Colors.red,
        player: player,
      ));
    });
  }

  Widget _buildPlayerWidget(PlayerPosition position) {
    return Column(
      children: [
        Container(
          width: 110.w,
          height: 110.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceVariant,
            border: Border.all(
              color: position.teamColor.withOpacity(0.7),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: 'https://img.sofascore.com/api/v1/player/${position.player.id}/image',
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
              cacheKey: position.player.id.toString(),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: position.teamColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6.r),
          ),
          constraints: BoxConstraints(maxWidth: 150.w),
          child: ReusableText(
            text: position.player.name ?? 'N/A',
            textSize: 80.sp,
            textColor: Theme.of(context).colorScheme.onSurface,
            textFontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldBackground() {
    return Container(
      height: 1900.h,
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
            left: 0,
            right: 0,
            top: 1900.h / 2 - 1,
            child: Container(
              height: 2,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 150.w,
            top: 1900.h / 2 - 150.h,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 2.w,
            top: 1900.h / 2 - 2,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          _buildPenaltyArea(true),
          _buildPenaltyArea(false),
          _buildGoalArea(true),
          _buildGoalArea(false),
        ],
      ),
    );
  }

  Widget _buildFootballField(
      List<PlayerPerMatchEntity> homePlayers,
      List<PlayerPerMatchEntity> awayPlayers,
      ) {
    // Always reinitialize positions for the current match
    _initializePlayerPositions(homePlayers, awayPlayers);

    final fieldWidth = MediaQuery.of(context).size.width;
    final fieldHeight = 1900.h;

    return SizedBox(
      width: fieldWidth,
      height: fieldHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildFieldBackground(),
          CustomPaint(
            size: Size(fieldWidth, fieldHeight),
            painter: FieldDrawingPainter(
              drawings,
              [],
              DrawingMode.none,
              Colors.red,
              null,
            ),
          ),
          ...homePlayerPositions.map(
                (position) => Positioned(
              left: position.x,
              top: position.y,
              child: GestureDetector(
                onTap: () {
                  if (position.player.id != null) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PlayerStatsModal(
                        matchId: widget.matchId,
                        playerId: position.player.id!,
                        playerName: position.player.name ?? 'Unknown Player',
                      ),
                    );
                  }
                },
                child: _buildPlayerWidget(position),
              ),
            ),
          ),
          ...awayPlayerPositions.map(
                (position) => Positioned(
              left: position.x,
              top: position.y,
              child: GestureDetector(
                onTap: () {
                  if (position.player.id != null) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PlayerStatsModal(
                        matchId: widget.matchId,
                        playerId: position.player.id!,
                        playerName: position.player.name ?? 'Unknown Player',
                      ),
                    );
                  }
                },
                child: _buildPlayerWidget(position),
              ),
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
      top: isHomeTeam ? -5.h : 1589.h,
      child: Container(
        height: 300.h,
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
      top: isHomeTeam ? -5.h : 1797.h,
      child: Container(
        height: 90.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      Map<String, List<PlayerPerMatchEntity>> players,
      Map<String, ManagerEntity?> managers,
      ) {
    final homePlayers = players['home'] ?? [];
    final awayPlayers = players['away'] ?? [];
    final homeManager = managers['homeManager'];
    final awayManager = managers['awayManager'];

    final homeStarting = homePlayers.where((p) => !p.substitute).toList();
    final awayStarting = awayPlayers.where((p) => !p.substitute).toList();
    final homeSubs = homePlayers.where((p) => p.substitute).toList();
    final awaySubs = awayPlayers.where((p) => p.substitute).toList();

    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 1900.h,
              child: _buildFootballField(homeStarting, awayStarting),
            ),
            SizedBox(height: 60.h),
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

  Widget _buildSubstitutesSection(
      ManagerEntity? homeManager,
      List<PlayerPerMatchEntity> homeSubs,
      ManagerEntity? awayManager,
      List<PlayerPerMatchEntity> awaySubs,
      ) {
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
        _buildSubsList('away_substitutes'.tr, awaySubs, Colors.red),
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

  @override
  Widget build(BuildContext context) {
    // Check if matchId changed since last build
    if (_lastMatchId != widget.matchId) {
      _lastMatchId = widget.matchId;
      homePlayerPositions.clear();
      awayPlayerPositions.clear();
      drawings.clear();
      _initializeData();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FieldEditScreen(
                matchId: widget.matchId,
                homePlayers: homePlayerPositions,
                awayPlayers: awayPlayerPositions,
              ),
            ),
          ).then((updatedData) {
            if (updatedData != null) {
              setState(() {
                homePlayerPositions = updatedData['home'];
                awayPlayerPositions = updatedData['away'];
                drawings = updatedData['drawings'] ?? [];
              });
            }
          });
        },
        child: const Icon(Icons.edit),
      ),
      body: BlocBuilder<PlayerPerMatchBloc, PlayerPerMatchState>(
        builder: (context, playerState) {
          return BlocBuilder<ManagerBloc, ManagerState>(
            builder: (context, managerState) {
              if (_playerBloc.isMatchCached(widget.matchId) &&
                  _managerBloc.isMatchCached(widget.matchId)) {
                final cachedPlayers = _playerBloc.getCachedPlayers(widget.matchId)!;
                final cachedManagers = _managerBloc.getCachedManagers(widget.matchId)!;
                return _buildContent(cachedPlayers, cachedManagers);
              }

              if (playerState is PlayerPerMatchLoading || managerState is ManagerLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }

              if (playerState is PlayerPerMatchError || managerState is ManagerError) {
                final errorMessage = playerState is PlayerPerMatchError
                    ? playerState.message
                    : (managerState as ManagerError).message;
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.w),
                    child: ReusableText(
                      text: errorMessage.tr,
                      textSize: 100.sp,
                      textColor: Theme.of(context).colorScheme.onSurface,
                      textFontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (playerState is PlayerPerMatchSuccess && managerState is ManagerSuccess) {
                return _buildContent(playerState.players, managerState.managers);
              }

              return Center(
                child: ReusableText(
                  text: 'waiting_for_lineups'.tr,
                  textSize: 100.sp,
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
              );
            },
          );
        },
      ),
    );
  }
}