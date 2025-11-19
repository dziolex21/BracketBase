import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/services/json_creator.dart';
import 'package:tournament_app/views/contestant_editor_screen.dart';
import 'package:tournament_app/views/tournament_lobby.dart';
import 'package:tournament_app/views/tournament_settings.dart';
import 'dart:convert';

class TournamentCreator extends StatefulWidget {
  const TournamentCreator({super.key});

  @override
  State<TournamentCreator> createState() => _TournamentCreatorState();
}

class _TournamentCreatorState extends State<TournamentCreator> {
  final List<Contestant> _contestants = [];

  void _navigateAndEditContestant(BuildContext context, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ContestantEditorScreen(contestant: _contestants[index]),
      ),
    );

    if (result != null) {
      if (result == 'DELETE') {
        setState(() {
          _contestants.removeAt(index);
        });
      } else if (result is Contestant) {
        setState(() {
          _contestants[index] = result;
        });
      }
    }
  }

  void _navigateAndAddContestant(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContestantEditorScreen(),
      ),
    );

    if (result != null && result is Contestant) {
      setState(() {
        _contestants.add(result);
      });
    }
  }

  // Function to create a tournament on the server (one version left)
  Future<void> createTournamentOnServer(String id, String bracketData) async {
    final mainDocRef =
    FirebaseFirestore.instance.collection('tournaments').doc(id);

    final mainData = {
      'optionAVotes': 0,
      'optionBVotes': 0,
      'playersList': [],
      'roundResult': 0,
      'isStarted': false, // Important flag!
      'bracketData': bracketData, // <--- SAVING THE BRACKET JSON
    };

    await mainDocRef.set(mainData);

    // Add the contestants collection
    for (var contestant in _contestants) {
      await mainDocRef.collection('contestants').doc(contestant.name).set({
        'name': contestant.name,
        'avatar': contestant.picture
      });
    }
  }

  void _startTournament(BuildContext context) async {
    if (_contestants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least 2 contestants to start tournament')),
      );
      return;
    }

    // 1. Create the bracket. This function will return a Map and save the file locally for the host
    final bracketMap = await createTournamentBracket(_contestants);
    final String bracketJsonString = jsonEncode(bracketMap);

    final random = Random();
    String id = "";

    // 1. Loop to generate a UNIQUE ID
    DocumentSnapshot docSnapshot;

    do {
      // Generate a new 6-digit ID
      id = "";
      for (int i = 0; i < 6; i++) {
        id += random.nextInt(10).toString();
      }

      // Check its existence
      final docRef = FirebaseFirestore.instance.collection("tournaments").doc(id);
      docSnapshot = await docRef.get();

      // Repeat while a document with this ID exists
    } while (docSnapshot.exists);

    // Now the 'id' variable is guaranteed to contain a unique, non-empty ID

    await createTournamentOnServer(id, bracketJsonString);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        // ID is passed to the Lobby
        builder: (context) => TournamentLobby(lobbyId: id, isHost: true),
      ),
    );
  }
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.purple1),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Text(
                    'Tournament creator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.purple1),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TournamentSettings()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.purple4,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.purple2),
                  ),
                  child: ListView.separated(
                    itemCount: _contestants.length + 1,
                    separatorBuilder: (context, index) =>
                    const SizedBox(height: 12.0),
                    itemBuilder: (context, index) {
                      if (index == _contestants.length) {
                        return _buildAddContestantButton(context);
                      }
                      return _buildContestantTile(context, index);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startTournament(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple1,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Start tournament',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContestantTile(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _navigateAndEditContestant(context, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: AppColors.purple3,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _contestants[index].name,
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
      onTap: () => _navigateAndAddContestant(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: AppColors.purple3,
          borderRadius: BorderRadius.circular(12.0),
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