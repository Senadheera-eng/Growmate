// treatment_progress_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TreatmentProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Clear all treatment progress for a specific tree and disease
  Future<int> clearTreatmentProgress({
    required String treeId,
    required String diseaseId,
  }) async {
    try {
      // Query all treatment progress for this tree and disease
      final treatmentProgressQuery = await _firestore
          .collection('treatment_progress')
          .where('treeId', isEqualTo: treeId)
          .where('diseaseId', isEqualTo: diseaseId)
          .get();

      // If no records found, return 0
      if (treatmentProgressQuery.docs.isEmpty) {
        return 0;
      }

      // Create a batch to delete all treatment progress documents
      final batch = _firestore.batch();
      for (var doc in treatmentProgressQuery.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch delete
      await batch.commit();
      
      print('Deleted ${treatmentProgressQuery.docs.length} treatment progress records for tree $treeId');
      return treatmentProgressQuery.docs.length;
    } catch (e) {
      print('Error clearing treatment progress: $e');
      rethrow;
    }
  }

  // Clear all treatment progress for a specific tree (regardless of disease)
  Future<int> clearAllTreatmentProgressForTree(String treeId) async {
    try {
      // Query all treatment progress for this tree
      final treatmentProgressQuery = await _firestore
          .collection('treatment_progress')
          .where('treeId', isEqualTo: treeId)
          .get();

      // If no records found, return 0
      if (treatmentProgressQuery.docs.isEmpty) {
        return 0;
      }

      // Create a batch to delete all treatment progress documents
      final batch = _firestore.batch();
      for (var doc in treatmentProgressQuery.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch delete
      await batch.commit();
      
      print('Deleted ${treatmentProgressQuery.docs.length} treatment progress records for tree $treeId');
      return treatmentProgressQuery.docs.length;
    } catch (e) {
      print('Error clearing all treatment progress: $e');
      rethrow;
    }
  }
}