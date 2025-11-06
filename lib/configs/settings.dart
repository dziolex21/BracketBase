import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppSettings {
  bool imagesEnabled;
  int selectedTiebreaker;

  AppSettings({
    this.imagesEnabled = true,
    this.selectedTiebreaker = 0,
  });

  factory AppSettings.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return AppSettings(
      imagesEnabled: json['imagesEnabled'] ?? true,
      selectedTiebreaker: json['selectedTiebreaker'] ?? 0,
    );
  }

  String toJson() {
    final Map<String, dynamic> data = {
      'imagesEnabled': imagesEnabled,
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
      // If there's an error, we'll fall back to default settings.
    }
    return AppSettings(); // Return default settings if file doesn't exist or on error.
  }

  Future<void> save() async {
    try {
      final file = await _localFile;
      await file.writeAsString(toJson());
    } catch (e) {
      // Handle or log the error as needed.
    }
  }
}
