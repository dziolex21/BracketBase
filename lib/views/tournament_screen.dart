import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:tournament_app/configs/color_data.dart';

class TournamentScreen extends StatelessWidget {
  final Map<String, dynamic> bracket;

  const TournamentScreen({super.key, required this.bracket});

  @override
  Widget build(BuildContext context) {
    final rounds = bracket.keys.toList();

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
            for (int i = 0; i < rounds.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RoundColumn(
                  roundName: rounds[i],
                  players: List<Map<String, dynamic>>.from(bracket[rounds[i]]),
                  roundIndex: i,
                  totalRounds: rounds.length,
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
  final int roundIndex;
  final int totalRounds;

  const _RoundColumn({
    required this.roundName,
    required this.players,
    required this.roundIndex,
    required this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the vertical spacing between contestant cards in this round.
    // The spacing increases exponentially with each round (`roundIndex`) to align
    // the cards with the bracket lines that would connect them.
    // `pow(2, roundIndex)` doubles the spacing for each subsequent round.
    final spacing = pow(2, roundIndex).toDouble() * 30;

    // Calculate the height of the contestant cards for this round.
    // Cards get slightly taller in later rounds.
    final cardHeight = 80.0 + roundIndex * 10;

    // A Column widget to lay out the round's title and its contestants vertically.
    return Column(
      children: [
        // Display the name of the round (e.g., "Round 1", "Quarterfinals").
        Text(
          roundName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        // A small fixed space between the round title and the first card.
        const SizedBox(height: 12),
        // Loop through the list of players for this round and generate a card for each one.
        // The `...` is the spread operator, which inserts the generated list of widgets
        // into the parent `Column`'s `children` list.
        for (int i = 0; i < players.length; i++) ...[
          // Add the calculated `spacing` *before* each card except the first one.
          if (i > 0) SizedBox(height: spacing),
          _ContestantCard(
            name: players[i]['name'],
            pictureId: players[i]['picture_id'],
            height: cardHeight,
          ),
        ],
      ],
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
          // если картинка есть — показываем, иначе ?
          CircleAvatar(
            radius: height * 0.25,
            backgroundColor: AppColors.purple4,
            backgroundImage: AssetImage('assets/pic$pictureId.jpg'),
            onBackgroundImageError: (_, __) {},
            child: Image.asset(
              'assets/pic$pictureId.jpg',
              errorBuilder: (_, __, ___) =>
              const Text('?', style: TextStyle(fontSize: 28, color: Colors.white)),
            ),
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
