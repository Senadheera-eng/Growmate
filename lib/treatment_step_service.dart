// treatment_step_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'treatment_step_model.dart';

class TreatmentStepService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get treatment steps for a disease
  Stream<List<TreatmentStep>> getTreatmentSteps(String diseaseId) {
    print('Fetching steps for disease: $diseaseId'); // Debug log
    
    return _firestore
        .collection('treatment_steps')
        .where('diseaseId', isEqualTo: diseaseId)
        .snapshots()
        .map((snapshot) {
          final steps = snapshot.docs
              .map((doc) {
                print('Found step: ${doc.id}'); // Debug log
                return TreatmentStep.fromMap({...doc.data(), 'id': doc.id});
              })
              .toList();

          // Sort steps in memory instead of in query
          steps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

          print('Total steps found: ${steps.length}'); // Debug log
          return steps;
        });
  }

  // Get current step progress
  Stream<TreatmentStepProgress?> getCurrentStepProgress(String treeId, String diseaseId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(null);

    print('Getting current progress for tree: $treeId, disease: $diseaseId'); // Debug log

    return _firestore
        .collection('treatment_progress')
        .where('treeId', isEqualTo: treeId)
        .where('diseaseId', isEqualTo: diseaseId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final inProgressDocs = snapshot.docs
              .where((doc) => doc.data()['completedDate'] == null)
              .toList();
          
          if (inProgressDocs.isEmpty) {
            print('No in-progress steps found'); // Debug log
            return null;
          }
          
          final progress = TreatmentStepProgress.fromMap(
              {...inProgressDocs.first.data(), 'id': inProgressDocs.first.id});
          print('Current step in progress: ${progress.stepId}'); // Debug log
          return progress;
        });
  }

  // Get all completed steps
  Stream<List<TreatmentStepProgress>> getCompletedSteps(String treeId, String diseaseId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    print('Getting completed steps for tree: $treeId, disease: $diseaseId'); // Debug log

    return _firestore
        .collection('treatment_progress')
        .where('treeId', isEqualTo: treeId)
        .where('diseaseId', isEqualTo: diseaseId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final completedSteps = snapshot.docs
              .where((doc) => doc.data()['completedDate'] != null)
              .map((doc) => TreatmentStepProgress.fromMap({...doc.data(), 'id': doc.id}))
              .toList();

          print('Found ${completedSteps.length} completed steps'); // Debug log
          return completedSteps;
        });
  }

  // Start a treatment step
  Future<void> startTreatmentStep({
    required String treeId,
    required String diseaseId,
    required String stepId,
  }) async {
    try {
      print('Starting step $stepId for tree $treeId'); // Debug log
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check for existing incomplete steps
      final existingSteps = await _firestore
          .collection('treatment_progress')
          .where('treeId', isEqualTo: treeId)
          .where('diseaseId', isEqualTo: diseaseId)
          .where('userId', isEqualTo: userId)
          .get();

      final hasIncompleteStep = existingSteps.docs
          .any((doc) => doc.data()['completedDate'] == null);

      if (hasIncompleteStep) {
        throw Exception('Please complete the current step first');
      }

      // Create new progress entry
      final progress = TreatmentStepProgress(
        id: const Uuid().v4(),
        treeId: treeId,
        diseaseId: diseaseId,
        stepId: stepId,
        userId: userId,
        startedDate: DateTime.now(),
      );

      await _firestore
          .collection('treatment_progress')
          .doc(progress.id)
          .set(progress.toMap());

      print('Successfully started step $stepId'); // Debug log
    } catch (e) {
      print('Error starting step: $e'); // Debug log
      throw Exception('Failed to start treatment step: ${e.toString()}');
    }
  }

  // Complete a step
  Future<void> completeStep({
    required String progressId,
    required bool outcomeAchieved,
    String? notes,
  }) async {
    try {
      print('Completing step $progressId with outcome: $outcomeAchieved'); // Debug log
      
      await _firestore.collection('treatment_progress').doc(progressId).update({
        'completedDate': DateTime.now().toIso8601String(),
        'outcomeAchieved': outcomeAchieved,
        'notes': notes,
      });

      print('Successfully completed step $progressId'); // Debug log
    } catch (e) {
      print('Error completing step: $e'); // Debug log
      throw Exception('Failed to complete treatment step: ${e.toString()}');
    }
  }

  // Verify treatment steps exist
  Future<bool> verifyTreatmentStepsExist(String diseaseId) async {
    try {
      final snapshot = await _firestore
          .collection('treatment_steps')
          .where('diseaseId', isEqualTo: diseaseId)
          .get();

      print('Verified ${snapshot.docs.length} steps exist for disease $diseaseId'); // Debug log
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error verifying treatment steps: $e'); // Debug log
      return false;
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> markTreeAsHealthy(String treeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection('trees').doc(treeId).update({
        'isDiseased': false,
        'diseaseId': null,
        'diseaseDescription': null,
      });

      print('Tree marked as healthy');
    } catch (e) {
      print('Error marking tree as healthy: $e');
      throw Exception('Failed to mark tree as healthy: ${e.toString()}');
    }
  }

  Future<bool> verifyAllStepsCompleted(String treeId, String diseaseId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final progressSnapshot = await _firestore
          .collection('treatment_progress')
          .where('treeId', isEqualTo: treeId)
          .where('diseaseId', isEqualTo: diseaseId)
          .where('userId', isEqualTo: userId)
          .get();

      final allSteps = progressSnapshot.docs.every((doc) => doc.data()['completedDate'] != null);
      return allSteps;
    } catch (e) {
      print('Error verifying steps: $e');
      throw Exception('Failed to verify steps: ${e.toString()}');
    }
  }

}