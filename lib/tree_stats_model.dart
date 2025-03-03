/* // tree_stats_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'tree_model.dart';

class TreeStats {
  final String treeId;
  final int careTipsCompleted;
  final int totalCareTips;
  final int treatmentStepsCompleted;
  final int totalTreatmentSteps;
  final ScheduledActivity? nextActivity;
  final List<TreeActivity> recentActivities;
  final bool isDiseased;

  TreeStats({
    required this.treeId,
    required this.careTipsCompleted,
    required this.totalCareTips,
    required this.treatmentStepsCompleted,
    required this.totalTreatmentSteps,
    this.nextActivity,
    required this.recentActivities,
    required this.isDiseased,
  });

  double get careTipsProgress => 
      totalCareTips > 0 ? careTipsCompleted / totalCareTips : 0;
      
  double get treatmentProgress => 
      totalTreatmentSteps > 0 ? treatmentStepsCompleted / totalTreatmentSteps : 0;
}

class ScheduledActivity {
  final String title;
  final String description;
  final DateTime scheduledDate;
  final String type; // 'watering', 'treatment', 'checkup'

  ScheduledActivity({
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.type,
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

  Future<TreeStats> getTreeStats(TreeModel tree) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get care tips completed
    final careTipsSnapshot = await _firestore
        .collection('care_tip_completions')
        .where('treeId', isEqualTo: tree.id)
        .where('userId', isEqualTo: userId)
        .get();
    
    final careTipsCompleted = careTipsSnapshot.docs.length;

    // Get total care tips for this tree's age
    final totalTipsSnapshot = await _firestore
        .collection('care_tips')
        .where('minimumAge', isLessThanOrEqualTo: tree.ageInMonths)
        .where('maximumAge', isGreaterThanOrEqualTo: tree.ageInMonths)
        .get();
    
    final totalCareTips = totalTipsSnapshot.docs.length;

    // Treatment steps data (only if tree is diseased)
    int treatmentStepsCompleted = 0;
    int totalTreatmentSteps = 0;

    if (tree.isDiseased && tree.diseaseId != null) {
      // Get completed treatment steps
      final treatmentProgressSnapshot = await _firestore
          .collection('treatment_progress')
          .where('treeId', isEqualTo: tree.id)
          .where('diseaseId', isEqualTo: tree.diseaseId)
          .where('userId', isEqualTo: userId)
          .get();
      
      treatmentStepsCompleted = treatmentProgressSnapshot.docs
          .where((doc) => doc.data().containsKey('completedDate') && doc.data()['completedDate'] != null)
          .length;

      // Get total treatment steps
      final totalTreatmentStepsSnapshot = await _firestore
          .collection('treatment_steps')
          .where('diseaseId', isEqualTo: tree.diseaseId)
          .get();
      
      totalTreatmentSteps = totalTreatmentStepsSnapshot.docs.length;
    }

    // Get next scheduled activity
    final nextActivity = await _getNextScheduledActivity(tree);

    // Get recent activities
    final recentActivities = await _getRecentActivities(tree.id, userId);

    return TreeStats(
      treeId: tree.id,
      careTipsCompleted: careTipsCompleted,
      totalCareTips: totalCareTips,
      treatmentStepsCompleted: treatmentStepsCompleted,
      totalTreatmentSteps: totalTreatmentSteps,
      nextActivity: nextActivity,
      recentActivities: recentActivities,
      isDiseased: tree.isDiseased,
    );
  }
  
  Future<ScheduledActivity?> _getNextScheduledActivity(TreeModel tree) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    
    // Check for in-progress treatment steps if tree is diseased
    if (tree.isDiseased && tree.diseaseId != null) {
      final treatmentProgress = await _firestore
          .collection('treatment_progress')
          .where('treeId', isEqualTo: tree.id)
          .where('diseaseId', isEqualTo: tree.diseaseId)
          .where('userId', isEqualTo: userId)
          .where('completedDate', isNull: true)
          .get();
      
      if (treatmentProgress.docs.isNotEmpty) {
        final progressData = treatmentProgress.docs.first.data();
        final stepId = progressData['stepId'];
        
        final stepDoc = await _firestore
            .collection('treatment_steps')
            .doc(stepId)
            .get();
        
        if (stepDoc.exists) {
          final stepData = stepDoc.data()!;
          final startDate = DateTime.parse(progressData['startedDate']);
          final recommendedDays = stepData['recommendedDays'] ?? 7;
          final targetDate = startDate.add(Duration(days: recommendedDays));
          
          return ScheduledActivity(
            title: 'Complete treatment step ${stepData['stepNumber']}',
            description: stepData['instruction'],
            scheduledDate: targetDate,
            type: 'treatment',
          );
        }
      }
    }
    
    // If no treatment in progress or tree is healthy, suggest next watering based on last watering
    final lastWatering = await _firestore
        .collection('care_tip_completions')
        .where('treeId', isEqualTo: tree.id)
        .where('userId', isEqualTo: userId)
        .orderBy('completedDate', descending: true)
        .limit(1)
        .get();
    
    if (lastWatering.docs.isNotEmpty) {
      final completionData = lastWatering.docs.first.data();
      final tipId = completionData['tipId'];
      
      final tipDoc = await _firestore
          .collection('care_tips')
          .doc(tipId)
          .get();
      
      if (tipDoc.exists && tipDoc.data()?['category'] == 'watering') {
        final lastDate = DateTime.parse(completionData['completedDate']);
        final nextDate = lastDate.add(const Duration(days: 7)); // Assuming weekly watering
        
        return ScheduledActivity(
          title: 'Water your tree',
          description: 'Regular watering is essential for young coconut trees',
          scheduledDate: nextDate,
          type: 'watering',
        );
      }
    }
    
    // Default fallback suggestion
    return ScheduledActivity(
      title: 'Check on your tree',
      description: 'Regular inspection helps catch issues early',
      scheduledDate: DateTime.now().add(const Duration(days: 1)),
      type: 'checkup',
    );
  }
  
  Future<List<TreeActivity>> _getRecentActivities(String treeId, String userId) async {
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
      final date = DateTime.parse(data['completedDate']);
      
      // Get tip details
      final tipDoc = await _firestore.collection('care_tips').doc(data['tipId']).get();
      String tipTitle = 'Care tip';
      String tipDescription = 'Completed care activity';
      
      if (tipDoc.exists) {
        final tipData = tipDoc.data();
        tipTitle = tipData?['title'] ?? 'Care tip';
        tipDescription = tipData?['description'] ?? 'Completed care activity';
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
    
    // Get treatment progress
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
      
      // Get step details
      final stepDoc = await _firestore.collection('treatment_steps').doc(stepId).get();
      String stepTitle = 'Treatment step';
      String stepDescription = 'Treatment activity';
      
      if (stepDoc.exists) {
        final stepData = stepDoc.data();
        stepTitle = 'Treatment Step ${stepData?['stepNumber']}';
        stepDescription = stepData?['instruction'] ?? 'Treatment activity';
      }
      
      // Check if this is a start or complete event
      if (data.containsKey('completedDate') && data['completedDate'] != null) {
        // This is a completion
        final completedDate = DateTime.parse(data['completedDate']);
        final outcomeAchieved = data['outcomeAchieved'] as bool?;
        
        activities.add(TreeActivity(
          id: doc.id,
          treeId: treeId,
          title: 'Completed $stepTitle',
          description: stepDescription,
          date: completedDate,
          type: 'treatment_complete',
          successful: outcomeAchieved,
        ));
      } else {
        // This is a start
        final startedDate = DateTime.parse(data['startedDate']);
        
        activities.add(TreeActivity(
          id: doc.id,
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
    
    // Return the most recent 5
    return activities.take(5).toList();
  }
  
  // Get all events for calendar view
  Future<Map<DateTime, List<TreeActivity>>> getCalendarEvents() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {};
    }
    
    final Map<DateTime, List<TreeActivity>> events = {};
    
    // Get all user's trees
    final treesSnapshot = await _firestore
        .collection('trees')
        .where('userId', isEqualTo: userId)
        .get();
    
    final List<String> treeIds = treesSnapshot.docs.map((doc) => doc.id).toList();
    
    // For each tree, get activities
    for (String treeId in treeIds) {
      // Get care tip completions
      final tipCompletions = await _firestore
          .collection('care_tip_completions')
          .where('treeId', isEqualTo: treeId)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in tipCompletions.docs) {
        final data = doc.data();
        final date = DateTime.parse(data['completedDate']);
        final day = DateTime(date.year, date.month, date.day);
        
        // Get tree details
        final treeDoc = await _firestore.collection('trees').doc(treeId).get();
        String treeName = 'Tree';
        
        if (treeDoc.exists) {
          final treeData = treeDoc.data();
          treeName = treeData?['name'] ?? 'Tree';
        }
        
        // Get tip details
        final tipDoc = await _firestore.collection('care_tips').doc(data['tipId']).get();
        String tipTitle = 'Care tip';
        String tipDescription = 'Completed care activity';
        
        if (tipDoc.exists) {
          final tipData = tipDoc.data();
          tipTitle = tipData?['title'] ?? 'Care tip';
          tipDescription = tipData?['description'] ?? 'Completed care activity';
        }
        
        final activity = TreeActivity(
          id: doc.id,
          treeId: treeId,
          title: '$treeName: $tipTitle',
          description: tipDescription,
          date: date,
          type: 'care_tip',
          successful: true,
        );
        
        if (events[day] == null) {
          events[day] = [];
        }
        
        events[day]!.add(activity);
      }
      
      // Get treatment progress
      final treatmentProgress = await _firestore
          .collection('treatment_progress')
          .where('treeId', isEqualTo: treeId)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in treatmentProgress.docs) {
        final data = doc.data();
        
        // Get tree details
        final treeDoc = await _firestore.collection('trees').doc(treeId).get();
        String treeName = 'Tree';
        
        if (treeDoc.exists) {
          final treeData = treeDoc.data();
          treeName = treeData?['name'] ?? 'Tree';
        }
        
        // Get step details
        final stepId = data['stepId'];
        final stepDoc = await _firestore.collection('treatment_steps').doc(stepId).get();
        String stepTitle = 'Treatment step';
        String stepDescription = 'Treatment activity';
        
        if (stepDoc.exists) {
          final stepData = stepDoc.data();
          stepTitle = 'Treatment Step ${stepData?['stepNumber']}';
          stepDescription = stepData?['instruction'] ?? 'Treatment activity';
        }
        
        // Handle start date
        final startDate = DateTime.parse(data['startedDate']);
        final startDay = DateTime(startDate.year, startDate.month, startDate.day);
        
        final startActivity = TreeActivity(
          id: '${doc.id}_start',
          treeId: treeId,
          title: '$treeName: Started $stepTitle',
          description: stepDescription,
          date: startDate,
          type: 'treatment_start',
          successful: null,
        );
        
        if (events[startDay] == null) {
          events[startDay] = [];
        }
        
        events[startDay]!.add(startActivity);
        
        // Handle completion date if available
        if (data.containsKey('completedDate') && data['completedDate'] != null) {
          final completedDate = DateTime.parse(data['completedDate']);
          final completedDay = DateTime(completedDate.year, completedDate.month, completedDate.day);
          final outcomeAchieved = data['outcomeAchieved'] as bool?;
          
          final completeActivity = TreeActivity(
            id: '${doc.id}_complete',
            treeId: treeId,
            title: '$treeName: Completed $stepTitle',
            description: stepDescription,
            date: completedDate,
            type: 'treatment_complete',
            successful: outcomeAchieved,
          );
          
          if (events[completedDay] == null) {
            events[completedDay] = [];
          }
          
          events[completedDay]!.add(completeActivity);
        }
      }
      
      // Get scheduled activities (future planning)
      await _addScheduledActivities(events, treeId, userId);
    }
    
    return events;
  }
  
  // Helper method to get upcoming scheduled activities for the calendar
  Future<void> _addScheduledActivities(
    Map<DateTime, List<TreeActivity>> events,
    String treeId,
    String userId
  ) async {
    try {
      // Get tree details first
      final treeDoc = await _firestore.collection('trees').doc(treeId).get();
      if (!treeDoc.exists) return;
      
      final treeData = treeDoc.data()!;
      final tree = TreeModel.fromMap({...treeData, 'id': treeId});
      final treeName = tree.name;
      
      // Get next watering date based on last watering
      final lastWatering = await _firestore
          .collection('care_tip_completions')
          .where('treeId', isEqualTo: treeId)
          .where('userId', isEqualTo: userId)
          .orderBy('completedDate', descending: true)
          .limit(1)
          .get();
      
      if (lastWatering.docs.isNotEmpty) {
        final data = lastWatering.docs.first.data();
        final tipId = data['tipId'];
        
        final tipDoc = await _firestore
            .collection('care_tips')
            .doc(tipId)
            .get();
        
        if (tipDoc.exists && tipDoc.data()?['category'] == 'watering') {
          final lastDate = DateTime.parse(data['completedDate']);
          
          // Schedule next watering events for the next 4 weeks
          for (int i = 1; i <= 4; i++) {
            final nextDate = lastDate.add(Duration(days: 7 * i));
            final nextDay = DateTime(nextDate.year, nextDate.month, nextDate.day);
            
            // Only add future dates
            if (nextDay.isAfter(DateTime.now())) {
              final activity = TreeActivity(
                id: 'scheduled_water_${treeId}_$i',
                treeId: treeId,
                title: '$treeName: Scheduled Watering',
                description: 'Regular watering is essential for young coconut trees',
                date: nextDate,
                type: 'scheduled_watering',
                successful: null,
              );
              
              if (events[nextDay] == null) {
                events[nextDay] = [];
              }
              
              events[nextDay]!.add(activity);
            }
          }
        }
      }
      
      // For diseased trees, add treatment schedule
      if (tree.isDiseased && tree.diseaseId != null) {
        final progressSnapshot = await _firestore
            .collection('treatment_progress')
            .where('treeId', isEqualTo: treeId)
            .where('userId', isEqualTo: userId)
            .where('completedDate', isNull: true)
            .limit(1)
            .get();
        
        if (progressSnapshot.docs.isNotEmpty) {
          final progressData = progressSnapshot.docs.first.data();
          final stepId = progressData['stepId'];
          final startDate = DateTime.parse(progressData['startedDate']);
          
          final stepDoc = await _firestore
              .collection('treatment_steps')
              .doc(stepId)
              .get();
          
          if (stepDoc.exists) {
            final stepData = stepDoc.data()!;
            final recommendedDays = stepData['recommendedDays'] ?? 7;
            final targetDate = startDate.add(Duration(days: recommendedDays));
            final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
            
            // Only add if it's in the future
            if (targetDay.isAfter(DateTime.now())) {
              final activity = TreeActivity(
                id: 'scheduled_treatment_${treeId}',
                treeId: treeId,
                title: '$treeName: Complete Treatment Step ${stepData['stepNumber']}',
                description: stepData['instruction'] ?? 'Complete the treatment step',
                date: targetDate,
                type: 'scheduled_treatment',
                successful: null,
              );
              
              if (events[targetDay] == null) {
                events[targetDay] = [];
              }
              
              events[targetDay]!.add(activity);
            }
          }
        }
      }
      
      // Add generic checkup reminders
      final checkupDate = DateTime.now().add(const Duration(days: 14));
      final checkupDay = DateTime(checkupDate.year, checkupDate.month, checkupDate.day);
      
      final activity = TreeActivity(
        id: 'scheduled_checkup_${treeId}',
        treeId: treeId,
        title: '$treeName: Regular Checkup',
        description: 'Check on your tree\'s health and growth progress',
        date: checkupDate,
        type: 'scheduled_checkup',
        successful: null,
      );
      
      if (events[checkupDay] == null) {
        events[checkupDay] = [];
      }
      
      events[checkupDay]!.add(activity);
      
    } catch (e) {
      print('Error adding scheduled activities: $e');
    }
  }
  
  // Get statistics summary for all trees
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
    
    // Get care tips stats
    final careTipsSnapshot = await _firestore
        .collection('care_tip_completions')
        .where('userId', isEqualTo: userId)
        .get();
    
    final totalCareTipsCompleted = careTipsSnapshot.docs.length;
    
    // Get treatment stats
    final treatmentSnapshot = await _firestore
        .collection('treatment_progress')
        .where('userId', isEqualTo: userId)
        .get();
    
    final totalTreatmentsStarted = treatmentSnapshot.docs.length;
    final totalTreatmentsCompleted = treatmentSnapshot.docs
        .where((doc) => doc.data().containsKey('completedDate') && doc.data()['completedDate'] != null)
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
} */
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
