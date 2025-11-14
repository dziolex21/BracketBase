import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tournament_app/configs/color_data.dart';

final String quizId = "Quiz1";
bool hasVoted = false;

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final docRefVotes = FirebaseFirestore.instance.collection(quizId).doc("votes");
  final docRefLobby = FirebaseFirestore.instance.collection(quizId).doc("lobby");

  int expectedVotes = 0;

  @override
  void initState() {
    super.initState();
    _resetVotes();
    _loadPlayerCount();
  }

  /// 🔁 Resetuje dane głosowania w Firestore i lokalnie
  Future<void> _resetVotes() async {
    hasVoted = false;
    _VoteOptionCardState.selectedOption = null;

    await docRefVotes.set({
      'optionA': 0,
      'optionB': 0,
      'totalVotes': 0,
    }, SetOptions(merge: false)); // nadpisuje cały dokument
  }

  /// 👥 Pobiera liczbę graczy z dokumentu Lobby
  Future<void> _loadPlayerCount() async {
    final snapshot = await docRefLobby.get();
    if (snapshot.exists) {
      final data = snapshot.data()!;
      setState(() {
        expectedVotes = data.length;
      });
    } else {
      setState(() {
        expectedVotes = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purple5,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: docRefVotes.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || expectedVotes == 0) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final votesA = data['optionA'] ?? 0;
            final votesB = data['optionB'] ?? 0;
            final totalVotes = votesA + votesB;

            // ✅ Jeśli wszyscy zagłosowali -> przejście do wyników
            if (totalVotes >= expectedVotes) {
              Future.microtask(() {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(
                      votesA: votesA,
                      votesB: votesB,
                    ),
                  ),
                );
              });
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
                      ),
                      VoteOptionCard(
                        title: 'Option B',
                        imagePath: 'assets/placeholder_image.png',
                        votes: votesB,
                        optionKey: 'optionB',
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

  const VoteOptionCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.votes,
    required this.optionKey,
  });

  @override
  State<VoteOptionCard> createState() => _VoteOptionCardState();
}

class _VoteOptionCardState extends State<VoteOptionCard> {
  static String? selectedOption;

  void vote() async {
    if (hasVoted) return;

    hasVoted = true;
    selectedOption = widget.optionKey;

    final docRef = FirebaseFirestore.instance.collection(quizId).doc("votes");

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      transaction.update(docRef, {
        widget.optionKey: (data[widget.optionKey] ?? 0) + 1,
        'totalVotes': (data['totalVotes'] ?? 0) + 1,
      });
    });

    setState(() {});
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
    final winner = votesA > votesB ? 'Option A wins!' : 'Option B wins!';

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
