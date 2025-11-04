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
        theme: ThemeData(
          colorScheme: ColorScheme(
            brightness: Brightness.dark,
            primary: AppColors.purple1,
            onPrimary: Colors.black,
            secondary: AppColors.purple2,
            onSecondary: AppColors.purple3,
            error: Colors.red,
            onError: Colors.white,
            background: AppColors.purple5,
            onBackground: AppColors.purple5,
            surface: AppColors.purple4,
            onSurface: AppColors.purple5,
          ),
          scaffoldBackgroundColor: AppColors.purple5,
          useMaterial3: true,
        ),
      home: const TournamentScreen()
    );
  }
}
