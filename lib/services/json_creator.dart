import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Contestant {
  final String name;
  final String picture;

  Contestant({required this.name, required this.picture});

  Map<String, dynamic> toJson() => {
        'name': name,
        'votes': 0,
        'picture': picture, // Also include picture in the JSON
      };
}

/// Helper function to create an "empty" contestant (placeholder)
Map<String, dynamic> _emptySlot() => {
      'name': '', // Empty name, as requested
      'votes': 0,
      'picture': '', // Also include picture in the JSON
    };

Future<Map<String, List<Map<String, dynamic>>>> createTournamentBracket(
    List<Contestant> contestants) async { // Made async
  int n = contestants.length;

  // 1. Find the next power of two (2, 4, 8, 16...)
  int nextPowerOf2 = pow(2, (log(n) / log(2)).ceil()).toInt(); // e.g., 7 -> 8
  int byes = nextPowerOf2 - n; // e.g., 8 - 7 = 1 "bye"

  // 2. Define round names
  final roundNames = ['1/32', '1/16', '1/8', '1/4', '1/2', '1'];
  // totalRounds is the number of *match rounds* (e.g., 8 players -> 3 rounds: 1/8, 1/4, 1/2)
  int totalRounds = (log(nextPowerOf2) / log(2)).toInt(); // e.g., 3 for 8 players

  // Find the index of the first round (e.g., '1/8' is index 2)
  String firstRoundName = roundNames[roundNames.indexOf('1') - totalRounds];
  int firstRoundIndex = roundNames.indexOf(firstRoundName); // e.g., 2

  // 3. Distribute contestants
  List<Map<String, dynamic>> allContestantsJson =
      contestants.map((c) => c.toJson()).toList();

  // Contestants who get a "bye" are the *last* ones in the list
  List<Map<String, dynamic>> nextRoundByes = [];
  // Contestants who play in the first round
  List<Map<String, dynamic>> firstRoundPairs = [];

  if (byes > 0) {
    // Take the last `byes` number of contestants for the next round
    nextRoundByes = allContestantsJson.sublist(n - byes); // e.g., [contestant7]
    // The rest play in the first round
    firstRoundPairs =
        allContestantsJson.sublist(0, n - byes); // e.g., [6 contestants]
  } else {
    firstRoundPairs = allContestantsJson;
  }

  // 4. Assemble the bracket
  Map<String, List<Map<String, dynamic>>> bracket = {
    firstRoundName: firstRoundPairs,
  };

  // 5. Generate *all* future rounds with empty placeholders
  // e.g., totalRounds = 3. i=1 (1/4), i=2 (1/2), i=3 (1)
  for (int i = 1; i <= totalRounds; i++) {
    // Name of the next round (e.g., 1/4, 1/2, 1)
    String roundName = roundNames[firstRoundIndex + i];

    // Calculate how many slots should be in this round
    // e.g., i=1 (1/4): 8 / 2^1 = 4 slots
    // e.g., i=2 (1/2): 8 / 2^2 = 2 slots
    // e.g., i=3 (1):   8 / 2^3 = 1 slot
    int slotsInThisRound = (nextPowerOf2 / pow(2, i)).toInt();

    // Create a list of N empty placeholders
    bracket[roundName] = List.generate(slotsInThisRound, (_) => _emptySlot());
  }

  // 6. Insert the contestants with byes into their slots in the next round
  if (nextRoundByes.isNotEmpty) {
    String nextRoundName = roundNames[firstRoundIndex + 1]; // e.g., '1/4'

    // Calculate how many winners will come from the first round
    // e.g., 6 players -> 3 matches -> 3 winners
    int winnersFromPrevRound = (firstRoundPairs.length / 2).ceil();

    // Get the list of slots (currently it's [empty, empty, empty, empty])
    List<Map<String, dynamic>> roundSlots = bracket[nextRoundName]!;

    // Insert the "bye" contestants *after* the slots reserved for winners
    for (int i = 0; i < nextRoundByes.length; i++) {
      // They will occupy slots starting from the winnersFromPrevRound index (e.g., index 3)
      roundSlots[winnersFromPrevRound + i] = nextRoundByes[i];
    }
  }

  // 7. Save the bracket to a temporary JSON file
  try {
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = p.join(tempDir.path, 'bracket.json');
    final File jsonFile = File(filePath);
    // Use an encoder with an indent to make the JSON more readable
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String jsonString = encoder.convert(bracket);
    await jsonFile.writeAsString(jsonString);
  } catch (e) {
    // If saving fails, print an error but don't crash the app
    print('Error saving bracket to file: $e');
  }
  print(bracket);
  return bracket;
}
