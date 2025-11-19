import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppSettings {
  int selectedTiebreaker;

  AppSettings({
    this.selectedTiebreaker = 0,
  });

  factory AppSettings.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return AppSettings(
      selectedTiebreaker: json['selectedTiebreaker'] ?? 0,
    );
  }

  String toJson() {
    final Map<String, dynamic> data = {
      'selectedTiebreaker': selectedTiebreaker,
    };
    return jsonEncode(data);
  }

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/user_settings.json');
  }

  static Future<AppSettings> load() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return AppSettings.fromJson(contents);
      }
    } catch (e) {
      // W przypadku błędu zwracamy ustawienia domyślne
    }
    return AppSettings(); // Zwróć domyślne ustawienia, jeśli plik nie istnieje lub wystąpi błąd
  }

  Future<void> save() async {
    try {
      final file = await _localFile;
      await file.writeAsString(toJson());
    } catch (e) {
      // Obsłuż błąd według potrzeb
    }
  }
}
