import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';




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
        toolbarHeight: 140,
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
                  () { /* TODO */ },
            ),
            const SizedBox(height: 30),
            _buildMenuButton(
              context,
              'Join tournament',
                AppColors.purple4,
                  () { /* TODO */ },
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
