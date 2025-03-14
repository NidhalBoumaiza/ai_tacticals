import 'package:analysis_ai/core/utils/navigation_with_transition.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart'; // Added for translations
import 'package:shimmer/shimmer.dart';

import '../../../../../core/widgets/reusable_text.dart';
import '../../../domain layer/entities/player_entity.dart';
import '../../bloc/players_bloc/players_bloc.dart';
import '../../widgets/home page widgets/standing screen widgets/country_flag_widget.dart';
import '../player info screen/player_info_screen.dart';

class SquadScreen extends StatefulWidget {
  final int teamId;

  const SquadScreen({super.key, required this.teamId});

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  late final PlayersBloc _playersBloc;

  @override
  void initState() {
    super.initState();
    _playersBloc = context.read<PlayersBloc>();
    _initializeData();
  }

  @override
  void didUpdateWidget(SquadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId) {
      _initializeData();
    }
  }

  void _initializeData() {
    if (!_playersBloc.isTeamCached(widget.teamId)) {
      _playersBloc.add(GetAllPlayersEvent(teamId: widget.teamId));
    }
  }

  Color _getPositionColor(String position) {
    return switch (position) {
      'Goalkeeper' => const Color(0xffdcb050),
      'Defense' => const Color(0xff7a85e5),
      'Midfield' => const Color(0xff4abc55),
      'Forward' => const Color(0xffe03b3c),
      _ => const Color(0xff8a8e90),
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayersBloc, PlayersState>(
      builder: (context, state) {
        if (_playersBloc.isTeamCached(widget.teamId)) {
          final cachedPlayers = _playersBloc.getCachedPlayers(widget.teamId)!;
          return _buildGroupedPlayersList(cachedPlayers);
        }

        if (state is PlayersLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        } else if (state is PlayersError) {
          return Center(
            child: ReusableText(
              text: state.message,
              textSize: 100.sp,
              textColor: Colors.red,
              textFontWeight: FontWeight.w600,
            ),
          );
        } else if (state is PlayersLoaded) {
          return _buildGroupedPlayersList(state.players);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGroupedPlayersList(List<PlayerEntityy> players) {
    // Fixed typo: PlayerEntityy -> PlayerEntity
    final groupedPlayers = <String, List<PlayerEntityy>>{};

    for (var player in players) {
      final position = player.position ?? 'Other Position';
      groupedPlayers.putIfAbsent(position, () => []).add(player);
    }

    const positionOrder = [
      'Goalkeeper',
      'Defense',
      'Midfield',
      'Forward',
      'Other Position',
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xff161d1f),
            borderRadius: BorderRadius.circular(55.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 30.w),
            child: Column(
              children: [
                ...positionOrder
                    .where((pos) => groupedPlayers.containsKey(pos))
                    .map((position) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 20.h, top: 30.h),
                            child: ReusableText(
                              text: position.tr.toLowerCase(),
                              textSize: 110.sp,
                              textColor: _getPositionColor(position),
                              textFontWeight: FontWeight.w600,
                            ),
                          ),
                          _buildPositionGroup(groupedPlayers[position]!),
                        ],
                      );
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionGroup(List<PlayerEntityy> players) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: players.length,
      separatorBuilder:
          (context, index) =>
              Divider(color: Colors.grey.shade800, height: 30.h),
      itemBuilder: (context, index) {
        final player = players[index];
        return GestureDetector(
          onTap: () {
            if (player.id != null && player.name != null) {
              navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                context,
                PlayerStatsScreen(
                  playerId: player.id!,
                  playerName: player.name!,
                ),
              );
            }
          },
          child: _buildPlayerRow(player),
        );
      },
    );
  }

  Widget _buildPlayerRow(PlayerEntityy player) {
    print("******************************");
    print(player);
    return Row(
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
                  color: Colors.grey.shade800,
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
                    cacheKey: player.id?.toString(),
                  ),
                ),
              ),
              SizedBox(width: 45.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text: player.name ?? 'na'.tr,
                      textSize: 100.sp,
                      textColor: const Color(0xffe4e9ea),
                      textFontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: player.shirtNumber != null ? 50.w : 65.w,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ReusableText(
                                text:
                                    player.shirtNumber != null
                                        ? player.shirtNumber.toString()
                                        : player.jerseyNumber != null
                                        ? player.jerseyNumber.toString()
                                        : 'na'.tr,
                                textSize: 90.sp,
                                textColor: Colors.white,
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 130.w,
                          child: ReusableText(
                            text:
                                player.age != null
                                    ? 'years'.tr.replaceAll(
                                      '{age}',
                                      player.age.toString(),
                                    )
                                    : 'na'.tr,
                            textSize: 90.sp,
                            textColor: Colors.white,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        SizedBox(width: 30.w),
                        CountryFlagWidget(
                          flag: player.countryAlpha2,
                          height: 15,
                          width: 15,
                        ),
                        SizedBox(width: 10.w),
                        SizedBox(
                          width: 80.w,
                          child: ReusableText(
                            text: player.countryAlpha3 ?? 'na'.tr,
                            textSize: 90.sp,
                            textColor: Colors.white,
                            textAlign: TextAlign.start,
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
    );
  }
}
