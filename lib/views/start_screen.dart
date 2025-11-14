import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    void showJoinTournamentPopup(BuildContext context) {
      final TextEditingController idController = TextEditingController();

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.purple4,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalContext) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
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
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Pole z ID turnieju
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purple5,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: TextField(
                        controller: idController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: const TextStyle(color: Colors.white),
                        cursorColor: AppColors.purple1,
                        decoration: const InputDecoration(
                          hintText: "Enter tournament ID",
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: AppColors.purple5,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Przycisk Join
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final enteredId = idController.text;
                        if (enteredId.length == 6) {
                          Navigator.pop(modalContext); // Close the modal

                          final docRef = FirebaseFirestore.instance.collection('tournaments').doc(enteredId);
                          final doc = await docRef.get();
  
                          if (doc.exists) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TournamentLobby(lobbyId: enteredId),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showMaterialBanner(
                              MaterialBanner(
                                padding: const EdgeInsets.all(16),
                                content: const Text('Did not find tournament with such id', style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.redAccent,
                                actions: [
                                  TextButton(
                                    child: const Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    onPressed: () => ScaffoldMessenger.of(context)
                                        .hideCurrentMaterialBanner(),
                                  ),
                                ],
                              ),
                            );
                          }
                        } else {
                           ScaffoldMessenger.of(context).showMaterialBanner(
                            MaterialBanner(
                              padding: const EdgeInsets.all(16),
                              content: const Text('Please enter a valid 6-digit ID.', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.redAccent,
                              actions: [
                                TextButton(
                                  child: const Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () => ScaffoldMessenger.of(context)
                                      .hideCurrentMaterialBanner(),
                                ),
                              ],
                            ),
                          );
                        }
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
            ),
          );
        },
      );
    }


    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.purple3,
        title: Center(
          child: Container(
            height: 100,
            width: 380,
            decoration: BoxDecoration(
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
        toolbarHeight: 220,
        elevation: 8.0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
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
                () => showJoinTournamentPopup(context)),
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
