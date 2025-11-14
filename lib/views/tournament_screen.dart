import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tournament_app/configs/color_data.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

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
            for (int i = 0; i < rounds.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RoundColumn(
                  roundName: rounds[i],
                  players:
                      List<Map<String, dynamic>>.from(bracket[rounds[i]] ?? []),
                  totalSlots: totalSlots,
                  roundIndex: i,
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
    const double totalHeight = 800;
    const double cardHeight = 80;

    final int slotsInThisRound = (totalSlots / pow(2, roundIndex)).ceil();

    List<double> positions = List.generate(
      slotsInThisRound,
      (i) => (i * 2 + 1) / (2 * slotsInThisRound),
    );

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
          for (int i = 0; i < slotsInThisRound; i++)
            Positioned(
              top: totalHeight * positions[i] - cardHeight / 2,
              left: 0,
              right: 0,
              child: (i < players.length && players[i]['name'].isNotEmpty)
                  ? _ContestantCard(
                      name: players[i]['name'] ?? '???',
                      picture: players[i]['picture'] ?? '',
                      height: cardHeight,
                    )
                  : const Opacity(
                      opacity: 0.0,
                      child: _ContestantCard(
                          name: 'empty', picture: '', height: cardHeight),
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

  const _ContestantCard({
    required this.name,
    required this.picture,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = height * 0.25;

    ImageProvider? backgroundImage;
    if (picture.isNotEmpty) {
      if (picture.startsWith('assets/')) {
        backgroundImage = AssetImage(picture);
      } else {
        backgroundImage = FileImage(File(picture));
      }
    }

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
            backgroundImage: backgroundImage,
            onBackgroundImageError: (_, __) {},
            child: (backgroundImage == null)
                ? const Text('?', style: TextStyle(fontSize: 28, color: Colors.white))
                : null,
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
