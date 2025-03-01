// treatment_step_model.dart

class TreatmentStep {
  final String id;
  final String diseaseId;
  final int stepNumber;
  final String instruction;
  final String expectedOutcome;
  final List<String> alternativeTips;
  final int recommendedDays;
  final String? nextStepId;

  TreatmentStep({
    required this.id,
    required this.diseaseId,
    required this.stepNumber,
    required this.instruction,
    required this.expectedOutcome,
    required this.alternativeTips,
    required this.recommendedDays,
    this.nextStepId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diseaseId': diseaseId,
      'stepNumber': stepNumber,
      'instruction': instruction,
      'expectedOutcome': expectedOutcome,
      'alternativeTips': alternativeTips,
      'recommendedDays': recommendedDays,
      'nextStepId': nextStepId,
    };
  }

  factory TreatmentStep.fromMap(Map<String, dynamic> map) {
    return TreatmentStep(
      id: map['id'] ?? '',
      diseaseId: map['diseaseId'] ?? '',
      stepNumber: map['stepNumber']?.toInt() ?? 0,
      instruction: map['instruction'] ?? '',
      expectedOutcome: map['expectedOutcome'] ?? '',
      alternativeTips: List<String>.from(map['alternativeTips'] ?? []),
      recommendedDays: map['recommendedDays']?.toInt() ?? 7,
      nextStepId: map['nextStepId'],
    );
  }
}

class TreatmentStepProgress {
  final String id;
  final String treeId;
  final String diseaseId;
  final String stepId;
  final String userId;
  final DateTime startedDate;
  final DateTime? completedDate;
  final bool? outcomeAchieved;
  final String? notes;

  TreatmentStepProgress({
    required this.id,
    required this.treeId,
    required this.diseaseId,
    required this.stepId,
    required this.userId,
    required this.startedDate,
    this.completedDate,
    this.outcomeAchieved,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'treeId': treeId,
      'diseaseId': diseaseId,
      'stepId': stepId,
      'userId': userId,
      'startedDate': startedDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'outcomeAchieved': outcomeAchieved,
      'notes': notes,
    };
  }

  factory TreatmentStepProgress.fromMap(Map<String, dynamic> map) {
    return TreatmentStepProgress(
      id: map['id'] ?? '',
      treeId: map['treeId'] ?? '',
      diseaseId: map['diseaseId'] ?? '',
      stepId: map['stepId'] ?? '',
      userId: map['userId'] ?? '',
      startedDate: DateTime.parse(map['startedDate']),
      completedDate: map['completedDate'] != null 
          ? DateTime.parse(map['completedDate']) 
          : null,
      outcomeAchieved: map['outcomeAchieved'],
      notes: map['notes'],
    );
  }
}