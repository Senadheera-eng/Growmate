// edit_tree_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grow_mate_version2/notification_service.dart';
import 'tree_model.dart';
import 'disease_model.dart';

class EditTreePage extends StatefulWidget {
  final TreeModel tree;

  const EditTreePage({Key? key, required this.tree}) : super(key: key);

  @override
  _EditTreePageState createState() => _EditTreePageState();
}

class _EditTreePageState extends State<EditTreePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _diseaseDescController;
  bool _isDiseased = false;
  String? _selectedDiseaseId;
  List<DiseaseModel> _diseases = [];
  bool _isLoading = false;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing tree data
    _nameController = TextEditingController(text: widget.tree.name);
    _ageController =
        TextEditingController(text: widget.tree.ageInMonths.toString());
    _locationController =
        TextEditingController(text: widget.tree.location ?? '');
    _diseaseDescController =
        TextEditingController(text: widget.tree.diseaseDescription ?? '');
    _isDiseased = widget.tree.isDiseased;
    _selectedDiseaseId = widget.tree.diseaseId;
    _selectedLocation = widget.tree.location;
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('diseases').get();

    setState(() {
      _diseases = snapshot.docs
          .map((doc) => DiseaseModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _diseaseDescController.dispose();
    super.dispose();
  }

  /* Future<void> _saveTree() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update tree data
      final updatedTree = {
        'name': _nameController.text,
        'ageInMonths': int.parse(_ageController.text),
        'location': _locationController.text,
        'isDiseased': _isDiseased,
      };

      // Add disease information only if the tree is diseased
      if (_isDiseased) {
        updatedTree['diseaseDescription'] = _diseaseDescController.text;
        updatedTree['diseaseId'] = _selectedDiseaseId as dynamic;
        updatedTree['diseaseIdentifiedDate'] = DateTime.now().toIso8601String();
      } else {
        // Remove disease fields if tree is marked as healthy
        updatedTree['diseaseDescription'] = null as dynamic;
        updatedTree['diseaseId'] = null as dynamic;
        updatedTree['diseaseIdentifiedDate'] = null as dynamic;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('trees')
          .doc(widget.tree.id)
          .update(updatedTree);

      // Get the updated tree data to pass to notifications
      final updatedTreeDoc = await FirebaseFirestore.instance
          .collection('trees')
          .doc(widget.tree.id)
          .get();
      
      final updatedTreeModel = TreeModel.fromMap({
        ...updatedTreeDoc.data()!,
        'id': widget.tree.id
      });

      // Update notifications for the tree
      try {
        final notificationService = NotificationService();
        
        // Schedule appropriate notifications
        await notificationService.scheduleWateringReminder(updatedTreeModel);
        await notificationService.scheduleFertilizationReminder(updatedTreeModel);
        await notificationService.scheduleCareTipReminders(updatedTreeModel);

        // If tree became diseased, schedule treatment notifications
        if (updatedTreeModel.isDiseased && updatedTreeModel.diseaseId != null) {
          await notificationService.scheduleTreatmentReminder(updatedTreeModel);
        }
      } catch (e) {
        print('Error scheduling notifications: $e');
        // Don't show error to user, notifications are a background feature
      }

      if (mounted) {
        Navigator.pop(context, updatedTreeModel);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tree updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
 */
  Future<void> _saveTree() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create base tree update data
      final Map<String, dynamic> updatedTree = <String, dynamic>{};
      updatedTree['name'] = _nameController.text;
      updatedTree['ageInMonths'] = int.parse(_ageController.text);
      updatedTree['location'] = _locationController.text;
      updatedTree['isDiseased'] = _isDiseased;

      // Store the original disease state to check if it changed
      final bool wasDiseasedBefore = widget.tree.isDiseased;
      final String? previousDiseaseId = widget.tree.diseaseId;

      // Add disease information only if the tree is diseased
      if (_isDiseased) {
        updatedTree['diseaseDescription'] = _diseaseDescController.text;
        updatedTree['diseaseId'] = _selectedDiseaseId ?? '';
        updatedTree['diseaseIdentifiedDate'] = DateTime.now().toIso8601String();
      } else {
        // Remove disease fields if tree is marked as healthy
        updatedTree['diseaseDescription'] = FieldValue.delete();
        updatedTree['diseaseId'] = FieldValue.delete();
        updatedTree['diseaseIdentifiedDate'] = FieldValue.delete();
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('trees')
          .doc(widget.tree.id)
          .update(updatedTree);

      // If the tree was previously diseased but is now healthy,
      // delete all treatment progress for this tree to allow starting over later
      if (wasDiseasedBefore && !_isDiseased && previousDiseaseId != null) {
        try {
          print(
              'Tree changed from diseased to healthy. Clearing treatment progress...');
          print(
              'Tree ID: ${widget.tree.id}, Previous Disease ID: $previousDiseaseId');

          // Query all treatment progress for this tree
          final treatmentProgressQuery = await FirebaseFirestore.instance
              .collection('treatment_progress')
              .where('treeId', isEqualTo: widget.tree.id)
              .get();

          print(
              'Found ${treatmentProgressQuery.docs.length} total treatment progress records for this tree');

          // Log all found documents for debugging
          for (var doc in treatmentProgressQuery.docs) {
            final data = doc.data();
            print('Document ID: ${doc.id}');
            print('  Tree ID: ${data['treeId']}');
            print('  Disease ID: ${data['diseaseId']}');
            print('  Step ID: ${data['stepId']}');
            print('  Started Date: ${data['startedDate']}');
            print(
                '  Completed Date: ${data.containsKey('completedDate') ? data['completedDate'] : 'Not completed'}');
          }

          // Create a batch to delete all treatment progress documents
          if (treatmentProgressQuery.docs.isNotEmpty) {
            final batch = FirebaseFirestore.instance.batch();
            for (var doc in treatmentProgressQuery.docs) {
              batch.delete(doc.reference);
              print('Marked document ${doc.id} for deletion');
            }

            // Commit the batch delete
            await batch.commit();
            print(
                'Successfully deleted ${treatmentProgressQuery.docs.length} treatment progress records');
          } else {
            print('No treatment progress records found to delete');
          }

          // Double-check to ensure deletion worked
          final verificationQuery = await FirebaseFirestore.instance
              .collection('treatment_progress')
              .where('treeId', isEqualTo: widget.tree.id)
              .get();

          if (verificationQuery.docs.isEmpty) {
            print(
                'Verification successful: All treatment progress records cleared');
          } else {
            print(
                'WARNING: ${verificationQuery.docs.length} treatment records still exist after deletion attempt');
          }
        } catch (e) {
          print('Error clearing treatment progress: $e');
          // Continue with the save operation even if clearing progress fails
        }
      }

      // Get the updated tree data to pass to notifications
      final updatedTreeDoc = await FirebaseFirestore.instance
          .collection('trees')
          .doc(widget.tree.id)
          .get();

      final updatedTreeModel =
          TreeModel.fromMap({...updatedTreeDoc.data()!, 'id': widget.tree.id});

      // Update notifications for the tree
      try {
        final notificationService = NotificationService();

        // Schedule appropriate notifications
        await notificationService.scheduleWateringReminder(updatedTreeModel);
        await notificationService
            .scheduleFertilizationReminder(updatedTreeModel);
        await notificationService.scheduleCareTipReminders(updatedTreeModel);

        // If tree became diseased, schedule treatment notifications
        if (updatedTreeModel.isDiseased && updatedTreeModel.diseaseId != null) {
          await notificationService.scheduleTreatmentReminder(updatedTreeModel);
        }
      } catch (e) {
        print('Error scheduling notifications: $e');
        // Don't show error to user, notifications are a background feature
      }

      if (mounted) {
        Navigator.pop(context, updatedTreeModel);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tree updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDiseaseSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.healing,
                color: Color(0xFF00C853),
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Tree Health Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const Spacer(),
              Switch(
                value: _isDiseased,
                onChanged: (value) {
                  setState(() {
                    _isDiseased = value;
                    if (!value) {
                      _selectedDiseaseId = null;
                      _diseaseDescController.clear();
                    }
                  });
                },
                activeColor: const Color(0xFF00C853),
              ),
            ],
          ),
          _isDiseased
              ? const Padding(
                  padding: EdgeInsets.only(left: 34),
                  child: Text(
                    'Tree is diseased',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent,
                    ),
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.only(left: 34),
                  child: Text(
                    'Tree is healthy',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ),
          if (_isDiseased) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Disease',
                prefixIcon:
                    const Icon(Icons.bug_report, color: Colors.redAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00C853)),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              value: _selectedDiseaseId,
              items: _diseases.map((disease) {
                return DropdownMenuItem(
                  value: disease.id,
                  child: Text(disease.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDiseaseId = value;
                  if (value != null) {
                    final disease = _diseases.firstWhere((d) => d.id == value);
                    _diseaseDescController.text = disease.description;
                  }
                });
              },
              validator: (value) => _isDiseased && value == null
                  ? 'Please select a disease'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diseaseDescController,
              decoration: InputDecoration(
                labelText: 'Additional Disease Notes',
                prefixIcon: const Icon(Icons.note_add, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00C853)),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              maxLines: 3,
              validator: (value) => _isDiseased && (value?.isEmpty ?? true)
                  ? 'Please add disease notes'
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.info,
                color: Color(0xFF00C853),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Tree Name',
              prefixIcon: const Icon(Icons.label, color: Color(0xFF00C853)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00C853)),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: 'Age (months)',
              prefixIcon:
                  const Icon(Icons.calendar_today, color: Color(0xFF00C853)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00C853)),
              ),
              fillColor: Colors.white,
              filled: true,
              helperText: 'Enter age between 1-6 months',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter age';
              final age = int.tryParse(value!);
              if (age == null) return 'Please enter a valid number';
              if (age < 1 || age > 6)
                return 'Age must be between 1 and 6 months';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              prefixIcon:
                  const Icon(Icons.location_on, color: Color(0xFF00C853)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00C853)),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a location';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Edit Tree',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF00C853),
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildDiseaseSection(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTree,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.save),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00C853),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 22,
            child: Icon(
              Icons.edit,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit ${widget.tree.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Update tree information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
