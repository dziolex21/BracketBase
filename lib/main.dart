import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/views/start_screen.dart';
import 'package:tournament_app/views/tournament_lobby.dart';
import 'package:tournament_app/views/voting_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tournament App',
      home: const TournamentScreen()
    );
  }
}
