// tips_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tree_model.dart';
import 'care_tip_tracking_model.dart';
import 'package:uuid/uuid.dart';

class TipsSection extends StatefulWidget {
  @override
  _TipsSectionState createState() => _TipsSectionState();
}

class _TipsSectionState extends State<TipsSection> {
  String? selectedTreeId;
  String selectedCategory = '';
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Care Tips',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tree Selection Dropdown
          if (selectedCategory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trees')
                    .where('userId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  List<TreeModel> trees = snapshot.data!.docs
                      .map((doc) => TreeModel.fromMap(
                          {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
                      .toList();

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Tree',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTreeId,
                    items: trees.map((tree) {
                      return DropdownMenuItem(
                        value: tree.id,
                        child: Text('${tree.name} (${tree.ageInMonths} months)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTreeId = value;
                      });
                    },
                  );
                },
              ),
            ),

          // Categories Grid
          if (selectedCategory.isEmpty)
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCategoryCard(
                    icon: Icons.opacity,
                    title: 'Watering Tips',
                    category: 'watering',
                    color: Colors.blue,
                  ),
                  _buildCategoryCard(
                    icon: Icons.bug_report,
                    title: 'Pest Control',
                    category: 'pest',
                    color: Colors.red,
                  ),
                  _buildCategoryCard(
                    icon: Icons.eco,
                    title: 'Fertilization',
                    category: 'fertilization',
                    color: Colors.green,
                  ),
                ],
              ),
            ),

          // Tips List
          if (selectedCategory.isNotEmpty && selectedTreeId != null)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('care_tips')
                    .where('category', isEqualTo: selectedCategory)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tips = snapshot.data!.docs.map((doc) {
                    return CareTip.fromMap(
                        {...doc.data() as Map<String, dynamic>, 'id': doc.id});
                  }).toList();

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('care_tip_completions')
                        .where('userId', isEqualTo: user?.uid)
                        .where('treeId', isEqualTo: selectedTreeId)
                        .snapshots(),
                    builder: (context, completionsSnapshot) {
                      final completions = completionsSnapshot.data?.docs
                              .map((doc) => CareTipCompletion.fromMap({
                                    ...doc.data() as Map<String, dynamic>,
                                    'id': doc.id
                                  }))
                              .toList() ??
                          [];

                      return ListView.builder(
                        itemCount: tips.length,
                        itemBuilder: (context, index) {
                          final tip = tips[index];
                          final completion = completions.firstWhere(
                            (c) => c.tipId == tip.id,
                            orElse: () => CareTipCompletion(
                              id: '',
                              tipId: '',
                              treeId: '',
                              userId: '',
                              completedDate: DateTime.now(),
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(tip.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tip.description),
                                  if (completion.id.isNotEmpty)
                                    Text(
                                      'Completed on: ${_formatDate(completion.completedDate)}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: completion.id.isEmpty
                                  ? ElevatedButton(
                                      onPressed: () =>
                                          _markTipAsComplete(tip.id, context),
                                      child: const Text('Mark Complete'),
                                    )
                                  : const Icon(Icons.check_circle,
                                      color: Colors.green),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
      // Back button when category is selected
      floatingActionButton: selectedCategory.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  selectedCategory = '';
                  selectedTreeId = null;
                });
              },
              child: Icon(Icons.arrow_back),
              backgroundColor: Colors.green[700],
            )
          : null,
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String category,
    required MaterialColor color,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markTipAsComplete(String tipId, BuildContext context) async {
    try {
      final completion = CareTipCompletion(
        id: const Uuid().v4(),
        tipId: tipId,
        treeId: selectedTreeId!,
        userId: user!.uid,
        completedDate: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('care_tip_completions')
          .doc(completion.id)
          .set(completion.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Care tip marked as complete!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking tip as complete: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}