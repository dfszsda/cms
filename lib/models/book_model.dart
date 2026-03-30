import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final String category;
  final int quantity;
  final String condition; // 'New' or 'Old'
  final String description;
  final String? imageUrl;
  final String? collegeId;
  final DateTime createdAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.quantity,
    required this.condition,
    required this.description,
    this.imageUrl,
    this.collegeId,
    required this.createdAt,
  });

  factory BookModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BookModel(
      id: id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 0,
      condition: data['condition'] ?? 'New',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      collegeId: data['collegeId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'category': category,
      'quantity': quantity,
      'condition': condition,
      'description': description,
      'imageUrl': imageUrl,
      'collegeId': collegeId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
