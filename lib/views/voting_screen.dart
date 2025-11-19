import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/configs/settings.dart';
import 'package:tournament_app/views/tournament_screen.dart';

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

  bool _userHasVoted = false;
  String? _selectedOptionKey;
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await AppSettings.load();
  }

  void _handleVote(String optionKey) async {
    if (widget.isHost) {
      String randomOption = Random().nextDouble() > 0.5 ? 'optionA' : 'optionB';
      await docRef.update({
        'tieOption': _settings.selectedTiebreaker == 0 ? randomOption : optionKey
      });
    }
    if (_userHasVoted) return;

    setState(() {
      _userHasVoted = true;
      _selectedOptionKey = optionKey;
    });

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
            final playersList = data['playersList'] as List? ?? [];
            // Safety: If playersList is empty/null, assume 1 vote to prevent infinite loop
            final expectedVotes = playersList.isEmpty ? 1 : playersList.length;

            // --- GET MATCH INFO ---
            final currentMatch = data['currentMatch'] as Map<String, dynamic>?;
            String nameA = "Option A";
            String imageA = "";
            String nameB = "Option B";
            String imageB = "";

            if (currentMatch != null) {
              final p1 = currentMatch['player1'];
              final p2 = currentMatch['player2'];
              if (p1 != null) {
                nameA = p1['name'] ?? "Player 1";
                imageA = p1['picture'] ?? "";
              }
              if (p2 != null) {
                nameB = p2['name'] ?? "Player 2";
                imageB = p2['picture'] ?? "";
              }
            }

            final votesA = data['optionA'] ?? 0;
            final votesB = data['optionB'] ?? 0;
            final totalVotes = votesA + votesB;

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
                        tieOption: data['tieOption'] ?? 'optionA',
                        matchData: currentMatch,
                      ),
                    ),
                  );
                }
              });
              // Show a simple loader while redirecting
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Vote',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFD2A2FF)),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      VoteOptionCard(
                        title: nameA,
                        imagePath: imageA,
                        votes: votesA,
                        isSelected: _selectedOptionKey == 'optionA',
                        onTap: () => _handleVote('optionA'),
                      ),
                      VoteOptionCard(
                        title: nameB,
                        imagePath: imageB,
                        votes: votesB,
                        isSelected: _selectedOptionKey == 'optionB',
                        onTap: () => _handleVote('optionB'),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Waiting for ${max(0, expectedVotes - totalVotes)} votes...',
                    style: const TextStyle(color: Color(0xFFB785F4), fontSize: 22, fontWeight: FontWeight.bold),
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

class VoteOptionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final int votes;
  final bool isSelected;
  final VoidCallback onTap;

  const VoteOptionCard({super.key, required this.title, required this.imagePath, required this.votes, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget buildImage() {
      if (imagePath.isEmpty) return const Icon(Icons.person, size: 50, color: Colors.white);
      if (imagePath.startsWith('assets/')) return Image.asset(imagePath);
      return Image.file(File(imagePath), errorBuilder: (_,__,___) => const Icon(Icons.error));
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purple1 : AppColors.purple3,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
          ),
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              Expanded(child: Padding(padding: const EdgeInsets.all(8.0), child: buildImage())),
              Container(
                padding: const EdgeInsets.all(8),
                child: Text('Votes: $votes', style: const TextStyle(color: Colors.white)),
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
  final String tieOption;
  final Map<String, dynamic>? matchData;

  const ResultScreen({
    super.key,
    required this.votesA,
    required this.votesB,
    required this.gameId,
    required this.isHost,
    required this.tieOption,
    this.matchData,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  DocumentReference<Map<String, dynamic>> get docRef =>
      FirebaseFirestore.instance.collection("tournaments").doc(widget.gameId);

  bool _isUpdating = false;

  Future<void> _processMatchResult() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final bool optionAWins = widget.votesA > widget.votesB;
      final bool isTie = widget.votesA == widget.votesB;

      Map<String, dynamic> winnerData;
      if (isTie) {
        winnerData = (widget.tieOption == 'optionA')
            ? widget.matchData!['player1']
            : widget.matchData!['player2'];
      } else {
        winnerData = optionAWins
            ? widget.matchData!['player1']
            : widget.matchData!['player2'];
      }

      final Directory tempDir = await getTemporaryDirectory();
      final File jsonFile = File(p.join(tempDir.path, 'bracket.json'));

      if (!await jsonFile.exists()) {
        throw Exception("Bracket file not found");
      }

      final String jsonString = await jsonFile.readAsString();
      Map<String, dynamic> bracket = jsonDecode(jsonString);

      final String nextRound = widget.matchData!['nextRound'];
      final int nextIndex = widget.matchData!['nextRoundIndex'];

      if (bracket.containsKey(nextRound)) {
        List<dynamic> nextRoundList = bracket[nextRound];
        if (nextIndex < nextRoundList.length) {
          nextRoundList[nextIndex] = winnerData;
        }
        bracket[nextRound] = nextRoundList;
      }

      final String updatedJsonString = jsonEncode(bracket);
      await jsonFile.writeAsString(updatedJsonString);

      await docRef.update({
        'bracketData': updatedJsonString,
        'isVotingStarted': false,
      });

    } catch (e) {
      print("Error updating bracket: $e");
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String winnerName = "???";
    if (widget.matchData != null) {
      if (widget.votesA > widget.votesB) {
        winnerName = widget.matchData!['player1']['name'];
      } else if (widget.votesB > widget.votesA) {
        winnerName = widget.matchData!['player2']['name'];
      } else {
        winnerName = (widget.tieOption == 'optionA')
            ? widget.matchData!['player1']['name']
            : widget.matchData!['player2']['name'];
      }
    }

    return StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            if (data['isVotingStarted'] == false) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TournamentScreen(
                        tournamentId: widget.gameId,
                        isHost: widget.isHost,
                      ),
                    ),
                  );
                }
              });
              return const Scaffold(
                  backgroundColor: AppColors.purple5,
                  body: Center(child: CircularProgressIndicator()));
            }
          }

          return Scaffold(
            backgroundColor: AppColors.purple5,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Winner:", style: TextStyle(color: Colors.white70, fontSize: 20)),
                  const SizedBox(height: 10),
                  Text(
                    winnerName,
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    '${widget.votesA}   vs   ${widget.votesB}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xFFD2A2FF),
                    ),
                  ),
                  const SizedBox(height: 50),
                  if (widget.isHost)
                    _isUpdating
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _processMatchResult,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple1,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: const Text(
                        'Next Match / Back to Bracket',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
    );
  }
}