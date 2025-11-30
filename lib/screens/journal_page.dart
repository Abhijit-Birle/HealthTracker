import 'package:flutter/material.dart';
import '../widgets/bouncing_button.dart';

class FullScreenJournalPage extends StatelessWidget {
  final Function(String, String) onAddEntry; // Callback
  const FullScreenJournalPage({super.key, required this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("Journal"), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: titleController, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), decoration: const InputDecoration(hintText: "Title", hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none)),
            const Divider(color: Colors.white24),
            Expanded(child: TextField(controller: bodyController, style: const TextStyle(color: Colors.white70), maxLines: null, decoration: const InputDecoration(hintText: "Write your thoughts...", hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none))),
            BouncingButton(
                onTap: () {
                  if (bodyController.text.isNotEmpty) {
                    onAddEntry("Journal", titleController.text.isNotEmpty ? "${titleController.text}: ${bodyController.text}" : bodyController.text);
                    Navigator.pop(context);
                  }
                },
                child: Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFE040FB), borderRadius: BorderRadius.circular(15)), child: const Center(child: Text("Save Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
            )
          ],
        ),
      ),
    );
  }
}