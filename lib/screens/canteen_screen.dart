// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/canteen_service.dart';
import '../services/auth_service.dart';
import 'cart_screen.dart';
import '../models/user_model.dart';

class CanteenScreen extends StatefulWidget {
  const CanteenScreen({super.key});

  @override
  State<CanteenScreen> createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen> {
  final CanteenService _canteenService = CanteenService();
  final AuthService _authService = AuthService();
  String _searchQuery = "";
  String _selectedCategory = "All";
  List<Map<String, dynamic>> _cartItems = [];
  UserModel? _currentUser;

  final List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.all_inclusive, 'color': Colors.grey},
    {'name': 'Cold-Drink', 'icon': Icons.local_drink, 'color': Colors.blue},
    {'name': 'Junk Food', 'icon': Icons.fastfood, 'color': Colors.red},
    {'name': 'Snacks', 'icon': Icons.set_meal, 'color': Colors.orange},
    {'name': 'Ice Cream', 'icon': Icons.icecream, 'color': Colors.pink},
    {'name': 'Wafers', 'icon': Icons.cookie, 'color': Colors.amber},
    {'name': 'Biscuit', 'icon': Icons.bakery_dining, 'color': Colors.brown},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final users = await _authService.getAllUsers().first;
    final user = users.firstWhere((u) => u.uid == _authService.currentUser?.uid);
    setState(() {
      _currentUser = user;
    });
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      int index = _cartItems.indexWhere((cartItem) => cartItem['name'] == item['name']);
      if (index != -1) {
        _cartItems[index]['quantity']++;
      } else {
        _cartItems.add({
          'name': item['name'],
          'price': item['price'],
          'quantity': 1,
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${item['name']} added to cart!")),
    );
  }

  void _showAddItemDialog({String? itemId, Map<String, dynamic>? existingData}) {
    if (_currentUser?.collegeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("College ID not found. Please relogin.")));
        return;
    }
    
    final nameCtrl = TextEditingController(text: existingData?['name']);
    final priceCtrl = TextEditingController(text: existingData?['price']?.toString().replaceAll('₹', ''));
    String category = existingData?['category'] ?? 'Snacks';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(itemId == null ? "Add Item" : "Edit Item"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Item Name")),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Price (e.g. 20)"), keyboardType: TextInputType.number),
                DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  items: categories.where((c) => c['name'] != 'All').map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name'] as String))).toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogCtx);
                final data = {
                  'name': nameCtrl.text,
                  'price': '₹${priceCtrl.text}',
                  'category': category,
                };
                if (itemId == null) {
                  await _canteenService.addCanteenItem(data, _currentUser!.collegeId!);
                } else {
                  await _canteenService.updateCanteenItem(itemId, data);
                }
                if (mounted) navigator.pop();
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Canteen Menu"),
        centerTitle: !isDesktop,
        actions: [
          if (_currentUser!.role != 'retailer')
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartScreen(
                          cartItems: _cartItems,
                          userName: _currentUser!.fullName,
                          userRole: _currentUser!.role,
                          collegeId: _currentUser!.collegeId!,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
                if (_cartItems.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text("${_cartItems.length}",
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Container(
              width: 250,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey[200]!)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  bool isSelected = _selectedCategory == cat['name'];
                  return ListTile(
                    leading: Icon(cat['icon'],
                        color: isSelected ? cat['color'] : Colors.grey),
                    title: Text(cat['name'],
                        style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? cat['color'] : Colors.black)),
                    selected: isSelected,
                    onTap: () =>
                        setState(() => _selectedCategory = cat['name']),
                  );
                },
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: "Search food items...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isDesktop)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        bool isSelected = _selectedCategory == cat['name'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat['name']),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: isSelected
                                      ? cat['color']
                                      : (cat['color'] as Color)
                                          .withValues(alpha: 0.1),
                                  child: Icon(cat['icon'],
                                      color: isSelected
                                          ? Colors.white
                                          : cat['color']),
                                ),
                                const SizedBox(height: 4),
                                Text(cat['name'],
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _canteenService.getCanteenItems(
                        collegeId: _currentUser!.collegeId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var items = snapshot.data!.docs
                          .map((doc) => {
                                'id': doc.id,
                                ...doc.data() as Map<String, dynamic>
                              })
                          .where((item) {
                        bool matchesSearch = item['name']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                        bool matchesCategory = _selectedCategory == "All" ||
                            item['category'] == _selectedCategory;
                        return matchesSearch && matchesCategory;
                      }).toList();

                      if (items.isEmpty) {
                        return const Center(child: Text("No items found"));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 3 : 1,
                          childAspectRatio: isDesktop ? 2.5 : 3.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.fastfood,
                                    color: Colors.orange),
                              ),
                              title: Text(item['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(item['price'],
                                  style: const TextStyle(color: Colors.green)),
                              trailing: _currentUser!.role == 'retailer'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () => _showAddItemDialog(
                                                itemId: item['id'],
                                                existingData: item)),
                                        IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _canteenService
                                                .deleteCanteenItem(item['id'])),
                                      ],
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _addToCart(item),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade50,
                                        foregroundColor: Colors.blue,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: const Text("ADD"),
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentUser!.role == 'retailer'
          ? FloatingActionButton(
              onPressed: () => _showAddItemDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
