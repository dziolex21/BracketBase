// lib/views/asset_image_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';

// --- Te listy MUSZĄ odpowiadać nazwom plików w Twoich folderach assets ---
const List<String> animalImages = [
  'assets/animals/Ananas.jpeg',
  'assets/animals/Arbuz.jpg',
  'assets/animals/Awocado.webp',
  'assets/animals/Banany.jpg',
  'assets/animals/Borówka.jpg',
  'assets/animals/Brzoskwinia.jpg',
  'assets/animals/Granat.jpg',
  'assets/animals/Gruszka.jpg',
  'assets/animals/Jabłko.jpg',
  'assets/animals/Jeżyna.png',
  'assets/animals/Kiwi.jpg',
  'assets/animals/Liczi.jpg',
  'assets/animals/Malinka.jpeg',
  'assets/animals/Mango.jpg',
  'assets/animals/Morela.webp',
  'assets/animals/Pomarańcza.webp',
  'assets/animals/Truskawka.png',
  'assets/animals/Winogrona.jpg',
  'assets/animals/Wiśnie.webp',
  'assets/animals/Zapomniałem.png',
  'assets/animals/Śliwka.png',
];

const List<String> avatarImages = [
  'assets/avatars/Discord2.jpeg',
  'assets/avatars/Discord3.jpeg',
  'assets/avatars/Discord4.png',
  'assets/avatars/Discord5.jpg',
  'assets/avatars/Discord6.jpg',
  'assets/avatars/Discord7.jpg',
  'assets/avatars/Discord8.png',
  'assets/avatars/Discord9.png',
  'assets/avatars/Discord10.webp',
  'assets/avatars/Discord11.jpeg',
  'assets/avatars/Discord12.webp',
  'assets/avatars/Discord13.webp',
  'assets/avatars/Discord14.webp',
  'assets/avatars/Discord15.jpg',
  'assets/avatars/Discord16.webp',
  'assets/avatars/Discord17.jpg',
];

// -----------------------------------------------------------------------

class AssetImagePickerScreen extends StatelessWidget {
  const AssetImagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
          bottom: const TabBar(
            indicatorColor: AppColors.purple1,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Animals'),
              Tab(text: 'Avatars'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ImageGrid(imagePaths: animalImages),
            _ImageGrid(imagePaths: avatarImages),
          ],
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> imagePaths;

  const _ImageGrid({required this.imagePaths});

  @override
  Widget build(BuildContext context) {
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
            // Zwróć wybraną ścieżkę do poprzedniego ekranu
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
