import 'package:flutter/material.dart';
import 'package:tournament_app/configs/color_data.dart';

class ContestantEditorScreen extends StatefulWidget {
  final String? contestantName;

  const ContestantEditorScreen({super.key, this.contestantName});

  @override
  State<ContestantEditorScreen> createState() => _ContestantEditorScreenState();
}

class _ContestantEditorScreenState extends State<ContestantEditorScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contestantName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
        title: Text(
          'Editor',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        child: Image.asset('assets/placeholder_image.png'),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement image change functionality
                        },
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
                          Navigator.of(context).pop(_nameController.text);
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
