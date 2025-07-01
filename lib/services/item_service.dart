import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lostandfound/models/item.dart';
import 'dart:io';

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
} 