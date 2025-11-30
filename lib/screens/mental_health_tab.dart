import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/glass_card.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/futuristic_slider.dart';
import '../widgets/snackbar_utils.dart';
import 'chat_page.dart';
import 'journal_page.dart';

class MentalHealthTab extends StatefulWidget {
  const MentalHealthTab({super.key});
  @override
  State<MentalHealthTab> createState() => _MentalHealthTabState();
}

class _MentalHealthTabState extends State<MentalHealthTab> {
  String _aiQuote = "Your mind is a garden. Your thoughts are the seeds.";
  List<Map<String, String>> _history = [
    {"type": "Chat", "date": "Today", "preview": "Feeling anxious about work..."},
    {"type": "Journal", "date": "Yesterday", "preview": "Grateful for the sunshine today."},
    {"type": "Chat", "date": "2 days ago", "preview": "Discussed sleep patterns."},
  ];

  void _addEntry(String type, String text) {
    setState(() {
      _history.insert(0, {
        "type": type,
        "date": "Just Now",
        "preview": text,
      });
    });
    showFuturisticSnackBar(context, "$type Saved!", const Color(0xFF00E676), icon: SizedBox(height:30, width:30, child: Lottie.network('https://assets3.lottiefiles.com/packages/lf20_HjK9Ol.json'))); // Pencil Lottie
  }

  void _openChatSession() { Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => FullScreenChatPage(onAddEntry: _addEntry))); }
  void _openJournalSession() { Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => FullScreenJournalPage(onAddEntry: _addEntry))); }
  void _showAIInsight() { showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1E2129), title: const Row(children: [Icon(Icons.auto_awesome, color: Color(0xFFE040FB)), SizedBox(width: 10), Text("AI Mind Analysis", style: TextStyle(color: Colors.white))]), content: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Current State: Balanced", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)), SizedBox(height: 10), Text("You have been logging consistent positive journal entries.", style: TextStyle(color: Colors.white70)), SizedBox(height: 15), Text("Suggestion:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("Try a 5-minute meditation before sleep.", style: TextStyle(color: Colors.white54))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Colors.grey)))])); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 60, 20, 100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Mental Wellness", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 20),
      GlassCard(color: Colors.white.withOpacity(0.08), child: Padding(padding: const EdgeInsets.all(25), child: Column(children: [
        // REPLACED WITH BRAIN LOTTIE, USE ASSET IF LOCAL
        SizedBox(height: 120, width: 120, child: Lottie.asset('assets/Lottie Animation.lottie', errorBuilder: (c,e,s) => const Icon(Icons.auto_awesome, color: Color(0xFF6C63FF), size: 50))),
        const SizedBox(height: 15), Text("\"$_aiQuote\"", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white))]))),
      const SizedBox(height: 30),
      Row(children: [Expanded(child: BouncingButton(onTap: _openChatSession, child: Container(height: 100, decoration: BoxDecoration(color: const Color(0xFF00B0FF).withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00B0FF).withOpacity(0.4))), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.chat_bubble_outline, color: Color(0xFF00B0FF), size: 30), SizedBox(height: 10), Text("Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])))), const SizedBox(width: 15), Expanded(child: BouncingButton(onTap: _openJournalSession, child: Container(height: 100, decoration: BoxDecoration(color: const Color(0xFFE040FB).withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE040FB).withOpacity(0.4))), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.book, color: Color(0xFFE040FB), size: 30), SizedBox(height: 10), Text("Journal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))))]),
      const SizedBox(height: 20),
      BouncingButton(onTap: _showAIInsight, child: Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00F0FF)]), borderRadius: BorderRadius.circular(15)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.analytics, color: Colors.white), SizedBox(width: 10), Text("View AI Insights", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))),
      const SizedBox(height: 30),
      const Text("History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 15),
      ..._history.asMap().entries.map((entry) { int idx = entry.key; var item = entry.value; return Padding(padding: const EdgeInsets.only(bottom: 10), child: Dismissible(key: Key("${item['type']}_$idx"), background: Container(color: Colors.redAccent.withOpacity(0.5), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.delete, color: Colors.white)), secondaryBackground: Container(color: Colors.blueAccent.withOpacity(0.5), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.archive, color: Colors.white)), onDismissed: (direction) { setState(() { _history.removeAt(idx); }); bool isDelete = direction == DismissDirection.startToEnd; showFuturisticSnackBar(context, isDelete ? "Deleted" : "Archived", isDelete ? Colors.redAccent : Colors.blueAccent, icon: SizedBox(height:30, width:30, child: Lottie.network(isDelete ? 'https://assets2.lottiefiles.com/packages/lf20_WCY7Y6.json' : 'https://assets8.lottiefiles.com/packages/lf20_1LhsaB.json'))); }, child: GlassCard(child: ListTile(leading: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: item['type'] == 'Chat' ? Colors.blue.withOpacity(0.2) : Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(5)), child: Text(item['type'] == 'Chat' ? "💬 Chat" : "📝 Journal", style: TextStyle(color: item['type'] == 'Chat' ? Colors.blue : Colors.purple, fontSize: 10, fontWeight: FontWeight.bold))), title: Text(item['preview']!, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Text(item['date']!, style: const TextStyle(color: Colors.white30, fontSize: 12)))))); }).toList()
    ]));
  }
}