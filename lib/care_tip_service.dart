// care_tip_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'care_tip_tracking_model.dart';

class CareTipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get care tips for a specific category and tree age
  Stream<List<CareTip>> getCareTipsForTree({
    required String category,
    required int treeAgeInMonths,
  }) {
    return _firestore
        .collection('care_tips')
        .where('category', isEqualTo: category)
        .where('minimumAge', isLessThanOrEqualTo: treeAgeInMonths)
        .where('maximumAge', isGreaterThanOrEqualTo: treeAgeInMonths)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CareTip.fromMap({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  // Get completed tips for a specific tree
  Stream<List<CareTipCompletion>> getCompletedTipsForTree(String treeId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('care_tip_completions')
        .where('userId', isEqualTo: userId)
        .where('treeId', isEqualTo: treeId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CareTipCompletion.fromMap({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  // Mark a tip as complete
  Future<void> markTipAsComplete({
    required String tipId,
    required String treeId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final completion = CareTipCompletion(
      id: const Uuid().v4(),
      tipId: tipId,
      treeId: treeId,
      userId: userId,
      completedDate: DateTime.now(),
    );

    await _firestore
        .collection('care_tip_completions')
        .doc(completion.id)
        .set(completion.toMap());
  }

  // Get all completed tips for a user
  Stream<List<CareTipCompletion>> getAllCompletedTips() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('care_tip_completions')
        .where('userId', isEqualTo: userId)
        .orderBy('completedDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CareTipCompletion.fromMap({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  // Get tips completion statistics for a tree
  Future<Map<String, int>> getTipsCompletionStats(String treeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final completions = await _firestore
        .collection('care_tip_completions')
        .where('userId', isEqualTo: userId)
        .where('treeId', isEqualTo: treeId)
        .get();

    final tips = await _firestore
        .collection('care_tips')
        .get();

    final stats = {
      'total': tips.docs.length,
      'completed': completions.docs.length,
      'remaining': tips.docs.length - completions.docs.length,
    };

    return stats;
  }
}