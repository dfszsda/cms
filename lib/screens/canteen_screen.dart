// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/canteen_service.dart';
import '../services/auth_service.dart';
import 'cart_screen.dart';

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
  String? _userRole;
  String? _userName;

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
    final currentUser = users.firstWhere((u) => u.uid == _authService.currentUser?.uid);
    setState(() {
      _userRole = currentUser.role;
      _userName = currentUser.fullName;
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
                  await _canteenService.addCanteenItem(data);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Canteen Menu"),
        centerTitle: true,
        actions: [
          if (_userRole != 'retailer')
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
                          userName: _userName ?? "User",
                          userRole: _userRole ?? "student",
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
                      child: Text("${_cartItems.length}", style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search food items...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
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
                    onTap: () => setState(() => _selectedCategory = cat['name']),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isSelected ? cat['color'] : (cat['color'] as Color).withValues(alpha: 0.1),
                          child: Icon(cat['icon'], color: isSelected ? Colors.white : cat['color']),
                        ),
                        const SizedBox(height: 4),
                        Text(cat['name'], style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
              stream: _canteenService.getCanteenItems(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var items = snapshot.data!.docs.map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>
                }).where((item) {
                  bool matchesSearch = item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                  bool matchesCategory = _selectedCategory == "All" || item['category'] == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (items.isEmpty) return const Center(child: Text("No items found"));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.fastfood, color: Colors.orange),
                        ),
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['price'], style: const TextStyle(color: Colors.green)),
                        trailing: _userRole == 'retailer'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddItemDialog(itemId: item['id'], existingData: item)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _canteenService.deleteCanteenItem(item['id'])),
                                ],
                              )
                            : ElevatedButton(
                                onPressed: () => _addToCart(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade50,
                                  foregroundColor: Colors.blue,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      floatingActionButton: _userRole == 'retailer'
          ? FloatingActionButton(
              onPressed: () => _showAddItemDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
