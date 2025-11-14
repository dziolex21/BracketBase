import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tournament_app/configs/color_data.dart';
import 'package:tournament_app/services/image_converter.dart';
import 'package:tournament_app/services/json_creator.dart';

class ContestantEditorScreen extends StatefulWidget {
  final Contestant? contestant;

  const ContestantEditorScreen({super.key, this.contestant});

  @override
  State<ContestantEditorScreen> createState() => _ContestantEditorScreenState();
}

class _ContestantEditorScreenState extends State<ContestantEditorScreen> {
  late final TextEditingController _nameController;
  late String _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contestant?.name);
    _imagePath = widget.contestant?.picture ?? 'assets/placeholder_image.png';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List originalBytes = await image.readAsBytes();
      final Uint8List convertedBytes = await ImageConverter.convert(originalBytes);
      final tempDir = await getTemporaryDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = p.join(tempDir.path, fileName);
      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(convertedBytes);

      setState(() {
        _imagePath = filePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purple5,
      appBar: AppBar(
        backgroundColor: AppColors.purple5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.purple1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Editor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: AppColors.purple3,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppColors.purple2),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.purple4,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.purple2),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: _imagePath.startsWith('assets/')
                            ? Image.asset(_imagePath)
                            : Image.file(File(_imagePath)),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple3,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
                        label: const Text(
                          'Change image',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.isNotEmpty) {
                            Navigator.of(context).pop(Contestant(
                              name: _nameController.text,
                              picture: _imagePath,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple1,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (widget.contestant != null) ...[
                      const SizedBox(height: 8.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop('DELETE');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline, color: Colors.white),
                          label: const Text(
                            'Delete',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
