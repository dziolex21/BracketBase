import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tournament_app/configs/color_data.dart';

bool hasVoted = false;

class VotingScreen extends StatefulWidget {
  final String gameId;
  const VotingScreen({super.key, this.gameId = ""});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  DocumentReference<Map<String, dynamic>> get docRef =>
      FirebaseFirestore.instance.collection("tournaments").doc(widget.gameId);

  @override
  void initState() {
    super.initState();
    _resetVotes();
  }

  /// 🔁 Resetuje dane głosowania w Firestore i lokalnie
  Future<void> _resetVotes() async {
    hasVoted = false;
    _VoteOptionCardState.selectedOption = null;

    // Użyj `merge: true`, aby zaktualizować dokument bez usuwania istniejących pól,
    // takich jak `playersList`.
    await docRef.set({
      'optionA': 0,
      'optionB': 0,
    }, SetOptions(merge: true));
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
              return const Center(child: CircularProgressIndicator());
            }

            final votesA = data['optionA'] ?? 0;
            final votesB = data['optionB'] ?? 0;
            final totalVotes = votesA + votesB;

            // ✅ Jeśli wszyscy zagłosowali -> przejście do wyników
            if (totalVotes >= expectedVotes) {
              Future.microtask(() {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultScreen(
                        votesA: votesA,
                        votesB: votesB,
                      ),
                    ),
                  );
                }
              });
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

                // Sekcja głosowania
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      VoteOptionCard(
                        title: 'Option A',
                        imagePath: 'assets/placeholder_image.png',
                        votes: votesA,
                        optionKey: 'optionA',
                        gameId: widget.gameId,
                      ),
                      VoteOptionCard(
                        title: 'Option B',
                        imagePath: 'assets/placeholder_image.png',
                        votes: votesB,
                        optionKey: 'optionB',
                        gameId: widget.gameId,
                      ),
                    ],
                  ),
                ),

                // Licznik
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

class VoteOptionCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final int votes;
  final String optionKey;
  final String gameId;

  const VoteOptionCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.votes,
    required this.optionKey,
    required this.gameId
  });

  @override
  State<VoteOptionCard> createState() => _VoteOptionCardState();
}

class _VoteOptionCardState extends State<VoteOptionCard> {
  DocumentReference<Map<String, dynamic>> get docRef => FirebaseFirestore.instance.collection("tournaments").doc(widget.gameId);
  static String? selectedOption;

  void vote() async {
    if (hasVoted) return;

    setState(() {
      hasVoted = true;
      selectedOption = widget.optionKey;
    });

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      transaction.update(docRef, {
        widget.optionKey: (data[widget.optionKey] ?? 0) + 1,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedOption == widget.optionKey;

    return Expanded(
      child: GestureDetector(
        onTap: vote,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.purple1 // jaśniejszy kolor przy wybraniu
                : AppColors.purple3, // standardowy kolor
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
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Image.asset(widget.imagePath),
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
                  'Votes: ${widget.votes}',
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

class ResultScreen extends StatelessWidget {
  final int votesA;
  final int votesB;

  const ResultScreen({
    super.key,
    required this.votesA,
    required this.votesB,
  });

  @override
  Widget build(BuildContext context) {
    String getWinnerText() {
      if (votesA > votesB) return 'Option A wins!';
      if (votesB > votesA) return 'Option B wins!';
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
              'A: $votesA   |   B: $votesB',
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFFD2A2FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
