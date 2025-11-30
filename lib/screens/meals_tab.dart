import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import '../models/meal_entry.dart';
import '../widgets/glass_card.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/nutrition_ring_painter.dart';
import '../widgets/snackbar_utils.dart';

class MealsTab extends StatefulWidget {
  final Function(int) onEarnXP;
  const MealsTab({super.key, required this.onEarnXP});

  @override
  State<MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends State<MealsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _selectedDate = DateTime.now();
  late List<MealEntry> history;

  @override
  void initState() {
    super.initState();
    DateTime today = DateTime.now();
    history = [
      MealEntry("Avocado Toast", "350 kcal", "08:30 AM", "Prot: 8g • Fat: 12g", "5g", "Vit A, C", Icons.bakery_dining, null, "Breakfast", today, imageUrl: "https://images.unsplash.com/photo-1588137372308-15f75323ca8d?auto=format&fit=crop&w=200&q=80", protein: 8, carbs: 40, fat: 12),
      MealEntry("Greek Yogurt", "120 kcal", "10:30 AM", "Prot: 15g • Fat: 0g", "0g", "Calc", Icons.icecream, null, "Snack", today, imageUrl: "https://images.unsplash.com/photo-1488477181946-6428a029177b?auto=format&fit=crop&w=200&q=80", protein: 15, carbs: 8, fat: 0),
      MealEntry("Chicken Salad", "450 kcal", "01:15 PM", "Prot: 40g • Fat: 8g", "4g", "Iron", Icons.restaurant, null, "Lunch", today, imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=200&q=80", protein: 40, carbs: 10, fat: 8),
    ];
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  Future<void> _showAddMealPopup(BuildContext context) async {
    await showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Color(0xFF1E2129), borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Log Entry", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 20), ListTile(leading: const Icon(Icons.camera_alt, color: Color(0xFF00F0FF)), title: const Text("Take Photo", style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); _pickImageAndShowDetails(ImageSource.camera); }), ListTile(leading: const Icon(Icons.photo_library, color: Color(0xFF6C63FF)), title: const Text("Choose from Gallery", style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); _pickImageAndShowDetails(ImageSource.gallery); }), const SizedBox(height: 20)])));
  }

  Future<void> _pickImageAndShowDetails(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && mounted) _showMealDetailsDialog(imageFile: File(image.path));
    } catch (e) { debugPrint("Error: $e"); }
  }

  // UPDATED DIALOG with CIRCULAR NUTRITION
  void _showMealDetailsDialog({File? imageFile, MealEntry? existingEntry, int? editIndex}) {
    bool isEditing = existingEntry != null;
    String initialName = isEditing ? existingEntry!.name : "Grilled Chicken";
    String initialCals = isEditing ? existingEntry!.cals : "450 kcal";

    TextEditingController nameController = TextEditingController(text: initialName);
    TextEditingController calController = TextEditingController(text: initialCals);
    TextEditingController nutriController = TextEditingController(text: isEditing ? existingEntry!.nutrition : "Prot: 40g • Fat: 10g");
    TextEditingController fiberController = TextEditingController(text: isEditing ? existingEntry!.fiber : "4g");
    TextEditingController vitController = TextEditingController(text: isEditing ? existingEntry!.vitamins : "Vit A, B6");

    double p = isEditing ? existingEntry!.protein : 25;
    double c = isEditing ? existingEntry!.carbs : 30;
    double f = isEditing ? existingEntry!.fat : 10;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => StatefulBuilder(builder: (context, setModalState) {
      return Container(height: MediaQuery.of(context).size.height * 0.9, padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Color(0xFF0F1115), borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 20),

        // CIRCULAR NUTRITION VISUALIZATION
        Center(
          child: SizedBox(
            height: 180, width: 180,
            child: CustomPaint(
              painter: NutritionRingPainter(protein: p, carbs: c, fat: f),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt, color: Colors.orangeAccent),
                    Text(calController.text.replaceAll(" kcal", ""), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text("kcal", style: TextStyle(color: Colors.grey, fontSize: 12))
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildLegendItem("Prot", const Color(0xFFE040FB)),
          const SizedBox(width: 10),
          _buildLegendItem("Carb", const Color(0xFF00E676)),
          const SizedBox(width: 10),
          _buildLegendItem("Fat", const Color(0xFF00B0FF)),
        ]),

        const SizedBox(height: 30),

        if (imageFile != null || existingEntry?.image != null) ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(imageFile ?? existingEntry!.image!, height: 150, width: double.infinity, fit: BoxFit.cover)),

        const SizedBox(height: 20),
        TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Name", labelStyle: TextStyle(color: Colors.grey))),
        const SizedBox(height: 15),
        TextField(controller: calController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Cals", labelStyle: TextStyle(color: Colors.grey))),

        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: TextField(controller: fiberController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Fiber", labelStyle: TextStyle(color: Colors.grey)))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: vitController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Vitamins", labelStyle: TextStyle(color: Colors.grey)))),
        ]),

        const SizedBox(height: 30),
        Row(children: [
          if(isEditing) Expanded(child: BouncingButton(onTap: () { setState(() { history.removeAt(editIndex!); }); Navigator.pop(context); showFuturisticSnackBar(context, "Deleted", Colors.redAccent, icon: SizedBox(height:30, width:30, child: Lottie.network('https://assets2.lottiefiles.com/packages/lf20_WCY7Y6.json'))); }, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent)), child: const Center(child: Icon(Icons.delete, color: Colors.redAccent))))),
          if(isEditing) const SizedBox(width: 10),
          Expanded(flex: 2, child: BouncingButton(onTap: () {
            MealEntry entry = MealEntry(nameController.text, calController.text, "Now", nutriController.text, fiberController.text, vitController.text, Icons.food_bank, imageFile ?? existingEntry?.image, "Lunch", _selectedDate, imageUrl: existingEntry?.imageUrl, protein: p, carbs: c, fat: f);
            setState(() { if (isEditing) history[editIndex!] = entry; else { history.insert(0, entry); widget.onEarnXP(20); } });
            Navigator.pop(context);
            showFuturisticSnackBar(context, isEditing ? "Updated!" : "Logged!", const Color(0xFF00E676), icon: SizedBox(height:40, width:40, child: Lottie.network('https://assets9.lottiefiles.com/packages/lf20_vT1rK7.json')));
          }, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(15)), child: const Center(child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))))
        ]),
        const SizedBox(height: 40),
      ])));
    }));
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<MealEntry> filtered = history.where((e) => _isSameDay(e.dateTime, _selectedDate)).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 130),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Meal Log", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.calendar_month, color: Color(0xFF00F0FF)), onPressed: () => _pickDate(context))
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => _showMealDetailsDialog(), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF1E2129), borderRadius: BorderRadius.circular(15)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: Color(0xFFE09F3E)), SizedBox(width: 8), Text("Manual Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])))),
          const SizedBox(width: 15),
          Expanded(child: GestureDetector(onTap: () => _showAddMealPopup(context), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF1E2129), borderRadius: BorderRadius.circular(15)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code_scanner, color: Color(0xFFE09F3E)), SizedBox(width: 8), Text("AI Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])))),
        ]),
        const SizedBox(height: 30),
        const Text("Recently had", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 15),
        ...filtered.map((e) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Dismissible(
            key: Key("${e.name}_${history.indexOf(e)}"),
            background: Container(color: Colors.redAccent.withOpacity(0.5), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
            onDismissed: (direction) {
              setState(() { history.remove(e); });
              showFuturisticSnackBar(context, "Meal Deleted", Colors.redAccent, icon: SizedBox(height:30, width:30, child: Lottie.network('https://assets2.lottiefiles.com/packages/lf20_WCY7Y6.json')));
            },
            child: GestureDetector(
              onTap: () => _showMealDetailsDialog(existingEntry: e, editIndex: history.indexOf(e)),
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(15), child: e.image != null ? Image.file(e.image!, width: 60, height: 60, fit: BoxFit.cover) : (e.imageUrl != null ? Image.network(e.imageUrl!, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 60, height: 60, color: Colors.grey, child: const Icon(Icons.fastfood))) : Container(width: 60, height: 60, color: Colors.grey, child: const Icon(Icons.fastfood)))),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(e.cals, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                      const SizedBox(height: 4),
                      // Added explicit nutrition details row
                      Text("Prot: ${e.protein.toInt()}g • Fib: ${e.fiber} • ${e.vitamins}", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                    ])),
                    IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), onPressed: () => _showMealDetailsDialog(existingEntry: e, editIndex: history.indexOf(e)))
                  ])
              ),
            )
        ))).toList()
      ]),
    );
  }
}