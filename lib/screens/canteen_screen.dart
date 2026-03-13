import 'package:flutter/material.dart';
import 'cart_screen.dart';

class CanteenScreen extends StatefulWidget {
  const CanteenScreen({super.key});

  @override
  State<CanteenScreen> createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen> {
  String _searchQuery = "";
  String _selectedCategory = "All";
  // ignore: prefer_final_fields
  List<Map<String, dynamic>> _cartItems = [];

  final List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.all_inclusive, 'color': Colors.grey},
    {'name': 'Cold-Drink', 'icon': Icons.local_drink, 'color': Colors.blue},
    {'name': 'Junk Food', 'icon': Icons.fastfood, 'color': Colors.red},
    {'name': 'Snacks', 'icon': Icons.set_meal, 'color': Colors.orange},
    {'name': 'Ice Cream', 'icon': Icons.icecream, 'color': Colors.pink},
    {'name': 'Wafers', 'icon': Icons.cookie, 'color': Colors.amber},
    {'name': 'Biscuit', 'icon': Icons.bakery_dining, 'color': Colors.brown},
  ];

  final List<Map<String, dynamic>> canteenItems = [
    {'name': 'Coca Cola', 'category': 'Cold-Drink', 'price': '₹40'},
    {'name': 'Pepsi', 'category': 'Cold-Drink', 'price': '₹40'},
    {'name': 'Burger', 'category': 'Junk Food', 'price': '₹60'},
    {'name': 'Pizza', 'category': 'Junk Food', 'price': '₹120'},
    {'name': 'Samosa', 'category': 'Snacks', 'price': '₹20'},
    {'name': 'Vadapav', 'category': 'Snacks', 'price': '₹20'},
    {'name': 'Vanilla Ice Cream', 'category': 'Ice Cream', 'price': '₹50'},
    {'name': 'Chocolate Cone', 'category': 'Ice Cream', 'price': '₹70'},
    {'name': 'Balaji Wafers', 'category': 'Wafers', 'price': '₹10'},
    {'name': 'Kurkure', 'category': 'Wafers', 'price': '₹20'},
    {'name': 'Parle-G', 'category': 'Biscuit', 'price': '₹5'},
    {'name': 'Hide & Seek', 'category': 'Biscuit', 'price': '₹30'},
  ];

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

  @override
  Widget build(BuildContext context) {
    var filteredItems = canteenItems.where((item) {
      bool matchesSearch = item['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesCategory = _selectedCategory == "All" || item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Canteen Menu"),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(cartItems: _cartItems),
                    ),
                  ).then((_) => setState(() {})); // Update when returning
                },
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      "${_cartItems.length}",
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
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

          // Categories Row
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
                          backgroundColor: isSelected ? cat['color'] : cat['color'].withOpacity(0.1),
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

          // Items List
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text("No items found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
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
                          trailing: ElevatedButton(
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
                  ),
          ),
        ],
      ),
    );
  }
}
