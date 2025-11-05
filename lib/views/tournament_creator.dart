import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/views/contestant_editor_screen.dart';
import 'package:tournament_app/views/start_screen.dart';
import 'package:tournament_app/views/tournament_settings.dart';
import 'package:tournament_app/views/tournament_lobby.dart';

class TournamentCreator extends StatelessWidget {
  const TournamentCreator({super.key});

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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.purple1),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StartScreen())
                      );
                    },
                  ),
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
                  color: AppColors.purple1,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.purple2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildContestantTile(context, 'Contestant_1'),
                    const SizedBox(height: 12.0),
                    _buildContestantTile(context, 'Contestant_2'),
                    const SizedBox(height: 12.0),
                    _buildContestantTile(context, 'Contestant_3'),
                    const SizedBox(height: 12.0),
                    _buildAddContestantButton(context),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TournamentLobby()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple2,
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

  Widget _buildContestantTile(BuildContext context, String name) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ContestantEditorScreen(contestantName: name)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: AppColors.purple4,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ContestantEditorScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: AppColors.purple3,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.white),
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
