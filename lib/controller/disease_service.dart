// disease_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/disease_model.dart';

class DiseaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search diseases
  Future<List<DiseaseModel>> searchDiseases(String query) async {
    query = query.toLowerCase();
    
    // Search in names
    final nameResults = await _firestore
        .collection('diseases')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    // Search in symptoms
    final symptomResults = await _firestore
        .collection('diseases')
        .where('symptoms', arrayContains: query)
        .get();

    // Combine and deduplicate results
    final Set<String> addedIds = {};
    final List<DiseaseModel> diseases = [];

    for (var doc in [...nameResults.docs, ...symptomResults.docs]) {
      if (!addedIds.contains(doc.id)) {
        addedIds.add(doc.id);
        diseases.add(DiseaseModel.fromMap({...doc.data(), 'id': doc.id}));
      }
    }

    return diseases;
  }

  // Get disease by ID
  Future<DiseaseModel?> getDiseaseById(String diseaseId) async {
    final doc = await _firestore.collection('diseases').doc(diseaseId).get();
    if (!doc.exists) return null;
    return DiseaseModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  // Get diseases for tree age range
  Stream<List<DiseaseModel>> getDiseasesByAge(int treeAge) {
    return _firestore
        .collection('diseases')
        .where('minimumAge', isLessThanOrEqualTo: treeAge)
        .where('maximumAge', isGreaterThanOrEqualTo: treeAge)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiseaseModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get completed treatments for a tree
  Stream<List<DocumentSnapshot>> getCompletedTreatments(String treeId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('care_tip_completions')
        .where('treeId', isEqualTo: treeId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Mark treatment as completed
  Future<void> markTreatmentComplete({
    required String treeId,
    required String diseaseId,
    required String treatmentId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('care_tip_completions').add({
      'treeId': treeId,
      'diseaseId': diseaseId,
      'treatmentId': treatmentId,
      'userId': userId,
      'completedDate': DateTime.now().toIso8601String(),
    });
  }
}