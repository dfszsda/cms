import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/book_order_model.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';

class LibraryManagementScreen extends StatefulWidget {
  final String? collegeId;
  const LibraryManagementScreen({super.key, this.collegeId});

  @override
  State<LibraryManagementScreen> createState() => _LibraryManagementScreenState();
}

class _LibraryManagementScreenState extends State<LibraryManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Row(
          children: [
            if (isDesktop && widget.collegeId == null)
              NavigationRail(
                extended: size.width > 1200,
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Librarian')),
                  NavigationRailDestination(icon: Icon(Icons.history_rounded), label: Text('Orders')),
                  NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Settings')),
                ],
                selectedIndex: 0,
                onDestinationSelected: (index) {
                  if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                },
              ),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    expandedHeight: isDesktop ? 80.0 : 120.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: theme.colorScheme.primary,
                    title: Text(widget.collegeId == null ? "Library Portal" : "Library Management", 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.indigo[800]!, Colors.indigo[500]!],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      if (widget.collegeId == null)
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                          onPressed: () async {
                            await _auth.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      const SizedBox(width: 8),
                    ],
                    bottom: TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(icon: Icon(Icons.book_rounded), text: "Books"),
                        Tab(icon: Icon(Icons.shopping_cart_rounded), text: "Orders"),
                        Tab(icon: Icon(Icons.card_membership_rounded), text: "Members"),
                      ],
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    _buildBooksTab(),
                    _buildOrdersTab(),
                    _buildMembersTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddBookDialog,
          backgroundColor: Colors.indigo,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBooksTab() {
    Query query = _firestore.collection('books');
    if (widget.collegeId != null) {
      query = query.where('collegeId', isEqualTo: widget.collegeId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final books = snapshot.data!.docs.map((doc) => BookModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
        
        if (books.isEmpty) return const Center(child: Text("No books found."));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.imageUrl != null 
                    ? Image.network(book.imageUrl!, width: 50, height: 70, fit: BoxFit.cover) 
                    : Container(color: Colors.indigo[50], width: 50, height: 70, child: const Icon(Icons.book, color: Colors.indigo)),
                ),
                title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${book.author}\nAvailable: ${book.quantity}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.blue), onPressed: () => _showAddBookDialog(book: book)),
                    IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.red), onPressed: () => _firestore.collection('books').doc(book.id).delete()),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    Query query = _firestore.collection('book_orders');
    if (widget.collegeId != null) {
      query = query.where('collegeId', isEqualTo: widget.collegeId);
    }
    query = query.orderBy('orderDate', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!.docs.map((doc) => BookOrderModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

        if (orders.isEmpty) return const Center(child: Text("No orders found."));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                title: Text(order.bookTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("User: ${order.userName}\nStatus: ${order.status}"),
                trailing: order.status == 'Pending' ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check_circle_rounded, color: Colors.green), onPressed: () => _updateOrderStatus(order, 'Issued')),
                    IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.red), onPressed: () => _updateOrderStatus(order, 'Rejected')),
                  ],
                ) : order.status == 'Issued' ? ElevatedButton(
                  onPressed: () => _updateOrderStatus(order, 'Returned'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: const Text("Return"),
                ) : Chip(label: Text(order.status)),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateOrderStatus(BookOrderModel order, String newStatus) async {
    await _firestore.collection('book_orders').doc(order.id).update({
      'status': newStatus,
      if (newStatus == 'Returned') 'returnDate': FieldValue.serverTimestamp(),
    });

    if (newStatus == 'Issued') {
      await _firestore.collection('books').doc(order.bookId).update({
        'quantity': FieldValue.increment(-1),
      });
    } else if (newStatus == 'Returned') {
      await _firestore.collection('books').doc(order.bookId).update({
        'quantity': FieldValue.increment(1),
      });
    }
  }

  Widget _buildMembersTab() {
    Query query = _firestore.collection('library_memberships');
    if (widget.collegeId != null) {
      query = query.where('collegeId', isEqualTo: widget.collegeId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final memberships = snapshot.data!.docs;

        if (memberships.isEmpty) return const Center(child: Text("No members found."));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: memberships.length,
          itemBuilder: (context, index) {
            final data = memberships[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            final userId = data['userId'];

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(userId).get(),
              builder: (context, userSnap) {
                String userName = 'Loading...';
                if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                  final userData = userSnap.data!.data() as Map<String, dynamic>?;
                  userName = userData?['fullName'] ?? 'Unknown';
                }

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Membership Status: $status"),
                    trailing: status == 'Pending' ? ElevatedButton(
                      onPressed: () => _firestore.collection('library_memberships').doc(userId).update({
                        'status': 'Active',
                        'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
                      }),
                      child: const Text("Approve"),
                    ) : const Icon(Icons.check_circle_rounded, color: Colors.green),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddBookDialog({BookModel? book}) {
    final titleCtrl = TextEditingController(text: book?.title);
    final authorCtrl = TextEditingController(text: book?.author);
    final categoryCtrl = TextEditingController(text: book?.category);
    final qtyCtrl = TextEditingController(text: book?.quantity.toString());
    final descCtrl = TextEditingController(text: book?.description);
    String condition = book?.condition ?? 'New';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(book == null ? "Add New Book" : "Edit Book Details"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
              TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: "Author")),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: "Category")),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: condition,
                items: ['New', 'Old'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => condition = val!,
                decoration: const InputDecoration(labelText: "Condition", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'title': titleCtrl.text,
                'author': authorCtrl.text,
                'category': categoryCtrl.text,
                'quantity': int.parse(qtyCtrl.text),
                'description': descCtrl.text,
                'condition': condition,
                'collegeId': widget.collegeId,
                'createdAt': book?.createdAt != null ? Timestamp.fromDate(book!.createdAt) : FieldValue.serverTimestamp(),
              };

              if (book == null) {
                await _firestore.collection('books').add(data);
              } else {
                await _firestore.collection('books').doc(book.id).update(data);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
