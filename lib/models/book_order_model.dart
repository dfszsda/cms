import 'package:cloud_firestore/cloud_firestore.dart';

class BookOrderModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String userId;
  final String userName;
  final DateTime orderDate;
  final String status; // 'Pending', 'Issued', 'Returned', 'Rejected'
  final DateTime? returnDate;

  BookOrderModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.userId,
    required this.userName,
    required this.orderDate,
    required this.status,
    this.returnDate,
  });

  factory BookOrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BookOrderModel(
      id: id,
      bookId: data['bookId'] ?? '',
      bookTitle: data['bookTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'Pending',
      returnDate: (data['returnDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'userId': userId,
      'userName': userName,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status,
      'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
    };
  }
}
