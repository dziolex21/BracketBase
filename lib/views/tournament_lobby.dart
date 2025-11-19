import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/views/tournament_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class TournamentLobby extends StatefulWidget {
  final String lobbyId;
  final bool isHost;

  const TournamentLobby({super.key, required this.lobbyId, this.isHost = false});

  @override
  State<TournamentLobby> createState() => _TournamentLobbyState();
}

class _TournamentLobbyState extends State<TournamentLobby> {
  String? _playerName;
  bool _isStartingTournament = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _promptForPlayerName();
      }
    });
  }

  @override
  void dispose() {
    if (!_isStartingTournament) {
      _handleLeaveLobby();
    }
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveBracketLocally(String jsonString) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = p.join(tempDir.path, 'bracket.json');
      final File jsonFile = File(filePath);

      await jsonFile.writeAsString(jsonString);
      print("Bracket downloaded and saved successfully.");
    } catch (e) {
      print("Error saving downloaded bracket: $e");
    }
  }

  Future<void> _promptForPlayerName() async {
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.purple4,
        title: Text(widget.isHost ? 'Enter Host Name' : 'Enter your name',
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Your name',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(_nameController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple2, // Button background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Join',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final docRef = FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.lobbyId);

      try {
        await docRef.update({
          'playersList': FieldValue.arrayUnion([name])
        });

        if (mounted) {
          setState(() {
            _playerName = name;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to join lobby: $e')));
          Navigator.of(context).pop();
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleLeaveLobby() async {
    if (_playerName == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('tournaments')
        .doc(widget.lobbyId);
    try {
      if (widget.isHost) {
        await docRef.delete();
      } else {
        await docRef.update({
          'playersList': FieldValue.arrayRemove([_playerName])
        });
      }
    } catch (e) {
      // Document may already be deleted, ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_playerName == null) {
      return const Scaffold(
        backgroundColor: AppColors.purple5,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.purple5, // najciemniejsze tło
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Strzałka wstecz
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.purple1),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 10),

              // ID turnieju
              Column(
                children: [
                  const Text(
                    "Tournament ID:",
                    style: TextStyle(
                      color: AppColors.purple1,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purple2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.lobbyId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Lista użytkowników
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('tournaments')
                        .doc(widget.lobbyId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.data!.exists) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        });
                        return const Center(
                            child: Text('Tournament has been cancelled.',
                                style: TextStyle(color: Colors.white)));
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>?;

                      // --- TOURNAMENT START LOGIC ---
                      if (data != null && (data['isStarted'] == true)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          if (mounted) {
                            if (!_isStartingTournament) {
                              setState(() {
                                _isStartingTournament = true;
                              });

                              // 1. CHECK AND DOWNLOAD THE BRACKET
                              if (data['bracketData'] != null) {
                                // Save data from the server to a local file
                                await _saveBracketLocally(data['bracketData']);
                              } else {
                                print("Error: No bracket data found on server!");
                              }

                              // 2. NAVIGATE TO THE TOURNAMENT SCREEN
                              // Find this part in your TournamentLobby
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TournamentScreen(
                                      tournamentId: widget.lobbyId,
                                      isHost: widget.isHost,
                                      // ADD THIS LINE:
                                      currentPlayerName: _playerName,
                                    )),
                              );
                            }
                          }
                        });

                        // While downloading and navigating, show a loading indicator
                        return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 10),
                                Text("Downloading tournament data...",
                                    style: TextStyle(color: Colors.white))
                              ],
                            ));
                      }

                      // --- WHAT WAS MISSING: DISPLAYING THE PLAYER LIST ---
                      if (data == null || data['playersList'] == null) {
                        return const Center(
                            child: Text('Waiting for players...',
                                style: TextStyle(color: Colors.white)));
                      }

                      final playersList =
                      List<String>.from(data['playersList']);

                      return GridView.builder(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.8,
                        ),
                        itemCount: playersList.length,
                        itemBuilder: (context, index) {
                          final playerName = playersList[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? AppColors.purple2
                                  : AppColors.purple4,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                playerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
              ),

              // Przycisk startu
              Visibility(
                visible: widget.isHost,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final docRef = FirebaseFirestore.instance
                          .collection('tournaments')
                          .doc(widget.lobbyId);
                      docRef.update({'isStarted': true});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Start tournament",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}