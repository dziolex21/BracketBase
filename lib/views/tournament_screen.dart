import 'package:flutter/material.dart';
import 'dart:math';
import 'package:tournament_app/configs/color_data.dart';

class TournamentScreen extends StatelessWidget {
  final Map<String, dynamic> bracket;

  const TournamentScreen({super.key, required this.bracket});

  int _nextPowerOfTwo(int n) {
    int power = 1;
    while (power < n) power <<= 1;
    return power;
  }

  @override
  Widget build(BuildContext context) {
    final rounds = bracket.keys.toList();
    final firstRoundPlayers =
    List<Map<String, dynamic>>.from(bracket[rounds.first] ?? []);
    final totalSlots = _nextPowerOfTwo(max(1, firstRoundPlayers.length));

    return Scaffold(
      backgroundColor: AppColors.purple5,
      appBar: AppBar(
        title: const Text('Tournament'),
        backgroundColor: AppColors.purple3,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < rounds.length; i++) // i represents the round index: 0, 1, 2...
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RoundColumn(
                  roundName: rounds[i],
                  players:
                  List<Map<String, dynamic>>.from(bracket[rounds[i]] ?? []),
                  totalSlots: totalSlots, // This is the TOTAL number of slots in the first round (e.g., 4, 8, 16...).
                  roundIndex: i, // The index of the current round.
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundColumn extends StatelessWidget {
  final String roundName;
  final List<Map<String, dynamic>> players;
  final int totalSlots; // Total slots in the first round (e.g., 4, 8, 16).
  final int roundIndex; // The index of this round (0, 1, 2...).

  const _RoundColumn({
    required this.roundName,
    required this.players,
    required this.totalSlots,
    required this.roundIndex,
  });

  @override
  Widget build(BuildContext context) {
    const double totalHeight = 800;
    const double cardHeight = 80;

    // --- CORE LOGIC FOR DYNAMIC BRACKET SPACING ---
    // Calculate the number of slots for THIS specific round.
    // The number of slots halves with each subsequent round.
    // Round 0: totalSlots / 2^0 = totalSlots (e.g., 8)
    // Round 1: totalSlots / 2^1 = totalSlots / 2 (e.g., 4)
    // Round 2: totalSlots / 2^2 = totalSlots / 4 (e.g., 2)
    final int slotsInThisRound = (totalSlots / pow(2, roundIndex)).ceil();

    // Generate vertical positions (as fractions of totalHeight) based on the number of slots in THIS round.
    // This centers each card within its designated vertical slice of the column.
    List<double> positions = List.generate(
      slotsInThisRound, // Use the calculated slots for this round.
          (i) => (i * 2 + 1) / (2 * slotsInThisRound), // The formula for calculating center points.
    );
    // For 4 slots, positions are: [1/8, 3/8, 5/8, 7/8]
    // For 2 slots, positions are: [1/4, 3/4]
    // For 1 slot, position is:    [1/2]
    // ----------------------------------------------------

    return SizedBox(
      width: 150,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                roundName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Iterate up to the number of slots in this round to create placeholders for matchups.
          for (int i = 0; i < slotsInThisRound; i++)
            Positioned(
              top: totalHeight * positions[i] - cardHeight / 2,
              left: 0,
              right: 0,
              child: (i < players.length) // If a player exists for this slot, show their card.
                  ? _ContestantCard(
                name: players[i]['name'] ?? '???',
                pictureId: (players[i]['picture_id'] is int)
                    ? players[i]['picture_id']
                    : 0,
                height: cardHeight,
              )
                  : const Opacity( // Otherwise, show an invisible placeholder to maintain spacing.
                opacity: 0.0,
                child: _ContestantCard(
                    name: 'empty', pictureId: 0, height: cardHeight),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContestantCard extends StatelessWidget {
  final String name;
  final int pictureId;
  final double height;

  const _ContestantCard({
    required this.name,
    required this.pictureId,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = height * 0.25;

    return Container(
      width: 120,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.purple3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple1, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple2.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: AppColors.purple4,
            backgroundImage: (pictureId > 0)
                ? AssetImage('assets/pic$pictureId.jpg')
                : null,
            onBackgroundImageError: (_, __) {},
            child: (pictureId > 0)
                ? null
                : const Text('?', style: TextStyle(fontSize: 28, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}