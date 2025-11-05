import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/views/tournament_creator.dart';
import 'package:tournament_app/views/tournament_lobby.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Start Screen',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void _showJoinTournamentPopup(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.purple4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nagłówek + przycisk zamykania
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tournament ID:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Pole z ID turnieju (na razie statyczne)
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.purple5,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: AppColors.purple1,
                      decoration: InputDecoration(
                        hintText: "Enter tournament ID",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.purple5,
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Przycisk Join
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Join',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      // --- POCZĄTEK ZMIAN ---
      // 1. Przywracamy AppBar
      appBar: AppBar(
        // 2. Ustawiamy tło AppBar na całą szerokość
        backgroundColor: AppColors.purple3,
        // 3. Wstawiamy kontener "App Name" jako tytuł
        title: Center( // Używamy Center, aby wyśrodkować nasz niestandardowy tytuł
          child: Container(
            height: 100,
            width: 380,
            decoration: BoxDecoration(
              // Tło kontenera jest takie samo jak tło AppBar, tworząc jednolity wygląd
              color: AppColors.purple1,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: const Center(
              child: Text(
                'App Name',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        // Ustawiamy preferowaną wysokość AppBar, aby zmieścić nasz kontener
        toolbarHeight: 220,
        // Dodajemy cień dla lepszego oddzielenia od reszty ekranu
        elevation: 8.0,
      ),
      // --- KONIEC ZMIAN ---
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Usuwamy stary kontener "App Name" i odstęp z body
            const SizedBox(height: 50),
            // Przyciski menu pozostają bez zmian
            _buildMenuButton(
              context,
              'Create tournament',
                AppColors.purple4,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TournamentCreator(),
                      ),
                    );
                  },
            ),
            const SizedBox(height: 30),
            _buildMenuButton(
              context,
              'Join tournament',
                AppColors.purple4,
                () => _showJoinTournamentPopup(context)
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.purple5,
    );
  }

  Widget _buildMenuButton(
      BuildContext context, String text, Color backgroundColor, VoidCallback onPressed) {
    return SizedBox(
      width: 350,
      height: 80,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: const BorderSide(color: Colors.white, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
