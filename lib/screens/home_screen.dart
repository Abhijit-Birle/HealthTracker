// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/meal_provider.dart';
import '../services/upload_service.dart';
import '../services/api_service.dart';
import '../models/meal.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _uploading = false;
  final picker = ImagePicker();

  Future<void> _pick(ImageSource src) async {
    final picked = await picker.pickImage(source: src, imageQuality: 80);
    if (picked == null) return;
    setState(() => _image = File(picked.path));
  }

  Future<void> _uploadAndAnalyze() async {
    if (_image == null) return;
    setState(() => _uploading = true);
    try {
      // 1) Upload via presigned
      final fileUrl = await UploadService.uploadFile(_image!);

      // 2) Notify backend to process
      final mealJson = await ApiService.notifyProcessImage(fileUrl);

      // 3) Add to provider
      Provider.of<MealProvider>(context, listen: false).addMealRaw(mealJson);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processed successfully')));
    } catch (e) {
      debugPrint('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MealProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('HealthTracker POC')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _image != null
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_image!, height: 260, fit: BoxFit.cover))
              : Container(height: 260, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Center(child: Text('No image selected'))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ElevatedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera')),
            ElevatedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo), label: const Text('Gallery')),
          ]),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: (_uploading || _image == null) ? null : _uploadAndAnalyze,
            icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload),
            label: Text(_uploading ? 'Uploading...' : 'Upload & Analyze'),
          ),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerLeft, child: Text('Recent Meals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          ...provider.meals.reversed.map((m) => MealTile(meal: m)).toList()
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkoutScreen())),
        child: const Icon(Icons.fitness_center),
      ),
    );
  }
}

class MealTile extends StatelessWidget {
  final Meal meal;
  const MealTile({required this.meal, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: (meal.imageUrl != null) ? Image.network(meal.imageUrl!, width: 64, fit: BoxFit.cover) : null,
        title: Text('${meal.name} • ${meal.calories.toStringAsFixed(0)} kcal'),
        subtitle: Text('P ${meal.protein}g • C ${meal.carbs}g • F ${meal.fat}g'),
        trailing: Text('${meal.date.toLocal().toIso8601String().split("T").first}'),
      ),
    );
  }
}
