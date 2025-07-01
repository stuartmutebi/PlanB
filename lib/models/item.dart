import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String? imageUrl;
  final DateTime date;
  final String userId;
  final bool isLost;
  final bool isRecovered;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.imageUrl,
    required this.date,
    required this.userId,
    required this.isLost,
    this.isRecovered = false,
  });

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      isLost: data['isLost'] ?? true,
      isRecovered: data['isRecovered'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'isLost': isLost,
      'isRecovered': isRecovered,
    };
  }

  Item copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? imageUrl,
    DateTime? date,
    String? userId,
    bool? isLost,
    bool? isRecovered,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      isLost: isLost ?? this.isLost,
      isRecovered: isRecovered ?? this.isRecovered,
    );
  }
} 