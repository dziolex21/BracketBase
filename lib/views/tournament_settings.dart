import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';

class TournamentSettings extends StatefulWidget {
  const TournamentSettings({super.key});

  @override
  State<TournamentSettings> createState() => _TournamentSettingsState();
}

class _TournamentSettingsState extends State<TournamentSettings> {
  bool _imagesEnabled = true;
  int _selectedTiebreaker = 0; // 0 for random, 1 for host

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purple5,
      appBar: AppBar(
        backgroundColor: AppColors.purple5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.purple1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Images section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: AppColors.purple4,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.purple2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Images',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  Switch(
                    value: _imagesEnabled,
                    onChanged: (value) {
                      setState(() {
                        _imagesEnabled = value;
                      });
                    },
                    activeTrackColor: Colors.green,
                    inactiveTrackColor: Colors.grey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            // Tiebreaker section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.purple4,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.purple2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tiebreaker',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(height: 16.0),
                  _buildTiebreakerOption(0, 'Random pick'),
                  const SizedBox(height: 12.0),
                  _buildTiebreakerOption(1, 'Tournament host decides'),
                  const SizedBox(height: 12.0),
                  _buildTiebreakerOption(3, 'first come first served'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiebreakerOption(int index, String text) {
    final bool isSelected = _selectedTiebreaker == index;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTiebreaker = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.purple1 : AppColors.purple3,
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }
}
