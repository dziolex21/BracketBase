import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/configs/settings.dart';

class TournamentSettings extends StatefulWidget {
  const TournamentSettings({super.key});

  @override
  State<TournamentSettings> createState() => _TournamentSettingsState();
}

class _TournamentSettingsState extends State<TournamentSettings> {
  late AppSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await AppSettings.load();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _settings.save();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.purple5,
        appBar: AppBar(
          backgroundColor: AppColors.purple5,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.purple5,
      appBar: AppBar(
        backgroundColor: AppColors.purple5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.purple1),
          onPressed: () async {
            await _saveSettings();
            Navigator.of(context).pop();
          },
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
                    value: _settings.imagesEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings.imagesEnabled = value;
                      });
                    },
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.grey,
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
                  _buildTiebreakerOption(2, 'First come first serve'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiebreakerOption(int index, String text) {
    final bool isSelected = _settings.selectedTiebreaker == index;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _settings.selectedTiebreaker = index;
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
