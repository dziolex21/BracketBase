import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/views/voting_screen.dart';

class TournamentScreen extends StatefulWidget {
  final bool isHost;
  final String tournamentId;
  const TournamentScreen({super.key, this.isHost = false, this.tournamentId = ""});

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
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final bracket = _bracket!;
    final rounds = bracket.keys.toList();
    final firstRoundPlayers =
    List<Map<String, dynamic>>.from(bracket[rounds.first] ?? []);

    // Count the total number of contestants
    int totalContestants = firstRoundPlayers.length;

    // If there is a 2nd round, look for byes in it
    if (rounds.length > 1) {
      final List<Map<String, dynamic>> secondRoundSlots =
      List<Map<String, dynamic>>.from(bracket[rounds[1]] ?? []);

      // "Byes" are participants in the 2nd round with a non-empty name
      final int byes = secondRoundSlots
          .where((player) =>
      player['name'] != null && (player['name'] as String).isNotEmpty)
          .length;

      totalContestants += byes;
    }

    // totalSlots is the "next power of two" of the TOTAL number of contestants
    final totalSlots = _nextPowerOfTwo(max(1, totalContestants));



    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.purple5,
        appBar: AppBar(
          title: const Text('Tournament'),
          backgroundColor: AppColors.purple3,
          automaticallyImplyLeading: false,
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
            Visibility(
              visible: widget.isHost,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VotingScreen(gameId: widget.tournamentId,)),
                      );
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
  final int totalSlots;
  final int roundIndex;

  const _RoundColumn({
    required this.roundName,
    required this.players,
    required this.totalSlots,
    required this.roundIndex,
  });

  @override
  Widget build(BuildContext context) {
    const double totalHeight = 800; // Total "canvas" for positioning
    const double titleTopPadding = 1;
    const double cardsTopOffset = 40;

    final int slotsInThisRound = (totalSlots / pow(2, roundIndex)).ceil();

    // 1. Calculate how much space is available for 1 slot
    final double availableSpacePerSlot =
        (totalHeight - cardsTopOffset) / slotsInThisRound;

    // 2. Calculate the card height (85% of the space) to have some padding
    final double calculatedCardHeight = availableSpacePerSlot * 0.85;

    // 3. Limit: not less than 30px (for 1/32) and not more than 100px (for 1/2)
    final double finalCardHeight = calculatedCardHeight.clamp(30.0, 100.0);

    // Card width is now dependent on the card height (with a 1.5 ratio)
    // It also has min/max limits to avoid being too thin or too wide
    final double cardWidth = (finalCardHeight * 1.5).clamp(80.0, 150.0);

    final List<double> positions = List.generate(
      slotsInThisRound,
          (i) => (i * 2 + 1) / (2 * slotsInThisRound),
    );

    return SizedBox(
      width: cardWidth,
      height: totalHeight,
      child: Stack( // Use a variable
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: titleTopPadding,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 12, right:12, top:2,bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.purple4,
                borderRadius: BorderRadius.circular(12),
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
              top: (totalHeight * positions[i] - finalCardHeight / 2) + cardsTopOffset,
              left: 0,
              right: 0,
              child: (i < players.length)
                  ? _ContestantCard(
                name: players[i]['name'] ?? '???',
                picture: players[i]['picture'] ?? '',
                // Pass dynamic height and fixed width
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

  // Note: _buildFallback is now defined inside build()

  @override
  Widget build(BuildContext context) {
    // Calculating dynamic font sizes
    final double dynamicNameFontSize = (height * 0.15).clamp(8.0, 14.0);
    final double imageHeight = height * 0.55;
    // The size of the "?" is taken as 50% of the image height
    final double dynamicFallbackFontSize = (imageHeight * 0.5).clamp(12.0, 28.0);

    Widget _buildFallback() {
      return Center(
        child: Text('?', style: TextStyle(fontSize: dynamicFallbackFontSize, color: Colors.white)),
      );
    }
    // ----------------------------------------------------

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
<<<<<<< HEAD
=======

class BracketPainter extends CustomPainter {
  final List<double> positions;
  final double totalHeight;
  final double cardWidth;
  final double lineLength; // This is the "space" for the line (40px)
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
      //  FIX 1: Y-coordinates now po
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
>>>>>>> main
