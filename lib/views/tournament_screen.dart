import 'package:flutter/material.dart';

class Contestant {
  final String name;
  final String? picture;

  Contestant({required this.name, this.picture});
}

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  // Mock contestants for testing locally
  final List<Contestant> contestants = [
    Contestant(name: 'Misato', picture: null),
    Contestant(name: 'Rei', picture: null),
    Contestant(name: 'Asuka', picture: null),
    Contestant(name: 'Shinji', picture: null),
  ];

  Contestant? semiFinalWinner1;
  Contestant? semiFinalWinner2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A2674),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E1A47),
        title: const Text(
          "Tournament",
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildStageSelector(),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: _buildBracket(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
              child: const Text("Continue", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stageChip("1/16", false),
        _stageChip("1/8", false),
        _stageChip("1/4", false),
        _stageChip("Final", true),
      ],
    );
  }

  Widget _stageChip(String text, bool selected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.purple.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBracket() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRound([
            contestants[0],
            contestants[1],
            contestants[2],
            contestants[3],
          ]),
          const SizedBox(width: 40),
          _buildRound([
            Contestant(name: 'Rei', picture: null),
            Contestant(name: 'Asuka', picture: null),
          ]),
          const SizedBox(width: 40),
          _buildFinal(),
        ],
      ),
    );
  }

  Widget _buildRound(List<Contestant> roundContestants) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: roundContestants.map((c) => _contestantCard(c)).toList(),
    );
  }

  Widget _contestantCard(Contestant c) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.purple.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.purple.shade200,
              borderRadius: BorderRadius.circular(8),
              image: c.picture != null
                  ? DecorationImage(image: AssetImage(c.picture!), fit: BoxFit.cover)
                  : null,
            ),
            child: c.picture == null
                ? const Icon(Icons.person, color: Colors.white, size: 40)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            c.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFinal() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.help_outline, color: Colors.white, size: 48),
      ],
    );
  }
}
