import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lostandfound/models/item.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<Item>> getItems({
    String? category,
    String? searchQuery,
  }) {
    Query query = _firestore.collection('items').orderBy('date', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where('title', isGreaterThanOrEqualTo: searchQuery)
          .where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff');
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
    });
  }

  Future<String> uploadImage(File imageFile) async {
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference ref = _storage.ref().child('item_images/$fileName');
    final UploadTask uploadTask = ref.putFile(imageFile);
    final TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> addItem(Item item, {File? imageFile}) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    final itemWithImage = item.copyWith(imageUrl: imageUrl);
    await _firestore.collection('items').add(itemWithImage.toMap());
  }

  Future<void> updateItem(Item item) async {
    await _firestore.collection('items').doc(item.id).update(item.toMap());
  }

  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }

  Future<void> markAsRecovered(String itemId) async {
    await _firestore.collection('items').doc(itemId).update({
      'isRecovered': true,
    });
  }

  Stream<List<Item>> getUserItems(String userId) {
    return _firestore
        .collection('items')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
    });
  }

  Future<List<Item>> findMatchingItems(Item item) async {
    final querySnapshot = await _firestore
        .collection('items')
        .where('category', isEqualTo: item.category)
        .where('isLost', isEqualTo: !item.isLost)
        .where('isRecovered', isEqualTo: false)
        .get();

    final items = querySnapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();

    // Filter items by location similarity
    return items.where((otherItem) {
      final locationSimilarity = _calculateLocationSimilarity(
        item.location,
        otherItem.location,
      );
      return locationSimilarity > 0.5; // Threshold for location similarity
    }).toList();
  }

  double _calculateLocationSimilarity(String location1, String location2) {
    // Simple location similarity calculation
    // In a real app, you might want to use geocoding and distance calculation
    final words1 = location1.toLowerCase().split(' ');
    final words2 = location2.toLowerCase().split(' ');
    final commonWords = words1.where((word) => words2.contains(word)).length;
    return commonWords / (words1.length + words2.length - commonWords);
  }

  Future<String> uploadClaimProofPhoto(File photoFile) async {
    final String fileName = 'claim_' + DateTime.now().millisecondsSinceEpoch.toString();
    final Reference ref = _storage.ref().child('claim_proof/$fileName');
    final UploadTask uploadTask = ref.putFile(photoFile);
    final TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> submitClaimRequest({
    required String itemId,
    required String claimantUserId,
    String? answer,
    String? photoUrl,
  }) async {
    final claimRequest = ClaimRequest(
      id: const Uuid().v4(),
      itemId: itemId,
      claimantUserId: claimantUserId,
      answer: answer,
      photoUrl: photoUrl,
      timestamp: DateTime.now(),
      status: 'pending',
    );
    await _firestore.collection('claim_requests').doc(claimRequest.id).set(claimRequest.toMap());
  }

  Stream<List<ClaimRequest>> getClaimRequestsForItem(String itemId) {
    return _firestore
        .collection('claim_requests')
        .where('itemId', isEqualTo: itemId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ClaimRequest.fromFirestore(doc)).toList());
  }

  Future<void> updateClaimRequestStatus(String claimRequestId, String status) async {
    await _firestore.collection('claim_requests').doc(claimRequestId).update({'status': status});
    if (status == 'approved') {
      // Get the claim request to find the itemId
      final claimDoc = await _firestore.collection('claim_requests').doc(claimRequestId).get();
      final claimData = claimDoc.data();
      if (claimData != null) {
        final itemId = claimData['itemId'];
        // Mark item as recovered
        await _firestore.collection('items').doc(itemId).update({'isRecovered': true});
        // Reject all other pending claims for this item
        final pendingClaims = await _firestore
            .collection('claim_requests')
            .where('itemId', isEqualTo: itemId)
            .where('status', isEqualTo: 'pending')
            .get();
        for (final doc in pendingClaims.docs) {
          if (doc.id != claimRequestId) {
            await doc.reference.update({'status': 'rejected'});
          }
        }
      }
    }
  }

  Future<bool> hasUserClaimedItem(String itemId, String userId) async {
    final query = await _firestore
        .collection('claim_requests')
        .where('itemId', isEqualTo: itemId)
        .where('claimantUserId', isEqualTo: userId)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Stream of potential matches for a user's items
  Stream<Map<String, List<Item>>> streamPotentialMatchesForUser(String userId) async* {
    await for (final userItems in getUserItems(userId)) {
      final Map<String, List<Item>> matchesMap = {};
      for (final item in userItems) {
        final matches = await findMatchingItems(item);
        matchesMap[item.id] = matches;
      }
      yield matchesMap;
    }
  }

  /// Create a chat document for an item and two users if it doesn't exist
  Future<String> createChatIfNotExists({
    required String itemId,
    required String userA,
    required String userB,
  }) async {
    final chatQuery = await _firestore
        .collection('chats')
        .where('itemId', isEqualTo: itemId)
        .where('participants', arrayContains: userA)
        .get();
    for (final doc in chatQuery.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      if (participants.contains(userB)) {
        return doc.id;
      }
    }
    final chatDoc = await _firestore.collection('chats').add({
      'itemId': itemId,
      'participants': [userA, userB],
      'createdAt': DateTime.now(),
    });
    return chatDoc.id;
  }

  /// Send a message in a chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'timestamp': DateTime.now(),
    });
  }

  /// Stream messages for a chat
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }
} 