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
  final String? validationQuestion;

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
    this.validationQuestion,
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
      validationQuestion: data['validationQuestion'],
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
      'validationQuestion': validationQuestion,
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
    String? validationQuestion,
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
      validationQuestion: validationQuestion ?? this.validationQuestion,
    );
  }
}

class ClaimRequest {
  final String id;
  final String itemId;
  final String claimantUserId;
  final String? answer;
  final String? photoUrl;
  final DateTime timestamp;
  final String status; // pending, approved, rejected

  ClaimRequest({
    required this.id,
    required this.itemId,
    required this.claimantUserId,
    this.answer,
    this.photoUrl,
    required this.timestamp,
    this.status = 'pending',
  });

  factory ClaimRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClaimRequest(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      claimantUserId: data['claimantUserId'] ?? '',
      answer: data['answer'],
      photoUrl: data['photoUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'claimantUserId': claimantUserId,
      'answer': answer,
      'photoUrl': photoUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}

// Stub for potential match (to be filled in by backend logic)
class PotentialMatch {
  final String id;
  final String itemId;
  final String matchedItemId;
  final double similarityScore;
  final String? reason;

  PotentialMatch({
    required this.id,
    required this.itemId,
    required this.matchedItemId,
    required this.similarityScore,
    this.reason,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
} 