import 'dart:math';

class Contestant {
  final String name;
  final String picture;
  final int pictureId;

  Contestant({required this.name, required this.picture, required this.pictureId});

  Map<String, dynamic> toJson() => {
    'name': name,
    'votes': 0,
    'picture_id': pictureId,
  };
}

Map<String, List<Map<String, dynamic>>> createTournamentBracket(List<Contestant> contestants) {
  int n = contestants.length;

  // Find next power of 2 (2, 4, 8, 16, 32...)
  int nextPowerOf2 = pow(2, (log(n) / log(2)).ceil()).toInt();

  // Calculate how many players get a bye
  int byes = nextPowerOf2 - n;

  // Determine round names (1/8, 1/4, 1/2, 1)
  final roundNames = [
    '1/32', '1/16', '1/8', '1/4', '1/2', '1'
  ];
  String firstRound = roundNames[(log(nextPowerOf2) / log(2)).toInt() - 1];

  // Distribute contestants
  List<Map<String, dynamic>> firstRoundPairs = [];
  for (var c in contestants) {
    firstRoundPairs.add(c.toJson());
  }

  // Some players go directly to next round if there's a bye
  List<Map<String, dynamic>> nextRoundByes = [];
  if (byes > 0) {
    nextRoundByes = firstRoundPairs.sublist(n - byes);
    firstRoundPairs = firstRoundPairs.sublist(0, n - byes);
  }

  // Build JSON structure
  Map<String, List<Map<String, dynamic>>> bracket = {
    firstRound: firstRoundPairs,
  };

  // Add remaining rounds empty
  int roundsCount = (log(nextPowerOf2) / log(2)).toInt();
  for (int i = 1; i < roundsCount; i++) {
    bracket[roundNames[(roundNames.indexOf(firstRound) + i)]] = [];
  }

  // Insert auto-advanced contestants into next round
  if (nextRoundByes.isNotEmpty) {
    String nextRoundName = roundNames[(roundNames.indexOf(firstRound) + 1)];
    bracket[nextRoundName] = nextRoundByes;
  }

  return bracket;
}
