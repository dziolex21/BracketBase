import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';

void main() {
  runApp(const VoteApp());
}

class VoteApp extends StatelessWidget {
  const VoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const VoteScreen(),
    );
  }
}

class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purple5,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 180),
            const Text(
              'Vote',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD2A2FF),
              ),
            ),
            const SizedBox(height: 20),

            // Sekcja z opcjami głosowania

            // Sekcja z opcjami głosowania
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  VoteOptionCard(
                    title: 'Option A',
                    imagePath: 'assets/placeholder_image.png',
                    votes: 4,
                  ),
                  VoteOptionCard(
                    title: 'Option B',
                    imagePath: 'assets/placeholder_image.png',
                    votes: 2,
                  ),
                ],
              ),
            ),





            // Napis na dole
            const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Text(
                'Waiting for 1 vote...',
                style: TextStyle(
                  color: Color(0xFFB785F4),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoteOptionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final int votes;

  const VoteOptionCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.votes,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded( // <-- TEN Expanded jest potrzebny, bo jest dzieckiem Row
      child: Container(
        height: 300, // <-- DODAJ stałą wysokość lub użyj innego mechanizmu
        decoration: BoxDecoration(


        color: AppColors.purple3,
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.purple4,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Image.asset(
                  imagePath,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.purple4,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                'Votes: $votes',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
