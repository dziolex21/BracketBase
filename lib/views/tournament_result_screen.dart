import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tournament_app/configs/color_data.dart';

class TournamentResultsScreen extends StatefulWidget {
  const TournamentResultsScreen({super.key});

  @override
  State<TournamentResultsScreen> createState() => _TournamentResultsScreenState();
}

class _TournamentResultsScreenState extends State<TournamentResultsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _winner;
  Map<String, dynamic>? _runnerUp;
  List<Map<String, dynamic>> _semiFinalists = [];

  @override
  void initState() {
    super.initState();
    _calculateResults();
  }

  Future<void> _calculateResults() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File jsonFile = File(p.join(tempDir.path, 'bracket.json'));

      if (!await jsonFile.exists()) {
        setState(() => _isLoading = false);
        return;
      }

      final String jsonString = await jsonFile.readAsString();
      final Map<String, dynamic> bracket = jsonDecode(jsonString);

      // 1. Находим победителя (Раунд "1")
      final List<dynamic> finalRound = bracket['1'] ?? [];
      if (finalRound.isNotEmpty) {
        _winner = finalRound.first;
      }

      // 2. Находим 2-е место (Тот, кто был в 1/2, но не в 1)
      final List<dynamic> semiFinalRound = bracket['1/2'] ?? [];
      if (_winner != null) {
        _runnerUp = semiFinalRound.firstWhere(
              (player) => player['name'] != _winner!['name'],
          orElse: () => null,
        );
      }

      // 3. Находим 3-е и 4-е места (Те, кто был в 1/4, но не попал в 1/2)
      final List<dynamic> quarterFinalRound = bracket['1/4'] ?? [];
      // Собираем имена тех, кто прошел в полуфинал
      final Set<String> semiFinalistsNames = semiFinalRound
          .map((e) => e['name'] as String)
          .toSet();

      _semiFinalists = List<Map<String, dynamic>>.from(quarterFinalRound.where((player) {
        // Если имя пустое (пустой слот) или игрок уже в полуфинале - пропускаем
        final name = player['name'];
        return name != null &&
            name.isNotEmpty &&
            !semiFinalistsNames.contains(name);
      }));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error calculating results: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.purple5,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_winner == null || _winner!['name'] == '') {
      return Scaffold(
        backgroundColor: AppColors.purple5,
        appBar: AppBar(backgroundColor: AppColors.purple3),
        body: const Center(
          child: Text("No winner determined yet.",
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.purple5,
      appBar: AppBar(
        title: const Text("Tournament Results"),
        backgroundColor: AppColors.purple3,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            // Вернуться в самое начало (или куда нужно)
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "CHAMPION",
              style: TextStyle(
                color: Color(0xFFFFD700), // Золотой цвет текста
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),

            // --- КАРТОЧКА ПОБЕДИТЕЛЯ ---
            _buildWinnerDisplay(_winner!),

            const SizedBox(height: 50),

            // --- СПИСОК ТОП ИГРОКОВ ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.purple4,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purple2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0, left: 8),
                    child: Text(
                      "Leaderboard",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_runnerUp != null)
                    _buildRankRow(2, _runnerUp!, const Color(0xFFC0C0C0)), // Серебро

                  for (var semi in _semiFinalists)
                    _buildRankRow(3, semi, const Color(0xFFCD7F32)), // Бронза
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerDisplay(Map<String, dynamic> player) {
    final String name = player['name'];
    final String picture = player['picture'] ?? '';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Сияние сзади
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),

        // Аватар
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD700), width: 6), // Золотая рамка
          ),
          child: ClipOval(
            child: _buildImage(picture),
          ),
        ),

        // Корона
        const Positioned(
          top: -35,
          child: Text(
            "👑",
            style: TextStyle(fontSize: 50),
          ),
        ),

        // Имя
        Positioned(
          bottom: -50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.purple2,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankRow(int rank, Map<String, dynamic> player, Color rankColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purple3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Медалька / Место
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.purple5,
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 2),
            ),
            child: Center(
              child: Text(
                rank == 3 ? "3-4" : "$rank", // Для полуфиналистов пишем 3-4
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: rank == 3 ? 10 : 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Аватар
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.purple1),
            ),
            child: ClipOval(
              child: _buildImage(player['picture'] ?? ''),
            ),
          ),
          const SizedBox(width: 16),

          // Имя
          Expanded(
            child: Text(
              player['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: AppColors.purple4,
        child: const Center(
            child: Icon(Icons.person, color: Colors.white54, size: 40)),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    } else {
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.error));
    }
  }
}