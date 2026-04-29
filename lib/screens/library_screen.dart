import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/membership_model.dart';
import '../models/book_order_model.dart';
import '../models/user_model.dart';
import '../services/error_handler.dart';

class LibraryScreen extends StatefulWidget {
  final UserModel user;
  const LibraryScreen({super.key, required this.user});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  MembershipModel? _membership;
  bool _isLoadingMembership = true;
  bool _isFeePaid = false;
  bool _isLoadingFee = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _checkFeeStatus();
    _checkMembership();
  }

  Future<void> _checkFeeStatus() async {
    try {
      final querySnapshot = await _firestore
          .collection('fee_payments')
          .where('studentId', isEqualTo: widget.user.uid)
          .where('semester', isEqualTo: widget.user.semester)
          .where('status', isEqualTo: 'Success')
          .get();

      setState(() {
        _isFeePaid = querySnapshot.docs.isNotEmpty;
        _isLoadingFee = false;
      });
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showError(context, e);
      }
      setState(() => _isLoadingFee = false);
    }
  }

  Future<void> _checkMembership() async {
    try {
      final doc = await _firestore.collection('library_memberships').doc(widget.user.uid).get();
      if (doc.exists) {
        setState(() {
          _membership = MembershipModel.fromFirestore(doc.data()!);
          _isLoadingMembership = false;
        });
      } else {
        setState(() {
          _isLoadingMembership = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showError(context, e);
      }
      setState(() => _isLoadingMembership = false);
    }
  }

  Future<void> _requestMembership() async {
    if (!_isFeePaid) {
      AppErrorHandler.showError(context, "You must pay your semester fees first to join the library.");
      return;
    }

    LoadingOverlay.show(context);
    try {
      await _firestore.collection('library_memberships').doc(widget.user.uid).set({
        'userId': widget.user.uid,
        'status': 'Pending',
        'joinDate': FieldValue.serverTimestamp(),
      });
      await _checkMembership();
      if (mounted) {
        AppErrorHandler.showSuccess(context, "Membership request sent!");
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  Future<void> _placeOrder(BookModel book) async {
    if (_membership == null || _membership!.status != 'Active') {
      AppErrorHandler.showError(context, "You need an active membership to order books.");
      return;
    }

    if (book.quantity <= 0) {
      AppErrorHandler.showError(context, "Book is currently out of stock.");
      return;
    }

    LoadingOverlay.show(context);
    try {
      await _firestore.collection('book_orders').add({
        'bookId': book.id,
        'bookTitle': book.title,
        'userId': widget.user.uid,
        'userName': widget.user.fullName,
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      if (mounted) {
        AppErrorHandler.showSuccess(context, "Book order placed successfully!");
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Digital Library", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF1E3A8A), theme.colorScheme.primary],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Icon(
                        Icons.local_library_rounded,
                        size: 140,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingMembership || _isLoadingFee)
                    const LinearProgressIndicator()
                  else if (!_isFeePaid)
                    _buildMembershipBanner(
                      "Semester Fees Unpaid. Pay fees to access Library Membership.", 
                      "Pay Now", 
                      null, // Disable request, could navigate to fee screen
                      isError: true
                    )
                  else if (_membership == null)
                    _buildMembershipBanner("Join Library Membership to borrow books", "Join Now", _requestMembership)
                  else if (_membership!.status == 'Pending')
                    _buildMembershipBanner("Your membership request is pending approval", "Pending", null)
                  else if (_membership!.status == 'Active')
                    _buildMembershipBanner("Active Member", "Membership ID: ${widget.user.uid.substring(0, 6).toUpperCase()}", null, isGreen: true),
                  
                  const SizedBox(height: 20),
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Search books, authors...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Available Books",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('books').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return SliverToBoxAdapter(child: AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {})));
              if (snapshot.connectionState == ConnectionState.waiting) return SliverToBoxAdapter(child: AppErrorHandler.buildLoadingWidget());

              final books = snapshot.data!.docs.map((doc) => BookModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                .where((book) => book.title.toLowerCase().contains(_searchQuery) || book.author.toLowerCase().contains(_searchQuery))
                .toList();

              if (books.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text("No books found matching your search."),
                )));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = books[index];
                      return _BookCard(
                        book: book,
                        onOrder: () => _placeOrder(book),
                        isMember: _membership?.status == 'Active',
                      );
                    },
                    childCount: books.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildMembershipBanner(String text, String btnText, VoidCallback? onTap, {bool isGreen = false, bool isError = false}) {
    Color bgColor = isGreen ? Colors.green : (isError ? Colors.red : Colors.blue);
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: bgColor, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            isGreen ? Icons.verified : (isError ? Icons.error_outline : Icons.info_outline), 
            color: bgColor
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            Text(btnText, style: TextStyle(color: isGreen ? Colors.green : (isError ? Colors.red : Colors.grey), fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onOrder;
  final bool isMember;

  const _BookCard({required this.book, required this.onOrder, required this.isMember});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                    ? Image.network(
                        book.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.book, color: Colors.grey, size: 50),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        width: double.infinity,
                        child: const Icon(Icons.book, color: Colors.grey, size: 50),
                      ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: book.condition == 'New' ? Colors.blue : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      book.condition,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Qty: ${book.quantity}",
                      style: TextStyle(
                        color: book.quantity > 0 ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isMember)
                      InkWell(
                        onTap: book.quantity > 0 ? onOrder : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: book.quantity > 0 ? Colors.blue : Colors.grey,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text("Order", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
