import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/views/voting_screen.dart';
import 'package:tournament_app/views/tournament_result_screen.dart';

class TournamentScreen extends StatefulWidget {
  final bool isHost;
  final String tournamentId;
  final String? currentPlayerName;

  const TournamentScreen({
    super.key,
    this.isHost = false,
    this.tournamentId = "",
    this.currentPlayerName,
  });

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  Map<String, dynamic>? _bracket;
  bool _isLoading = true;
  String? _error;

  // Mapping logic for bracket progression
  final Map<String, String> _roundProgression = {
    '1/16': '1/8',
    '1/8': '1/4',
    '1/4': '1/2',
    '1/2': '1',
    '1': 'winner'
  };

  @override
  void initState() {
    super.initState();
    _loadLocalBracket();
  }

  Future<void> _loadLocalBracket() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File jsonFile = File(p.join(tempDir.path, 'bracket.json'));

      if (await jsonFile.exists()) {
        final String jsonString = await jsonFile.readAsString();
        setState(() {
          _bracket = jsonDecode(jsonString);
          _isLoading = false;
        });
      } else {
        // Wait for Firestore sync if local file is missing
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load tournament data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLocalBracket(String jsonString) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File jsonFile = File(p.join(tempDir.path, 'bracket.json'));
      await jsonFile.writeAsString(jsonString);

      if (mounted) {
        setState(() {
          _bracket = jsonDecode(jsonString);
        });
      }
    } catch (e) {
      print("Error updating local bracket: $e");
    }
  }

  /// Logic to find the next playable match
  Map<String, dynamic>? _findNextReadyMatch() {
    if (_bracket == null) return null;

    final List<String> roundOrder = ['1/16', '1/8', '1/4', '1/2', '1'];

    for (String roundName in roundOrder) {
      if (!_bracket!.containsKey(roundName)) continue;
      if (roundName == '1') continue; // Finals handled separately

      final List<dynamic> currentRoundPlayers = _bracket![roundName];
      final String nextRoundName = _roundProgression[roundName]!;

      if (!_bracket!.containsKey(nextRoundName)) continue;
      final List<dynamic> nextRoundPlayers = _bracket![nextRoundName];

      // Check pairs
      for (int i = 0; i < currentRoundPlayers.length; i += 2) {
        if (i + 1 >= currentRoundPlayers.length) break;

        final p1 = currentRoundPlayers[i];
        final p2 = currentRoundPlayers[i + 1];

        // Check if both players exist
        bool p1Ready = p1['name'] != null && (p1['name'] as String).isNotEmpty;
        bool p2Ready = p2['name'] != null && (p2['name'] as String).isNotEmpty;

        if (p1Ready && p2Ready) {
          // Check if the destination slot is empty
          int nextRoundIndex = i ~/ 2;
          if (nextRoundIndex < nextRoundPlayers.length) {
            final nextSlot = nextRoundPlayers[nextRoundIndex];
            bool nextSlotEmpty = nextSlot['name'] == null || (nextSlot['name'] as String).isEmpty;

            if (nextSlotEmpty) {
              return {
                'round': roundName,
                'nextRound': nextRoundName,
                'indexP1': i,
                'indexP2': i + 1,
                'nextRoundIndex': nextRoundIndex,
                'player1': p1,
                'player2': p2,
              };
            }
          }
        }
      }
    }
    return null;
  }

  Future<void> _startNextVotingRound() async {
    final matchData = _findNextReadyMatch();

    if (matchData != null) {
      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .update({
        'currentMatch': matchData,
        'isVotingStarted': true,
        'optionA': 0,
        'optionB': 0,
        'tieOption': '',
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No more matches found. Tournament might be ready to finish!"))
      );
    }
  }

  Future<void> _handleLeaveTournament() async {
    final docRef = FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId);
    try {
      if (widget.isHost) {
        await docRef.delete();
      } else {
        if (widget.currentPlayerName != null) {
          await docRef.update({'playersList': FieldValue.arrayRemove([widget.currentPlayerName])});
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) { /*...*/ }
  }

  void _showLeaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.purple4,
          title: const Text("Leave Tournament?", style: TextStyle(color: Colors.white)),
          content: Text(
            widget.isHost
                ? "As the host, leaving will end the tournament for everyone."
                : "Are you sure you want to leave this tournament?",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Leave", style: TextStyle(color: AppColors.purple1, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                _handleLeaveTournament();
              },
            ),
          ],
        );
      },
    );
  }

  int _nextPowerOfTwo(int n) {
    int power = 1;
    while (power < n) power <<= 1;
    return power;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.purple5,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- RESTORED BRACKET CALCULATION LOGIC ---
    if (_bracket == null) return const Scaffold(backgroundColor: AppColors.purple5, body: Center(child: Text("No Data", style: TextStyle(color: Colors.white))));

    final rounds = _bracket!.keys.toList();
    final firstRoundPlayers = List<Map<String, dynamic>>.from(_bracket![rounds.first] ?? []);

    int totalContestants = firstRoundPlayers.length;
    if (rounds.length > 1) {
      final List<Map<String, dynamic>> secondRoundSlots = List<Map<String, dynamic>>.from(_bracket![rounds[1]] ?? []);
      final int byes = secondRoundSlots.where((player) => player['name'] != null && (player['name'] as String).isNotEmpty).length;
      totalContestants += byes;
    }

    final totalSlots = _nextPowerOfTwo(max(1, totalContestants));
    const double horizontalPadding = 16.0;
    // ------------------------------------------

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;

            if (data == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.of(context).pop(); });
            } else {
              // 1. Sync Bracket
              if (data.containsKey('bracketData')) {
                final String serverBracketStr = data['bracketData'];
                // Simple check to avoid infinite loops if data is identical
                if (jsonEncode(_bracket) != serverBracketStr) {
                  _updateLocalBracket(serverBracketStr);
                }
              }

              // 2. Navigation
              if (data['isVotingStarted'] == true) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => VotingScreen(gameId: widget.tournamentId, isHost: widget.isHost)),
                    );
                  }
                });
              } else if (data['isTournamentFinished'] == true) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const TournamentResultsScreen()),
                    );
                  }
                });
              }
            }
          } else if (snapshot.connectionState == ConnectionState.active && !snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.of(context).pop(); });
          }

          bool isMatchReady = widget.isHost && _findNextReadyMatch() != null;
          bool isTournamentDone = widget.isHost && !isMatchReady;

          return WillPopScope(
            onWillPop: () async { _showLeaveConfirmationDialog(); return false; },
            child: Scaffold(
              backgroundColor: AppColors.purple5,
              appBar: AppBar(
                title: const Text('Tournament'),
                backgroundColor: AppColors.purple3,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: _showLeaveConfirmationDialog),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(20.0),
                      minScale: 0.1,
                      maxScale: 3.0,
                      constrained: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < rounds.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: _RoundColumn(
                                  roundName: rounds[i],
                                  players: List<Map<String, dynamic>>.from(_bracket![rounds[i]] ?? []),
                                  totalSlots: totalSlots, // Passing dynamic totalSlots
                                  roundIndex: i,
                                  horizontalPadding: horizontalPadding,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.isHost,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: AppColors.purple4,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          if (!isTournamentDone)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isMatchReady ? _startNextVotingRound : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isMatchReady ? AppColors.purple1 : Colors.grey,
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                ),
                                child: Text(
                                  'Start Next Match Vote',
                                  style: TextStyle(fontSize: 18, color: isMatchReady ? Colors.white : Colors.white54, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          if (isTournamentDone)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('tournaments')
                                      .doc(widget.tournamentId)
                                      .update({'isTournamentFinished': true});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                ),
                                child: const Text('Finish & Show Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
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

// --- FULLY RESTORED UI CLASSES ---

class _RoundColumn extends StatelessWidget {
  final String roundName;
  final List<Map<String, dynamic>> players;
  final int totalSlots;
  final int roundIndex;
  final double horizontalPadding;

  const _RoundColumn({
    required this.roundName,
    required this.players,
    required this.totalSlots,
    required this.roundIndex,
    required this.horizontalPadding,
  });

  int _getRoundCount(int slots) {
    if (slots <= 1) return 1;
    return (log(slots) / log(2)).ceil() + 1;
  }

  @override
  Widget build(BuildContext context) {
    const double totalHeight = 900;
    const double titleTopPadding = 2;
    const double cardsTopOffset = 40;

    const double lineSpace = 40;
    const double strokeWidth = 2.0;
    final Color lineColor = AppColors.purple1;

    final int slotsInThisRound = (totalSlots / pow(2, roundIndex)).ceil();

    final double availableSpacePerSlot = (totalHeight - cardsTopOffset) / slotsInThisRound;
    final double calculatedCardHeight = availableSpacePerSlot * 0.85;
    final double finalCardHeight = calculatedCardHeight.clamp(30.0, 100.0);

    final double cardWidth = (finalCardHeight * 1.5).clamp(80.0, 150.0);
    final double columnWidth = cardWidth + lineSpace;

    final List<double> positions = List.generate(
      slotsInThisRound,
          (i) => (i * 2 + 1) / (2 * slotsInThisRound),
    );

    final int pairsToDraw = (players.length / 2).ceil();
    final int positionsToKeep = pairsToDraw * 2;

    final List<double> positionsForDrawing = (positionsToKeep >= slotsInThisRound)
        ? positions
        : positions.sublist(0, positionsToKeep);

    return SizedBox(
      width: columnWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (roundIndex < _getRoundCount(totalSlots) - 1)
            CustomPaint(
              size: Size(columnWidth, totalHeight),
              painter: BracketPainter(
                positions: positionsForDrawing,
                totalHeight: totalHeight,
                cardWidth: cardWidth,
                lineLength: lineSpace,
                lineColor: lineColor,
                strokeWidth: strokeWidth,
                cardsTopOffset: cardsTopOffset,
                horizontalPadding: horizontalPadding,
              ),
            ),

          Positioned(
            top: titleTopPadding,
            left: 0,
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.purple4,
                borderRadius: BorderRadius.circular(8),
              ),
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
          ),

          for (int i = 0; i < slotsInThisRound; i++)
            Positioned(
              left: 0,
              top: (totalHeight * positions[i] - finalCardHeight / 2) + cardsTopOffset,
              child: (i < players.length)
                  ? _ContestantCard(
                name: players[i]['name'] ?? '???',
                picture: players[i]['picture'] ?? '',
                height: finalCardHeight,
                width: cardWidth,
              )
                  : Opacity(
                opacity: 0.0,
                child: _ContestantCard(
                    name: 'empty', picture: '', height: finalCardHeight, width: cardWidth),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContestantCard extends StatelessWidget {
  final String name;
  final String picture;
  final double height;
  final double width;

  const _ContestantCard({
    required this.name,
    required this.picture,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final double dynamicNameFontSize = (height * 0.15).clamp(8.0, 14.0);
    final double imageHeight = height * 0.55;
    final double dynamicFallbackFontSize = (imageHeight * 0.5).clamp(12.0, 28.0);

    Widget _buildFallback() {
      return Center(
        child: Text('?', style: TextStyle(fontSize: dynamicFallbackFontSize, color: Colors.white)),
      );
    }

    final double imageWidth = imageHeight;

    ImageProvider? backgroundImage;
    if (picture.isNotEmpty) {
      if (picture.startsWith('assets/')) {
        backgroundImage = AssetImage(picture);
      } else {
        backgroundImage = FileImage(File(picture));
      }
    }

    return Container(
      width: width,
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
          SizedBox(
            height: imageHeight,
            width: imageWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: AppColors.purple4,
                child: (backgroundImage != null)
                    ? Image(
                  image: backgroundImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallback(),
                )
                    : _buildFallback(),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            name,
            style: TextStyle(color: Colors.white, fontSize: dynamicNameFontSize),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class BracketPainter extends CustomPainter {
  final List<double> positions;
  final double totalHeight;
  final double cardWidth;
  final double lineLength;
  final Color lineColor;
  final double strokeWidth;
  final double cardsTopOffset;
  final double horizontalPadding;

  BracketPainter({
    required this.positions,
    required this.totalHeight,
    required this.cardWidth,
    required this.lineLength,
    required this.lineColor,
    required this.strokeWidth,
    required this.cardsTopOffset,
    required this.horizontalPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < positions.length - 1; i += 2) {
      final double Y1 = (totalHeight * positions[i]) + cardsTopOffset;
      final double Y2 = (totalHeight * positions[i + 1]) + cardsTopOffset;
      final double Ymid = (Y1 + Y2) / 2;
      final double Xstart = cardWidth;
      final double Xvert = cardWidth + lineLength / 2;
      final double Xend = cardWidth + lineLength + (horizontalPadding * 2);

      canvas.drawLine(Offset(Xstart, Y1), Offset(Xvert, Y1), paint);
      canvas.drawLine(Offset(Xstart, Y2), Offset(Xvert, Y2), paint);
      canvas.drawLine(Offset(Xvert, Y1), Offset(Xvert, Y2), paint);
      canvas.drawLine(Offset(Xvert, Ymid), Offset(Xend, Ymid), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}