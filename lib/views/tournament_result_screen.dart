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

  // Данные для отображения. Если name пустое — значит место вакантно.
  Map<String, dynamic> _winner = {'name': '', 'picture': ''};
  Map<String, dynamic> _runnerUp = {'name': '', 'picture': ''};
  List<Map<String, dynamic>> _semiFinalLosers = []; // 3-4 места

  @override
  void initState() {
    super.initState();
    _calculateIntermediateResults();
  }

  Future<void> _calculateIntermediateResults() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File jsonFile = File(p.join(tempDir.path, 'bracket.json'));

      if (!await jsonFile.exists()) {
        setState(() => _isLoading = false);
        return;
      }

      final String jsonString = await jsonFile.readAsString();
      final Map<String, dynamic> bracket = jsonDecode(jsonString);

      // --- 1. ПОБЕДИТЕЛЬ (Золото) ---
      // Берем из раунда "1"
      final List<dynamic> round1 = bracket['1'] ?? [];
      if (round1.isNotEmpty && round1[0]['name'] != '') {
        _winner = round1[0];
      }

      // --- 2. ВТОРОЕ МЕСТО (Серебро) ---
      // Это тот, кто есть в "1/2", но кого НЕТ в "1".
      // Но мы можем определить его ТОЛЬКО если победитель уже известен.
      // Если победителя нет, значит финал еще не сыгран, и 2-е место тоже неизвестно.
      if (_winner['name'] != '') {
        final List<dynamic> round1_2 = bracket['1/2'] ?? [];
        // Ищем игрока в 1/2, чье имя не совпадает с победителем
        final runnerUpEntry = round1_2.firstWhere(
              (p) => p['name'] != '' && p['name'] != _winner['name'],
          orElse: () => null,
        );
        if (runnerUpEntry != null) {
          _runnerUp = runnerUpEntry;
        }
      }

      // --- 3. ТРЕТЬЕ-ЧЕТВЕРТОЕ МЕСТА (Бронза) ---
      // Это те, кто был в "1/4", но НЕ попал в "1/2".
      final List<dynamic> round1_4 = bracket['1/4'] ?? [];
      final List<dynamic> round1_2 = bracket['1/2'] ?? [];

      // Собираем имена тех, кто прошел в полуфинал (в 1/2)
      final Set<String> promotedToSemiNames = round1_2
          .map((e) => e['name'] as String)
          .where((name) => name.isNotEmpty)
          .toSet();

      // Фильтруем 1/4: берем тех, у кого есть имя И кого нет в списке прошедших
      final List<Map<String, dynamic>> losers = [];
      for (var player in round1_4) {
        final String name = player['name'] ?? '';
        // Условие: Имя есть, и этого имени нет в следующем раунде
        // НО! Если в следующем раунде (1/2) еще есть пустые слоты,
        // мы не можем точно сказать, что этот человек вылетел (может он еще не сыграл).
        // Поэтому показываем в списке только тех, кто точно вылетел,
        // либо (для красоты) просто заполняем заглушками, если турнир в процессе.

        if (name.isNotEmpty && !promotedToSemiNames.contains(name)) {
          // Проверяем, заполнен ли раунд 1/2 полностью.
          // Если в 1/2 есть пустые слоты, возможно этот игрок просто еще не сыграл свой матч 1/4.
          // Для упрощения: мы считаем бронзовыми призерами тех, кто не прошел дальше,
          // ТОЛЬКО если мы уверены в составе 1/2.

          // В рамках вашей задачи: давайте просто покажем тех, кто точно не прошел.
          losers.add(player);
        }
      }
      _semiFinalLosers = losers;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
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

    return Scaffold(
      backgroundColor: AppColors.purple5,
      appBar: AppBar(
        title: const Text("Tournament Standings"),
        backgroundColor: AppColors.purple3,
        centerTitle: true,
        // Убираем кнопку назад по умолчанию, делаем свою "Home"
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, size: 30, color: Colors.white),
            onPressed: () {
              // Возврат в самое начало
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const Text(
              "CHAMPION",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),

            // --- КАРТОЧКА ПОБЕДИТЕЛЯ (или заглушка) ---
            _buildWinnerDisplay(_winner),

            const SizedBox(height: 50),

            // --- ТАБЛИЦА ЛИДЕРОВ ---
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
                      "Podium",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 2-е Место (Серебро)
                  _buildRankRow(2, _runnerUp, const Color(0xFFC0C0C0)),

                  // 3-е и 4-е Места (Бронза)
                  // Если список пуст (начало турнира), покажем две заглушки
                  if (_semiFinalLosers.isEmpty) ...[
                    _buildRankRow(3, {'name': '', 'picture': ''}, const Color(0xFFCD7F32)),
                    _buildRankRow(3, {'name': '', 'picture': ''}, const Color(0xFFCD7F32)),
                  ] else ...[
                    for (var player in _semiFinalLosers)
                      _buildRankRow(3, player, const Color(0xFFCD7F32)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет для Чемпиона (Большой)
  Widget _buildWinnerDisplay(Map<String, dynamic> player) {
    final String name = player['name'] ?? '';
    final String picture = player['picture'] ?? '';
    final bool hasWinner = name.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Сияние (только если есть победитель)
        if (hasWinner)
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

        // Аватар или Заглушка
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.purple3, // Фон заглушки
            border: Border.all(
                color: hasWinner ? const Color(0xFFFFD700) : AppColors.purple2, // Золотая или блеклая рамка
                width: 6
            ),
          ),
          child: ClipOval(
            child: _buildImage(picture),
          ),
        ),

        // Корона (только если есть победитель)
        if (hasWinner)
          const Positioned(
            top: -35,
            child: Text("👑", style: TextStyle(fontSize: 50)),
          ),

        // Имя или "TBD"
        Positioned(
          bottom: -50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.purple2,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: hasWinner ? const Color(0xFFFFD700) : AppColors.purple1,
                  width: 2
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Text(
              hasWinner ? name : "???",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: hasWinner ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Виджет строки (2, 3 место)
  Widget _buildRankRow(int rank, Map<String, dynamic> player, Color rankColor) {
    final String name = player['name'] ?? '';
    final String picture = player['picture'] ?? '';
    final bool isKnown = name.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purple3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Медалька
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.purple5,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isKnown ? rankColor : Colors.grey.withOpacity(0.3),
                  width: 2
              ),
            ),
            child: Center(
              child: Text(
                rank == 3 ? "3-4" : "$rank",
                style: TextStyle(
                  color: isKnown ? rankColor : Colors.grey,
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
              color: AppColors.purple4,
              border: Border.all(color: AppColors.purple1),
            ),
            child: ClipOval(
              child: _buildImage(picture, isSmall: true),
            ),
          ),
          const SizedBox(width: 16),

          // Имя
          Expanded(
            child: Text(
              isKnown ? name : "???",
              style: TextStyle(
                color: isKnown ? Colors.white : Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path, {bool isSmall = false}) {
    // Если пути нет или он пустой - показываем вопрос
    if (path.isEmpty) {
      return Container(
        color: AppColors.purple4,
        child: Center(
          child: Text(
            "?",
            style: TextStyle(
                color: Colors.white24,
                fontSize: isSmall ? 20 : 50,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    } else {
      return Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_,__,___) => const Icon(Icons.error)
      );
    }
  }
}