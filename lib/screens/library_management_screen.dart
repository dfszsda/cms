import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/book_order_model.dart';

class LibraryManagementScreen extends StatefulWidget {
  final String? collegeId;
  const LibraryManagementScreen({super.key, this.collegeId});

  @override
  State<LibraryManagementScreen> createState() => _LibraryManagementScreenState();
}

class _LibraryManagementScreenState extends State<LibraryManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: widget.collegeId == null ? AppBar(
          title: const Text("Library Management"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.book), text: "Books"),
              Tab(icon: Icon(Icons.shopping_cart), text: "Orders"),
              Tab(icon: Icon(Icons.card_membership), text: "Members"),
            ],
          ),
        ) : null,
        body: Column(
          children: [
            if (widget.collegeId != null)
              const TabBar(
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.indigo,
                tabs: [
                  Tab(icon: Icon(Icons.book), text: "Books"),
                  Tab(icon: Icon(Icons.shopping_cart), text: "Orders"),
                  Tab(icon: Icon(Icons.card_membership), text: "Members"),
                ],
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildBooksTab(),
                  _buildOrdersTab(),
                  _buildMembersTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddBookDialog,
          backgroundColor: Colors.indigo,
          child: const Icon(Icons.add, color: Colors.white),
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
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return ListTile(
              leading: book.imageUrl != null ? Image.network(book.imageUrl!, width: 50, height: 50, fit: BoxFit.cover) : const Icon(Icons.book),
              title: Text(book.title),
              subtitle: Text("${book.author} | Qty: ${book.quantity}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddBookDialog(book: book)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _firestore.collection('books').doc(book.id).delete()),
                ],
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
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(order.bookTitle),
                subtitle: Text("By: ${order.userName}\nStatus: ${order.status}"),
                trailing: order.status == 'Pending' ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _updateOrderStatus(order, 'Issued')),
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _updateOrderStatus(order, 'Rejected')),
                  ],
                ) : order.status == 'Issued' ? TextButton(
                  onPressed: () => _updateOrderStatus(order, 'Returned'),
                  child: const Text("Mark Returned"),
                ) : null,
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

                return ListTile(
                  title: Text(userName),
                  subtitle: Text("Status: $status"),
                  trailing: status == 'Pending' ? ElevatedButton(
                    onPressed: () => _firestore.collection('library_memberships').doc(userId).update({
                      'status': 'Active',
                      'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
                    }),
                    child: const Text("Approve"),
                  ) : null,
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
        title: Text(book == null ? "Add Book" : "Edit Book"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
              TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: "Author")),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: "Category")),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
              DropdownButtonFormField<String>(
                value: condition,
                items: ['New', 'Old'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => condition = val!,
                decoration: const InputDecoration(labelText: "Condition"),
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
