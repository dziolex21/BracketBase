import 'dart:math';

class Contestant {
  final String name;
  final String picture;
  final int pictureId;

  Contestant({
    required this.name,
    required this.picture,
    required this.pictureId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'votes': 0,
    'picture_id': pictureId,
  };
}

Map<String, List<Map<String, dynamic>>> createTournamentBracket(List<Contestant> contestants) {
  int n = contestants.length;
  int nextPowerOf2 = pow(2, (log(n) / log(2)).ceil()).toInt();
  int byes = nextPowerOf2 - n;

  final roundNames = ['1/32', '1/16', '1/8', '1/4', '1/2', '1'];
  String firstRound = roundNames[(log(nextPowerOf2) / log(2)).toInt() - 1];

  List<Map<String, dynamic>> firstRoundPairs = contestants.map((c) => c.toJson()).toList();

  List<Map<String, dynamic>> nextRoundByes = [];
  if (byes > 0) {
    nextRoundByes = firstRoundPairs.sublist(n - byes);
    firstRoundPairs = firstRoundPairs.sublist(0, n - byes);
  }

  Map<String, List<Map<String, dynamic>>> bracket = {
    firstRound: firstRoundPairs,
  };

  int roundsCount = (log(nextPowerOf2) / log(2)).toInt();
  for (int i = 1; i < roundsCount; i++) {
    bracket[roundNames[(roundNames.indexOf(firstRound) + i)]] = [];
  }

  if (nextRoundByes.isNotEmpty) {
    String nextRoundName = roundNames[(roundNames.indexOf(firstRound) + 1)];
    bracket[nextRoundName] = nextRoundByes;
  }

  return bracket;
}

void main() {
  final contestants = [
    Contestant(name: 'Misato', picture: 'pic1.jpg', pictureId: 1),
    Contestant(name: 'Rei', picture: 'pic2.jpg', pictureId: 2),
    Contestant(name: 'Asuka', picture: 'pic3.jpg', pictureId: 3),
    Contestant(name: 'eva1', picture: 'pic3.jpg', pictureId: 3),
    Contestant(name: 'eva2', picture: 'pic3.jpg', pictureId: 3),
    Contestant(name: 'eva3', picture: 'pic3.jpg', pictureId: 3),
    Contestant(name: 'eva0', picture: 'pic3.jpg', pictureId: 3),
  ];

  final bracket = createTournamentBracket(contestants);
  print(bracket);
}
