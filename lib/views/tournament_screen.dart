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

  @override
  void initState() {
    super.initState();
    _loadBracket();
  }

  Future<void> _loadBracket() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = p.join(tempDir.path, 'bracket.json');
      final File jsonFile = File(filePath);

      if (await jsonFile.exists()) {
        final String jsonString = await jsonFile.readAsString();
        final Map<String, dynamic> loadedBracket = jsonDecode(jsonString);
        setState(() {
          _bracket = loadedBracket;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Tournament data not found. Please create a new tournament.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load tournament data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLeaveTournament() async {
    final docRef = FirebaseFirestore.instance
        .collection('tournaments')
        .doc(widget.tournamentId);

    try {
      if (widget.isHost) {
        await docRef.delete();
      } else {
        if (widget.currentPlayerName != null) {
          await docRef.update({
            'playersList': FieldValue.arrayRemove([widget.currentPlayerName])
          });
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error leaving tournament: $e"))
        );
      }
    }
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
      return Scaffold(
        backgroundColor: AppColors.purple5,
        appBar: AppBar(
          title: const Text('Loading Tournament...'),
          backgroundColor: AppColors.purple3,
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.purple5,
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: AppColors.purple3,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right:16, top:0,bottom: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple1),
                  child: const Text("Go Back", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      );
    }

    final bracket = _bracket!;
    final rounds = bracket.keys.toList();
    final firstRoundPlayers =
    List<Map<String, dynamic>>.from(bracket[rounds.first] ?? []);

    int totalContestants = firstRoundPlayers.length;

    if (rounds.length > 1) {
      final List<Map<String, dynamic>> secondRoundSlots =
      List<Map<String, dynamic>>.from(bracket[rounds[1]] ?? []);

      final int byes = secondRoundSlots
          .where((player) =>
      player['name'] != null && (player['name'] as String).isNotEmpty)
          .length;

      totalContestants += byes;
    }

    final totalSlots = _nextPowerOfTwo(max(1, totalContestants));
    const double horizontalPadding = 16.0;

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;

            if (data == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop();
              });
            }
            // --- AUTO-NAVIGATION LOGIC (FOR EVERYONE) ---
            else {
              // 1. Navigate to voting
              if (data['isVotingStarted'] == true) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => VotingScreen(gameId: widget.tournamentId, isHost: widget.isHost,)),
                    );
                  }
                });
              }
              // 2. Navigate to results (NEW)
              else if (data['isTournamentFinished'] == true) {
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).pop();
            });
          }

          return WillPopScope(
            onWillPop: () async {
              _showLeaveConfirmationDialog();
              return false;
            },
            child: Scaffold(
              backgroundColor: AppColors.purple5,
              appBar: AppBar(
                title: const Text('Tournament'),
                backgroundColor: AppColors.purple3,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: "Leave Tournament",
                    onPressed: _showLeaveConfirmationDialog,
                  ),
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
                                  players: List<Map<String, dynamic>>.from(bracket[rounds[i]] ?? []),
                                  totalSlots: totalSlots,
                                  roundIndex: i,
                                  horizontalPadding: horizontalPadding,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // --- CONTROL BUTTONS (HOST ONLY) ---
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
                          // Voting button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('tournaments')
                                    .doc(widget.tournamentId)
                                    .update({'isVotingStarted': true});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.purple1,
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: const Text(
                                'Go to Voting',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Results button (NEW)
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
                                backgroundColor: const Color(0xFFFFD700), // Gold color for finish
                                foregroundColor: Colors.black, // Black text
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: const Text(
                                'Finish & Show Results',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
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

// [_RoundColumn, _ContestantCard and BracketPainter classes remain unchanged below]
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

    final double availableSpacePerSlot =
        (totalHeight - cardsTopOffset) / slotsInThisRound;
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