// lib/views/asset_image_picker_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tournament_app/configs/color_data.dart';

class AssetImagePickerScreen extends StatefulWidget {
  const AssetImagePickerScreen({super.key});

  @override
  State<AssetImagePickerScreen> createState() => _AssetImagePickerScreenState();
}

class _AssetImagePickerScreenState extends State<AssetImagePickerScreen> {
  // Mapa przechowująca kategorie i przypisane do nich obrazy.
  // Klucz: Nazwa kategorii (np. "Animals"), Wartość: Lista ścieżek do obrazów.
  Map<String, List<String>> imageCategories = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssetCategories();
  }

  /// Funkcja do dynamicznego wczytywania kategorii i obrazów z folderu assets.
  Future<void> _loadAssetCategories() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final Map<String, List<String>> categories = {};

    // Iterujemy po wszystkich ścieżkach zasobów z manifestu.
    for (String assetPath in manifestMap.keys) {
      // Sprawdzamy, czy ścieżka zaczyna się od 'assets/' i zawiera podfolder.
      // Przykład: 'assets/fruits/cat.jpg'
      if (assetPath.startsWith('assets/') && assetPath.split('/').length > 2) {
        // Wyodrębniamy nazwę podfolderu (kategorii).
        // 'assets/fruits/cat.jpg' -> 'fruits'
        final categoryName = assetPath.split('/')[1];

        // Ignorujemy pliki ukryte (np. .DS_Store na macOS).
        final fileName = assetPath.split('/').last;
        if (fileName.startsWith('.')) {
          continue;
        }

        // Jeśli kategoria nie istnieje jeszcze w naszej mapie, tworzymy ją.
        if (!categories.containsKey(categoryName)) {
          categories[categoryName] = [];
        }

        // Dodajemy ścieżkę obrazu do odpowiedniej kategorii.
        categories[categoryName]!.add(assetPath);
      }
    }

    setState(() {
      imageCategories = categories;
      isLoading = false;
    });
  }

  /// Funkcja pomocnicza do zamiany nazwy folderu na ładną nazwę kategorii.
  /// Przykład: "fruits" -> "Animals"
  String _formatCategoryName(String name) {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // Pobieramy nazwy kategorii do stworzenia zakładek.
    final categoryKeys = imageCategories.keys.toList();

    return DefaultTabController(
      // Liczba zakładek jest teraz dynamiczna.
      length: categoryKeys.length,
      child: Scaffold(
        backgroundColor: AppColors.purple5,
        appBar: AppBar(
          backgroundColor: AppColors.purple5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.purple1),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Choose Image',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          // Jeśli nie ma kategorii, nie pokazuj paska z zakładkami.
          bottom: categoryKeys.isEmpty
              ? null
              : TabBar(
            isScrollable: true, // Pozwala przewijać zakładki, jeśli jest ich dużo.
            indicatorColor: AppColors.purple1,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            // Dynamicznie tworzymy zakładki na podstawie kluczy mapy.
            tabs: categoryKeys
                .map((key) => Tab(text: _formatCategoryName(key)))
                .toList(),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.purple1))
        // Jeśli nie ma kategorii, pokaż informację.
            : categoryKeys.isEmpty
            ? const Center(
          child: Text(
            'No image categories found in assets.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        )
        // Dynamicznie tworzymy widoki dla każdej zakładki.
            : TabBarView(
          children: categoryKeys
              .map((key) => _ImageGrid(imagePaths: imageCategories[key]!))
              .toList(),
        ),
      ),
    );
  }
}

// Widget _ImageGrid pozostaje bez zmian.
class _ImageGrid extends StatelessWidget {
  final List<String> imagePaths;

  const _ImageGrid({required this.imagePaths});

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) {
      return const Center(
        child: Text(
          'No images found in this category.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemCount: imagePaths.length,
      itemBuilder: (context, index) {
        final imagePath = imagePaths[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop(imagePath);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
