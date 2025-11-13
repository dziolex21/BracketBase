import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/views/contestant_editor_screen.dart';
import 'package:tournament_app/views/tournament_settings.dart';
import 'package:tournament_app/data/TournamentData.dart';
import 'package:tournament_app/views/tournament_screen.dart';

class Contestant {
  final String name;
  final String picture;

  Contestant({required this.name, required this.picture});

  Map<String, dynamic> toJson() => {
    'name': name,
    'votes': 0,
  };
}

Map<String, List<Map<String, dynamic>>> createTournamentBracket(List<Contestant> contestants) {
  int n = contestants.length;
  int nextPowerOf2 = pow(2, (log(n) / log(2)).ceil()).toInt();
  int byes = nextPowerOf2 - n;

  final roundNames = ['1/32', '1/16', '1/8', '1/4', '1/2', '1'];
  String firstRound = roundNames[(log(nextPowerOf2) / log(2)).toInt() - 1];

  List<Map<String, dynamic>> firstRoundPairs = contestants.map((c) => c.toJson()).toList();

  List<Map<String, dynamic>> nextRoundByes = [];
  if (byes > 0) {
    nextRoundByes = firstRoundPairs.sublist(n - byes);
    firstRoundPairs = firstRoundPairs.sublist(0, n - byes);
  }

  Map<String, List<Map<String, dynamic>>> bracket = {
    firstRound: firstRoundPairs,
  };

  int roundsCount = (log(nextPowerOf2) / log(2)).toInt();
  for (int i = 1; i < roundsCount; i++) {
    bracket[roundNames[(roundNames.indexOf(firstRound) + i)]] = [];
  }

  if (nextRoundByes.isNotEmpty) {
    String nextRoundName = roundNames[(roundNames.indexOf(firstRound) + 1)];
    bracket[nextRoundName] = nextRoundByes;
  }

  return bracket;
}



class TournamentCreator extends StatefulWidget {
  const TournamentCreator({super.key});

  @override
  State<TournamentCreator> createState() => _TournamentCreatorState();
}

class _TournamentCreatorState extends State<TournamentCreator> {
  final List<Contestant> _contestants = [
    
  ];

  void _navigateAndEditContestant(BuildContext context, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContestantEditorScreen(contestant: _contestants[index]),
      ),
    );

    if (result != null && result is Contestant) {
      setState(() {
        _contestants[index] = result;
      });
    }
  }

  void _navigateAndAddContestant(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContestantEditorScreen(),
      ),
    );

    if (result != null && result is Contestant) {
      setState(() {
        _contestants.add(result);
      });
    }
  }

  void _startTournament(BuildContext context) {
    if (_contestants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 contestants to start tournament')),
      );
      return;
    }

    final bracket = createTournamentBracket(_contestants);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentScreen(bracket: bracket),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purple5,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text(
                    'Tournament creator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.purple1),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TournamentSettings()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.purple4,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.purple2),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _contestants.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(height: 12.0),
                  itemBuilder: (context, index) {
                    if (index == _contestants.length) {
                      return _buildAddContestantButton(context);
                    }
                    return _buildContestantTile(context, index);
                  },
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startTournament(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple1,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Start tournament',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContestantTile(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _navigateAndEditContestant(context, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: AppColors.purple3,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _contestants[index].name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildAddContestantButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateAndAddContestant(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: AppColors.purple3,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add contestant',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Icon(Icons.add, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}
