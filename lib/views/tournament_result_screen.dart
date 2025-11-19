import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tournament_app/configs/color_data.dart';

class TournamentResultsScreen extends StatefulWidget {
  const TournamentResultsScreen({super.key});

  @override
  State<TournamentResultsScreen> createState() => _TournamentResultsScreenState();
}

class _TournamentResultsScreenState extends State<TournamentResultsScreen> {
  bool _isLoading = true;

  // Data for display. If name is empty, the spot is vacant.
  Map<String, dynamic> _winner = {'name': '', 'picture': ''};
  Map<String, dynamic> _runnerUp = {'name': '', 'picture': ''};
  List<Map<String, dynamic>> _semiFinalLosers = []; // 3-4 places

  @override
  void initState() {
    super.initState();
    _calculateIntermediateResults();
  }

  Future<void> _calculateIntermediateResults() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File jsonFile = File(p.join(tempDir.path, 'bracket.json'));

      if (!await jsonFile.exists()) {
        setState(() => _isLoading = false);
        return;
      }

      final String jsonString = await jsonFile.readAsString();
      final Map<String, dynamic> bracket = jsonDecode(jsonString);

      // --- 1. WINNER (Gold) ---
      // Taken from round "1"
      final List<dynamic> round1 = bracket['1'] ?? [];
      if (round1.isNotEmpty && round1[0]['name'] != '') {
        _winner = round1[0];
      }

      // --- 2. SECOND PLACE (Silver) ---
      // This is the one who is in "1/2" but NOT in "1".
      // But we can only determine them if the winner is already known.
      // If there's no winner, the final hasn't been played yet, and 2nd place is also unknown.
      if (_winner['name'] != '') {
        final List<dynamic> round1_2 = bracket['1/2'] ?? [];
        // Search for a player in 1/2 whose name does not match the winner's
        final runnerUpEntry = round1_2.firstWhere(
              (p) => p['name'] != '' && p['name'] != _winner['name'],
          orElse: () => null,
        );
        if (runnerUpEntry != null) {
          _runnerUp = runnerUpEntry;
        }
      }

      // --- 3. THIRD-FOURTH PLACES (Bronze) ---
      // These are the ones who were in "1/4" but did NOT make it to "1/2".
      final List<dynamic> round1_4 = bracket['1/4'] ?? [];
      final List<dynamic> round1_2 = bracket['1/2'] ?? [];

      // Collect the names of those who advanced to the semifinals (to 1/2)
      final Set<String> promotedToSemiNames = round1_2
          .map((e) => e['name'] as String)
          .where((name) => name.isNotEmpty)
          .toSet();

      // Filter 1/4: take those who have a name AND are not in the list of promoted players
      final List<Map<String, dynamic>> losers = [];
      for (var player in round1_4) {
        final String name = player['name'] ?? '';
        // Condition: The name exists, and this name is not in the next round.
        // BUT! If there are still empty slots in the next round (1/2),
        // we can't be sure that this person has been eliminated (maybe they haven't played yet).
        // Therefore, we only show those in the list who are definitely eliminated,
        // or (for aesthetics) just fill with placeholders if the tournament is in progress.

        if (name.isNotEmpty && !promotedToSemiNames.contains(name)) {
          // Check if the 1/2 round is fully populated.
          // If there are empty slots in 1/2, this player might just not have played their 1/4 match yet.
          // For simplicity: we consider those who did not advance as bronze medalists
          // ONLY if we are certain about the composition of the 1/2 round.

          // For the purpose of this task: let's just show those who definitely did not advance.
          losers.add(player);
        }
      }
      _semiFinalLosers = losers;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.purple5,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.purple5,
      appBar: AppBar(
        title: const Text("Tournament Standings"),
        backgroundColor: AppColors.purple3,
        centerTitle: true,
        // Remove the default back button and create our own "Home" button
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, size: 30, color: Colors.white),
            onPressed: () {
              // Return to the very beginning
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const Text(
              "CHAMPION",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),

            // --- WINNER CARD (or placeholder) ---
            _buildWinnerDisplay(_winner),

            const SizedBox(height: 50),

            // --- LEADERBOARD ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.purple4,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purple2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0, left: 8),
                    child: Text(
                      "Podium",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 2nd Place (Silver)
                  _buildRankRow(2, _runnerUp, const Color(0xFFC0C0C0)),

                  // 3rd and 4th Places (Bronze)
                  // If the list is empty (start of the tournament), show two placeholders
                  if (_semiFinalLosers.isEmpty) ...[
                    _buildRankRow(3, {'name': '', 'picture': ''}, const Color(0xFFCD7F32)),
                    _buildRankRow(3, {'name': '', 'picture': ''}, const Color(0xFFCD7F32)),
                  ] else ...[
                    for (var player in _semiFinalLosers)
                      _buildRankRow(3, player, const Color(0xFFCD7F32)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the Champion (Large)
  Widget _buildWinnerDisplay(Map<String, dynamic> player) {
    final String name = player['name'] ?? '';
    final String picture = player['picture'] ?? '';
    final bool hasWinner = name.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Glow (only if there is a winner)
        if (hasWinner)
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

        // Avatar or Placeholder
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.purple3, // Placeholder background
            border: Border.all(
                color: hasWinner ? const Color(0xFFFFD700) : AppColors.purple2, // Golden or dim border
                width: 6
            ),
          ),
          child: ClipOval(
            child: _buildImage(picture),
          ),
        ),

        // Crown (only if there is a winner)
        if (hasWinner)
          const Positioned(
            top: -35,
            child: Text("👑", style: TextStyle(fontSize: 50)),
          ),

        // Name or "TBD"
        Positioned(
          bottom: -50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.purple2,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: hasWinner ? const Color(0xFFFFD700) : AppColors.purple1,
                  width: 2
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Text(
              hasWinner ? name : "???",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: hasWinner ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Row widget (2nd, 3rd place)
  Widget _buildRankRow(int rank, Map<String, dynamic> player, Color rankColor) {
    final String name = player['name'] ?? '';
    final String picture = player['picture'] ?? '';
    final bool isKnown = name.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purple3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Medal
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.purple5,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isKnown ? rankColor : Colors.grey.withOpacity(0.3),
                  width: 2
              ),
            ),
            child: Center(
              child: Text(
                rank == 3 ? "3-4" : "$rank",
                style: TextStyle(
                  color: isKnown ? rankColor : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: rank == 3 ? 10 : 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purple4,
              border: Border.all(color: AppColors.purple1),
            ),
            child: ClipOval(
              child: _buildImage(picture, isSmall: true),
            ),
          ),
          const SizedBox(width: 16),

          // Name
          Expanded(
            child: Text(
              isKnown ? name : "???",
              style: TextStyle(
                color: isKnown ? Colors.white : Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path, {bool isSmall = false}) {
    // If the path is missing or empty - show a question mark
    if (path.isEmpty) {
      return Container(
        color: AppColors.purple4,
        child: Center(
          child: Text(
            "?",
            style: TextStyle(
                color: Colors.white24,
                fontSize: isSmall ? 20 : 50,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    } else {
      return Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_,__,___) => const Icon(Icons.error)
      );
    }
  }
}