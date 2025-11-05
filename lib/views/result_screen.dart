import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';

void main() {
  runApp(const ResultsApp());
}

class ResultsApp extends StatelessWidget {
  const ResultsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ResultsScreen(),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0025), // 🔹 Tło główne (tu wstaw swój kolor)
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 🏆 Zwycięzca
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4A1B78), // 🔹 Kolor karty zwycięzcy
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white, // 🔹 Kolor obramowania zwycięzcy
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Winner: NAME',
                      style: TextStyle(
                        color: Colors.white, // 🔹 Kolor tekstu
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.asset(
                      'assets/optionA.png', // 🔹 Ścieżka do obrazka
                      width: 60,
                      height: 60,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 📋 Lista pozostałych miejsc
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  ResultCard(position: 2, name: 'NAME', imagePath: 'assets/placeholder_image.png'),
                  ResultCard(position: 3, name: 'NAME', imagePath: 'assets/placeholder_image.png'),
                  ResultCard(position: 4, name: 'NAME', imagePath: 'assets/placeholder_image.png'),
                ],
              ),
            ),

            // 🔘 Przycisk "Back to menu"
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple3, // 🔹 Kolor przycisku
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Wróć do menu
                  },
                  child: const Text(
                    'Back to menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final int position;
  final String name;
  final String imagePath;

  const ResultCard({
    super.key,
    required this.position,
    required this.name,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.purple5,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '#$position $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Image.asset(
            imagePath,
            width: 60,
            height: 60,
          ),
        ],
      ),
    );
  }
}
