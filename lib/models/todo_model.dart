import 'package:cloud_firestore/cloud_firestore.dart';

class TodoTask {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime deadline;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isDone;

  TodoTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.createdAt,
    this.completedAt,
    this.isDone = false,
  });

  factory TodoTask.fromMap(Map<String, dynamic> data, String id) {
    return TodoTask(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      isDone: data['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isDone': isDone,
    };
  }

  String get timeTaken {
    if (completedAt == null) return "Not completed";
    final duration = completedAt!.difference(createdAt);
    if (duration.inDays > 0) return "${duration.inDays} days ${duration.inHours % 24} hrs";
    if (duration.inHours > 0) return "${duration.inHours} hrs ${duration.inMinutes % 60} mins";
    return "${duration.inMinutes} mins";
  }
}

class GroupProject {
  final String id;
  final String name;
  final String leaderId;
  final List<String> memberIds;
  final DateTime createdAt;

  GroupProject({
    required this.id,
    required this.name,
    required this.leaderId,
    required this.memberIds,
    required this.createdAt,
  });

  factory GroupProject.fromMap(Map<String, dynamic> data, String id) {
    return GroupProject(
      id: id,
      name: data['name'] ?? '',
      leaderId: data['leaderId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class GroupTask {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String assignedTo;
  final String assignedToName;
  final DateTime deadline;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isDone;

  GroupTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedToName,
    required this.deadline,
    required this.createdAt,
    this.completedAt,
    this.isDone = false,
  });

  factory GroupTask.fromMap(Map<String, dynamic> data, String id) {
    return GroupTask(
      id: id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      isDone: data['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isDone': isDone,
    };
  }
}
