import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/views/contestant_editor_screen.dart';
import 'package:tournament_app/views/tournament_lobby.dart';
import 'package:tournament_app/views/tournament_settings.dart';
import 'package:tournament_app/views/tournament_lobby.dart';

class TournamentCreator extends StatefulWidget {
  const TournamentCreator({super.key});

  @override
  State<TournamentCreator> createState() => _TournamentCreatorState();
}

class _TournamentCreatorState extends State<TournamentCreator> {
  final List<String> _contestants = [];

  void _navigateAndEditContestant(BuildContext context, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContestantEditorScreen(contestantName: _contestants[index]),
      ),
    );

    if (result != null && result is String && result.isNotEmpty) {
      setState(() {
        _contestants[index] = result;
      });
    }
  }

  void _navigateAndAddContestant(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContestantEditorScreen(),
      ),
    );

    if (result != null && result is String && result.isNotEmpty) {
      setState(() {
        _contestants.add(result);
      });
    }
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
                  itemCount: _contestants.length + 1, // +1 for the add button
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
                  onPressed: () {
                    final lobbyId = (Random().nextInt(900000) + 100000).toString();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TournamentLobby(lobbyId: lobbyId),
                      ),
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
              _contestants[index],
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
