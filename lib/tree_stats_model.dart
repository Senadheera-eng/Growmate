// tree_stats_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tree_model.dart';

class TreeStats {
  final String treeId;
  final int careTipsCompleted;
  final int treatmentStepsCompleted;
  final int treatmentStepsInProgress;
  final List<TreeActivity> recentActivities;
  final bool isDiseased;

  TreeStats({
    required this.treeId,
    required this.careTipsCompleted,
    required this.treatmentStepsCompleted,
    required this.treatmentStepsInProgress,
    required this.recentActivities,
    required this.isDiseased,
  });
}

class TreeActivity {
  final String id;
  final String treeId;
  final String title;
  final String description;
  final DateTime date;
  final String type; // 'care_tip', 'treatment_start', 'treatment_complete'
  final bool? successful;

  TreeActivity({
    required this.id,
    required this.treeId,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.successful,
  });
}

class TreeStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get simple tree stats that doesn't require complex queries
  Future<TreeStats> getTreeStats(TreeModel tree) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get care tips completed (directly query completions without filtering by age)
    final careTipsSnapshot = await _firestore
        .collection('care_tip_completions')
        .where('treeId', isEqualTo: tree.id)
        .where('userId', isEqualTo: userId)
        .get();

    final careTipsCompleted = careTipsSnapshot.docs.length;

    // Treatment steps data (only if tree is diseased)
    int treatmentStepsCompleted = 0;
    int treatmentStepsInProgress = 0;

    if (tree.isDiseased && tree.diseaseId != null) {
      // Get treatment progress
      final treatmentProgressSnapshot = await _firestore
          .collection('treatment_progress')
          .where('treeId', isEqualTo: tree.id)
          .where('diseaseId', isEqualTo: tree.diseaseId)
          .where('userId', isEqualTo: userId)
          .get();

      treatmentStepsCompleted = treatmentProgressSnapshot.docs
          .where((doc) =>
              doc.data().containsKey('completedDate') &&
              doc.data()['completedDate'] != null)
          .length;

      treatmentStepsInProgress = treatmentProgressSnapshot.docs
          .where((doc) =>
              !doc.data().containsKey('completedDate') ||
              doc.data()['completedDate'] == null)
          .length;
    }

    // Get recent activities
    final recentActivities = await _getRecentActivities(tree.id, userId);

    return TreeStats(
      treeId: tree.id,
      careTipsCompleted: careTipsCompleted,
      treatmentStepsCompleted: treatmentStepsCompleted,
      treatmentStepsInProgress: treatmentStepsInProgress,
      recentActivities: recentActivities,
      isDiseased: tree.isDiseased,
    );
  }

  // Get recent activities by directly querying completions
  Future<List<TreeActivity>> _getRecentActivities(
      String treeId, String userId) async {
    final List<TreeActivity> activities = [];

    // Get care tip completions
    final tipCompletions = await _firestore
        .collection('care_tip_completions')
        .where('treeId', isEqualTo: treeId)
        .where('userId', isEqualTo: userId)
        .orderBy('completedDate', descending: true)
        .limit(5)
        .get();

    for (var doc in tipCompletions.docs) {
      final data = doc.data();
      if (!data.containsKey('completedDate')) continue;

      final date = DateTime.parse(data['completedDate']);
      final tipId = data['tipId'];

      // Try to get tip details, but don't fail if we can't
      String tipTitle = 'Care tip completed';
      String tipDescription = 'Care activity was completed';

      try {
        final tipDoc =
            await _firestore.collection('care_tips').doc(tipId).get();
        if (tipDoc.exists) {
          final tipData = tipDoc.data();
          tipTitle = tipData?['title'] ?? 'Care tip completed';
          tipDescription =
              tipData?['description'] ?? 'Care activity was completed';
        }
      } catch (e) {
        // Ignore errors fetching tip details
      }

      activities.add(TreeActivity(
        id: doc.id,
        treeId: treeId,
        title: tipTitle,
        description: tipDescription,
        date: date,
        type: 'care_tip',
        successful: true,
      ));
    }

    // Get treatment completions
    final treatmentProgress = await _firestore
        .collection('treatment_progress')
        .where('treeId', isEqualTo: treeId)
        .where('userId', isEqualTo: userId)
        .orderBy('startedDate', descending: true)
        .limit(5)
        .get();

    for (var doc in treatmentProgress.docs) {
      final data = doc.data();
      final stepId = data['stepId'];

      // Try to get step details
      String stepTitle = 'Treatment step';
      String stepDescription = 'Treatment activity';

      try {
        final stepDoc =
            await _firestore.collection('treatment_steps').doc(stepId).get();
        if (stepDoc.exists) {
          final stepData = stepDoc.data();
          stepTitle = 'Treatment Step ${stepData?['stepNumber'] ?? ''}';
          stepDescription = stepData?['instruction'] ?? 'Treatment activity';
        }
      } catch (e) {
        // Ignore errors fetching step details
      }

      // Check if this is a completed step
      if (data.containsKey('completedDate') && data['completedDate'] != null) {
        final completedDate = DateTime.parse(data['completedDate']);
        final outcomeAchieved = data['outcomeAchieved'] as bool? ?? false;

        activities.add(TreeActivity(
          id: '${doc.id}_complete',
          treeId: treeId,
          title: outcomeAchieved
              ? 'Completed $stepTitle successfully'
              : 'Completed $stepTitle (needs attention)',
          description: stepDescription,
          date: completedDate,
          type: 'treatment_complete',
          successful: outcomeAchieved,
        ));
      } else {
        // This is a step in progress
        final startedDate = DateTime.parse(data['startedDate']);

        activities.add(TreeActivity(
          id: '${doc.id}_start',
          treeId: treeId,
          title: 'Started $stepTitle',
          description: stepDescription,
          date: startedDate,
          type: 'treatment_start',
          successful: null,
        ));
      }
    }

    // Sort all activities by date
    activities.sort((a, b) => b.date.compareTo(a.date));

    // Return the most recent activities
    return activities.take(5).toList();
  }

  // Get stats summary without requiring complex queries
  Future<Map<String, dynamic>> getStatsSummary() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get all trees
    final treesSnapshot = await _firestore
        .collection('trees')
        .where('userId', isEqualTo: userId)
        .get();

    final totalTrees = treesSnapshot.docs.length;
    final healthyTrees = treesSnapshot.docs
        .where((doc) => !(doc.data()['isDiseased'] ?? false))
        .length;
    final diseasedTrees = totalTrees - healthyTrees;

    // Get all care tips completions
    final careTipsSnapshot = await _firestore
        .collection('care_tip_completions')
        .where('userId', isEqualTo: userId)
        .get();

    final totalCareTipsCompleted = careTipsSnapshot.docs.length;

    // Get all treatment progress info
    final treatmentSnapshot = await _firestore
        .collection('treatment_progress')
        .where('userId', isEqualTo: userId)
        .get();

    final totalTreatmentsStarted = treatmentSnapshot.docs.length;
    final totalTreatmentsCompleted = treatmentSnapshot.docs
        .where((doc) =>
            doc.data().containsKey('completedDate') &&
            doc.data()['completedDate'] != null)
        .length;

    return {
      'totalTrees': totalTrees,
      'healthyTrees': healthyTrees,
      'diseasedTrees': diseasedTrees,
      'careTipsCompleted': totalCareTipsCompleted,
      'treatmentsStarted': totalTreatmentsStarted,
      'treatmentsCompleted': totalTreatmentsCompleted,
      'treatmentsInProgress': totalTreatmentsStarted - totalTreatmentsCompleted,
    };
  }
}
