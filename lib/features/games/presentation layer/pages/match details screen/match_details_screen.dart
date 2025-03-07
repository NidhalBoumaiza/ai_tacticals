import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data layer/models/one_match_statics_entity.dart';
import '../../bloc/match details bloc/match_details_bloc.dart';

class MatchDetailsScreen extends StatelessWidget {
  final int matchId;

  const MatchDetailsScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF33353B), // Dark gray background
      appBar: AppBar(
        backgroundColor: const Color(0xFF33353B),
        elevation: 0,
        title: const Text('Match Details', style: TextStyle(color: Color(0xFFF3D07E))),
        iconTheme: const IconThemeData(color: Color(0xFFF3D07E)),
      ),
      body: BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
        builder: (context, state) {
          if (state is MatchDetailsInitial) {
            BlocProvider.of<MatchDetailsBloc>(context)
                .add(GetMatchDetailsEvent(matchId: matchId));
            return const SizedBox.shrink();
          } else if (state is MatchDetailsLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF3D07E)));
          } else if (state is MatchDetailsLoaded) {
            return MatchDetailsContent(matchDetails: state.matchDetails);
          } else if (state is MatchDetailsError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Color(0xFFF3D07E), fontSize: 16),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class MatchDetailsContent extends StatelessWidget {
  final MatchDetails matchDetails;

  const MatchDetailsContent({super.key, required this.matchDetails});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFF3D07E).withOpacity(0.2), const Color(0xFF33353B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(matchDetails.homeTeam.shortName,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${matchDetails.homeScore.current} - ${matchDetails.awayScore.current}',
                        style: const TextStyle(
                            color: Color(0xFFF3D07E), fontSize: 36, fontWeight: FontWeight.bold)),
                    Text(matchDetails.awayTeam.shortName,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(matchDetails.status,
                    style: const TextStyle(color: Color(0xFFF1D778), fontSize: 16)),
              ],
            ),
          ),
          // Match Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Match Information',
                    style: TextStyle(
                        color: Color(0xFFF3D07E), fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildInfoRow('Tournament', matchDetails.tournamentName),
                _buildInfoRow('Venue', matchDetails.venueName),
                _buildInfoRow('Referee', matchDetails.refereeName),
                _buildInfoRow('Date', DateFormat('dd MMM yyyy, HH:mm').format(matchDetails.startTime)),
              ],
            ),
          ),
          // Statistics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Match Statistics',
                    style: TextStyle(
                        color: Color(0xFFF3D07E), fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...matchDetails.statistics
                    .where((stat) => stat.period == 'ALL') // Show only overall stats for simplicity
                    .expand((stat) => stat.groups)
                    .map((group) => _buildStatsGroup(group)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Color(0xFFF1D778), fontSize: 16)),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGroup(StatisticsGroup group) {
    return Card(
      color: const Color(0xFF33353B).withOpacity(0.9),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF3D07E), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.groupName,
                style: const TextStyle(
                    color: Color(0xFFF3D07E), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...group.items.map((item) => _buildStatsItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsItem(StatisticsItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(item.homeValue,
                style: TextStyle(
                    color: item.compareCode == 1 ? const Color(0xFFF3D07E) : Colors.white,
                    fontSize: 16)),
          ),
          Expanded(
            flex: 3,
            child: Text(item.name,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(item.awayValue,
                style: TextStyle(
                    color: item.compareCode == 2 ? const Color(0xFFF3D07E) : Colors.white,
                    fontSize: 16),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}