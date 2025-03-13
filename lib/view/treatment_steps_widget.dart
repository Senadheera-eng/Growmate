// treatment_steps_widget.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grow_mate_version2/controller/notification_service.dart';
import 'package:grow_mate_version2/model/tree_model.dart';
import '../model/treatment_step_model.dart';
import '../controller/treatment_step_service.dart';

class TreatmentStepsWidget extends StatelessWidget {
  final String treeId;
  final String diseaseId;
  final TreatmentStepService _stepService = TreatmentStepService();

  TreatmentStepsWidget({
    Key? key,
    required this.treeId,
    required this.diseaseId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TreatmentStep>>(
      stream: _stepService.getTreatmentSteps(diseaseId),
      builder: (context, stepsSnapshot) {
        if (!stepsSnapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
            color: Color(0xFF00C853),
            strokeWidth: 3,
          ));
        }

        final steps = stepsSnapshot.data!;
        if (steps.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'No treatment steps found for this disease',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        return StreamBuilder<TreatmentStepProgress?>(
          stream: _stepService.getCurrentStepProgress(treeId, diseaseId),
          builder: (context, progressSnapshot) {
            return StreamBuilder<List<TreatmentStepProgress>>(
              stream: _stepService.getCompletedSteps(treeId, diseaseId),
              builder: (context, completedSnapshot) {
                final currentProgress = progressSnapshot.data;
                final completedSteps = completedSnapshot.data ?? [];

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    final isCompleted = completedSteps
                        .any((progress) => progress.stepId == step.id);
                    final isCurrent = currentProgress?.stepId == step.id;
                    final canStart = index == 0 ||
                        (completedSteps.any((progress) =>
                            progress.stepId == steps[index - 1].id &&
                            progress.outcomeAchieved == true));

                    return _buildStepCard(
                      context,
                      step,
                      isCompleted,
                      isCurrent,
                      canStart,
                      currentProgress,
                      completedSteps,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    TreatmentStep step,
    bool isCompleted,
    bool isCurrent,
    bool canStart,
    TreatmentStepProgress? currentProgress,
    List<TreatmentStepProgress> completedSteps,
  ) {
    final completedStep =
        completedSteps.firstWhere((progress) => progress.stepId == step.id,
            orElse: () => TreatmentStepProgress(
                  id: '',
                  treeId: '',
                  diseaseId: '',
                  stepId: '',
                  userId: '',
                  startedDate: DateTime.now(),
                ));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFF1B5E20),
              ),
        ),
        child: ExpansionTile(
          initiallyExpanded: isCurrent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: EdgeInsets.zero,
          title: Row(
            children: [
              _buildStepAvatar(step, isCompleted, isCurrent, canStart),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${step.stepNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    if (isCompleted && completedStep.outcomeAchieved != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: completedStep.outcomeAchieved == true
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          completedStep.outcomeAchieved == true
                              ? 'Completed successfully'
                              : 'Needs attention',
                          style: TextStyle(
                            color: completedStep.outcomeAchieved == true
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFEF6C00),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFE0F2F1),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      step.instruction,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Expected Outcome Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF2E7D32),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Expected Outcome:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.expectedOutcome,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Waiting Period
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFB2DFDB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Color(0xFF00897B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Wait ${step.recommendedDays} days',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF00897B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  if (!isCompleted && !isCurrent && canStart)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _startStep(context, step),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          shadowColor: const Color(0xFF00C853).withOpacity(0.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded),
                            SizedBox(width: 8),
                            Text(
                              'START THIS STEP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (isCurrent)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFBBDEFB),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF1976D2),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Started on: ${_formatDate(currentProgress!.startedDate)}',
                                style: const TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => _completeStep(
                                      context, currentProgress, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C853),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_outline),
                                        SizedBox(width: 4),
                                        Text(
                                          'SUCCESS',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => _completeStep(
                                      context, currentProgress, false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF6C00),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.help_outline),
                                        SizedBox(width: 4),
                                        Text(
                                          'NEED HELP',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else if (isCompleted &&
                      completedStep.outcomeAchieved == false)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.tips_and_updates_outlined,
                                    color: Color(0xFFEF6C00),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Alternative Tips:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF6C00),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...step.alternativeTips.map((tip) => Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, top: 6, bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '•',
                                          style: TextStyle(
                                            color: Color(0xFFEF6C00),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            tip,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.4,
                                              color: Color(0xFF424242),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _retryStep(context, step),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded),
                                  SizedBox(width: 4),
                                  Text(
                                    'TRY AGAIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepAvatar(
    TreatmentStep step,
    bool isCompleted,
    bool isCurrent,
    bool canStart,
  ) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData? icon;

    if (isCompleted) {
      backgroundColor = const Color(0xFF4CAF50);
      icon = Icons.check_rounded;
    } else if (isCurrent) {
      backgroundColor = const Color(0xFF2196F3);
      icon = Icons.hourglass_top_rounded;
    } else if (canStart) {
      backgroundColor = const Color(0xFFFF9800);
      icon = null;
    } else {
      backgroundColor = const Color(0xFFBDBDBD);
      textColor = const Color(0xFF757575);
      icon = null;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: icon != null
            ? Icon(
                icon,
                color: textColor,
                size: 22,
              )
            : Text(
                step.stepNumber.toString(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Color _getStepColor(bool isCompleted, bool isCurrent, bool canStart) {
    if (isCompleted) return const Color(0xFF4CAF50);
    if (isCurrent) return const Color(0xFF2196F3);
    if (canStart) return const Color(0xFFFF9800);
    return const Color(0xFFBDBDBD);
  }

  Future<void> _startStep(BuildContext context, TreatmentStep step) async {
    try {
      await _stepService.startTreatmentStep(
        treeId: treeId,
        diseaseId: diseaseId,
        stepId: step.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treatment step started'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting step: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // In TreatmentStepsWidget class
  Future<void> _completeStep(
    BuildContext context,
    TreatmentStepProgress progress,
    bool outcomeAchieved,
  ) async {
    try {
      // Complete the current step
      await _stepService.completeStep(
        progressId: progress.id,
        outcomeAchieved: outcomeAchieved,
      );

      // Add this notification refresh code
      try {
        // Get the current tree data
        final treeDoc = await FirebaseFirestore.instance
            .collection('trees')
            .doc(progress.treeId)
            .get();

        if (treeDoc.exists) {
          final tree =
              TreeModel.fromMap({...treeDoc.data()!, 'id': treeDoc.id});

          // Refresh treatment notifications
          await NotificationService().scheduleTreatmentReminder(tree);
        }
      } catch (e) {
        print('Error refreshing treatment notifications: $e');
      }

      // Only check for all steps completion if this step was successful
      if (outcomeAchieved) {
        final allStepsCompleted = await _stepService.verifyAllStepsCompleted(
          progress.treeId,
          progress.diseaseId,
        );

        if (allStepsCompleted) {
          // All steps are completed successfully, mark tree as healthy
          await _stepService.markTreeAsHealthy(progress.treeId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'All treatment steps completed successfully! Tree is now healthy.'),
              backgroundColor: Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
        } else {
          // Not all steps are completed yet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Step completed successfully. Continue with remaining steps.'),
              backgroundColor: Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
        }
      } else {
        // Step was not successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Step completed. Check alternative tips and try again.'),
            backgroundColor: Color(0xFFFF9800),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing step: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _retryStep(BuildContext context, TreatmentStep step) async {
    try {
      await _startStep(context, step);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error retrying step: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
