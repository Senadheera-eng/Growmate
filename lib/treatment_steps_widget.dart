// treatment_steps_widget.dart
import 'package:flutter/material.dart';
import 'treatment_step_model.dart';
import 'treatment_step_service.dart';

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
          return const Center(child: CircularProgressIndicator());
        }

        final steps = stepsSnapshot.data!;
        if (steps.isEmpty) {
          return const Center(
            child: Text('No treatment steps found for this disease'),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isCurrent,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    _getStepColor(isCompleted, isCurrent, canStart),
                child: Text(
                  step.stepNumber.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${step.stepNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCompleted && completedStep.outcomeAchieved != null)
                      Text(
                        completedStep.outcomeAchieved == true
                            ? 'Completed successfully'
                            : 'Needs attention',
                        style: TextStyle(
                          color: completedStep.outcomeAchieved == true
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.instruction,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Expected Outcome:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(step.expectedOutcome),
                  const SizedBox(height: 16),
                  Text(
                    'Recommended waiting period: ${step.recommendedDays} days',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isCompleted && !isCurrent && canStart)
                    ElevatedButton(
                      onPressed: () => _startStep(context, step),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Start This Step'),
                    )
                  else if (isCurrent)
                    Column(
                      children: [
                        Text(
                          'Started on: ${_formatDate(currentProgress!.startedDate)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _completeStep(
                                    context, currentProgress, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Outcome Achieved'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _completeStep(
                                    context, currentProgress, false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child: const Text('Need Help'),
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
                        const Text(
                          'Alternative Tips:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...step.alternativeTips.map((tip) => Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, top: 4, bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(child: Text(tip)),
                                ],
                              ),
                            )),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => _retryStep(context, step),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text('Try Again'),
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

  Color _getStepColor(bool isCompleted, bool isCurrent, bool canStart) {
    if (isCompleted) return Colors.green;
    if (isCurrent) return Colors.blue;
    if (canStart) return Colors.orange;
    return Colors.grey;
  }

  Future<void> _startStep(BuildContext context, TreatmentStep step) async {
    try {
      await _stepService.startTreatmentStep(
        treeId: treeId,
        diseaseId: diseaseId,
        stepId: step.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treatment step started')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting step: $e')),
      );
    }
  }

  /* Future<void> _completeStep(
    BuildContext context,
    TreatmentStepProgress progress,
    bool outcomeAchieved,
  ) async {
    try {
      await _stepService.completeStep(
        progressId: progress.id,
        outcomeAchieved: outcomeAchieved,
      );

      final allStepsCompleted = await _stepService.verifyAllStepsCompleted(
        progress.treeId,
        progress.diseaseId,
      );

      if (allStepsCompleted) {
        await _stepService.markTreeAsHealthy(progress.treeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All treatment steps completed. Tree is now healthy!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              outcomeAchieved
                  ? 'Step completed successfully'
                  : 'Step completed. Check alternative tips',
            ),
            backgroundColor: outcomeAchieved ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing step: $e')),
      );
    }
  } */
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
            content: Text('All treatment steps completed successfully! Tree is now healthy.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Not all steps are completed yet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Step completed successfully. Continue with remaining steps.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Step was not successful
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Step completed. Check alternative tips and try again.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error completing step: $e')),
    );
  }
}

  Future<void> _retryStep(BuildContext context, TreatmentStep step) async {
    try {
      await _startStep(context, step);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error retrying step: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
