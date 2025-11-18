import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tournament_app/configs/color_data.dart';

class VotingScreen extends StatefulWidget {
  final String gameId;
  final bool isHost;
  const VotingScreen({super.key, this.gameId = "", this.isHost = false});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  DocumentReference<Map<String, dynamic>> get docRef =>
      FirebaseFirestore.instance.collection("tournaments").doc(widget.gameId);

  // State variables to track the user's vote locally
  bool _userHasVoted = false;
  String? _selectedOptionKey;

  @override
  void initState() {
    super.initState();
    if (widget.isHost) {
      _resetTournamentVotes();
    }
  }

  /// 🔁 Reset tournament votes in Firestore (Host only)
  Future<void> _resetTournamentVotes() async {
    // Also reset local state for the host
    setState(() {
      _userHasVoted = false;
      _selectedOptionKey = null;
    });

    await docRef.update({
      'optionA': 0,
      'optionB': 0,
    });
  }

  /// Handles the user's vote action
  void _handleVote(String optionKey) {
    if (_userHasVoted) {
      return; // Prevent multiple votes from the same user
    }

    setState(() {
      _userHasVoted = true;
      _selectedOptionKey = optionKey;
    });

    // Run a transaction to safely update the vote count
    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final currentVotes = snapshot.data()![optionKey] ?? 0;
      transaction.update(docRef, {optionKey: currentVotes + 1});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purple5,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: docRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final players = data['playersList'] as List? ?? [];
            final expectedVotes = players.length;

            if (expectedVotes == 0) {
              // This might happen temporarily if the lobby data is still loading
              return const Center(child: CircularProgressIndicator());
            }

            final votesA = data['optionA'] ?? 0;
            final votesB = data['optionB'] ?? 0;
            final totalVotes = votesA + votesB;

            // ✅ If everyone has voted -> navigate to results
            if (totalVotes >= expectedVotes) {
              Future.microtask(() {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultScreen(
                        votesA: votesA,
                        votesB: votesB,
                        gameId: widget.gameId,
                        isHost: widget.isHost,
                      ),
                    ),
                  );
                }
              });
              // Show a loader while navigating
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                const SizedBox(height: 180),
                const Text(
                  'Vote',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD2A2FF),
                  ),
                ),
                const SizedBox(height: 20),

                // Voting section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      VoteOptionCard(
                        title: 'Option A',
                        imagePath: 'assets/placeholder_image.png',
                        votes: votesA,
                        isSelected: _selectedOptionKey == 'optionA',
                        onTap: () => _handleVote('optionA'),
                      ),
                      VoteOptionCard(
                        title: 'Option B',
                        imagePath: 'assets/placeholder_image.png',
                        votes: votesB,
                        isSelected: _selectedOptionKey == 'optionB',
                        onTap: () => _handleVote('optionB'),
                      ),
                    ],
                  ),
                ),

                // Counter
                Padding(
                  padding: const EdgeInsets.only(bottom: 40, top: 20),
                  child: Text(
                    'Waiting for ${expectedVotes - totalVotes} votes...',
                    style: const TextStyle(
                      color: Color(0xFFB785F4),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// VoteOptionCard is now a StatelessWidget
class VoteOptionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final int votes;
  final bool isSelected;
  final VoidCallback onTap;

  const VoteOptionCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.votes,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.purple1 // Lighter color when selected
                : AppColors.purple3, // Standard color
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.purple3 : AppColors.purple4,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Image.asset(imagePath),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.purple3 : AppColors.purple4,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  'Votes: $votes',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultScreen extends StatefulWidget {
  final int votesA;
  final int votesB;
  final String gameId;
  final bool isHost;

  const ResultScreen({
    super.key,
    required this.votesA,
    required this.votesB,
    required this.gameId,
    required this.isHost,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  DocumentReference<Map<String, dynamic>> get docRef =>
      FirebaseFirestore.instance.collection("tournaments").doc(widget.gameId);

  // This method will be called by the host to signal returning to the tournament
  Future<void> _endVoting() async {
    await docRef.update({'isVotingStarted': false});
    // This pop will take the host back to the tournament screen
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // For non-hosts, we listen for the host's signal to go back
    if (!widget.isHost) {
      return StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            if (data['isVotingStarted'] == false) {
              // When the flag is false, pop back to the tournament screen
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              });
            }
          }
          // While waiting for the host, show the results
          return _buildResultsView();
        },
      );
    }

    // For the host, we show the results and the button to go back
    return _buildResultsView();
  }

  // Helper widget to build the result view UI to avoid repetition
  Widget _buildResultsView() {
    String getWinnerText() {
      if (widget.votesA > widget.votesB) return 'Option A wins!';
      if (widget.votesB > widget.votesA) return 'Option B wins!';
      return "It's a Tie!";
    }

    final winner = getWinnerText();

    return Scaffold(
      backgroundColor: AppColors.purple5,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              winner,
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'A: ${widget.votesA}   |   B: ${widget.votesB}',
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFFD2A2FF),
              ),
            ),
            const SizedBox(height: 50),
            // This button is only visible to the host
            if (widget.isHost)
              ElevatedButton(
                onPressed: _endVoting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple1,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'Back to Tournament',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
