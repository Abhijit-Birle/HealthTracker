import 'package:flutter/material.dart';

class FullScreenChatPage extends StatefulWidget {
  final Function(String, String) onAddEntry; // Callback
  const FullScreenChatPage({super.key, required this.onAddEntry});

  @override
  State<FullScreenChatPage> createState() => _FullScreenChatPageState();
}

class _FullScreenChatPageState extends State<FullScreenChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {"text": "Hi there! I'm here to listen.", "isUser": false}
  ];

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    String userText = _controller.text;
    setState(() {
      _messages.add({"text": userText, "isUser": true});
      Future.delayed(const Duration(seconds: 1), () {
        if(mounted) setState(() => _messages.add({"text": "I hear you.", "isUser": false}));
      });
    });
    // Save to main history
    widget.onAddEntry("Chat", userText);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("AI Companion"), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Column(children: [Expanded(child: ListView.builder(padding: const EdgeInsets.all(20), itemCount: _messages.length, itemBuilder: (ctx, i) { final msg = _messages[i]; bool isUser = msg['isUser']; return Align(alignment: isUser ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15), constraints: const BoxConstraints(maxWidth: 250), decoration: BoxDecoration(color: isUser ? const Color(0xFF6C63FF).withOpacity(0.3) : Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: isUser ? const Color(0xFF6C63FF).withOpacity(0.5) : Colors.transparent)), child: Text(msg['text'], style: const TextStyle(color: Colors.white)))); })), Container(padding: const EdgeInsets.all(20), color: Colors.black54, child: Row(children: [Expanded(child: TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Type a message...", hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none))), IconButton(icon: const Icon(Icons.send, color: Color(0xFF6C63FF)), onPressed: _sendMessage)]))]),
    );
  }
}