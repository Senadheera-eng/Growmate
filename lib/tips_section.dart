// tips_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grow_mate_version2/treatment_steps_widget.dart';
import 'tree_model.dart';
import 'disease_model.dart';

class TipsSection extends StatefulWidget {
  const TipsSection({Key? key}) : super(key: key);

  @override
  _TipsSectionState createState() => _TipsSectionState();
}

class _TipsSectionState extends State<TipsSection> {
  String? selectedTreeId;
  String selectedCategory = '';
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  List<DiseaseModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for diseases or symptoms...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults.clear();
                                _isSearching = false;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: _handleSearch,
                ),
                if (selectedCategory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildTreeDropdown(),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeDropdown() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('trees')
        .where('userId', isEqualTo: user?.uid);

    // Filter trees based on category
    if (selectedCategory == 'diseased') {
      query = query.where('isDiseased', isEqualTo: true);
    } else {
      // For other categories, only show healthy trees
      query = query.where('isDiseased', isEqualTo: false);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final trees = snapshot.data!.docs.map((doc) {
          return TreeModel.fromMap(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id});
        }).toList();

        if (trees.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              selectedCategory == 'diseased'
                  ? 'No diseased trees found'
                  : 'No healthy trees found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
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
    );
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final nameResults = await FirebaseFirestore.instance
        .collection('diseases')
        .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('name', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
        .get();

    final symptomResults = await FirebaseFirestore.instance
        .collection('diseases')
        .where('symptoms', arrayContains: query.toLowerCase())
        .get();

    final Set<String> addedIds = {};
    final List<DiseaseModel> diseases = [];

    for (var doc in [...nameResults.docs, ...symptomResults.docs]) {
      if (!addedIds.contains(doc.id)) {
        addedIds.add(doc.id);
        diseases.add(DiseaseModel.fromMap({...doc.data(), 'id': doc.id}));
      }
    }

    setState(() => _searchResults = diseases);
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No diseases found matching your search'),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final disease = _searchResults[index];
        return _buildDiseaseCard(disease);
      },
    );
  }

  Widget _buildMainContent() {
    if (selectedCategory.isEmpty) {
      return _buildCategoriesGrid();
    }

    if (selectedTreeId == null) {
      return const Center(
        child: Text('Please select a tree to view specific care tips'),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trees')
          .doc(selectedTreeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final treeData = snapshot.data!.data() as Map<String, dynamic>;
        final tree = TreeModel.fromMap({...treeData, 'id': snapshot.data!.id});

        // For diseased category, only show disease specific tips
        if (selectedCategory == 'diseased') {
          if (!tree.isDiseased) {
            return const Center(
              child: Text('This tree has no disease treatment plan'),
            );
          }
          return SingleChildScrollView(
            child: _buildDiseaseSpecificTips(tree),
          );
        }

        // For other categories (healthy trees), show care tips
        return SingleChildScrollView(
          child: _buildCareTips(tree),
        );
      },
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildCategoryCard(
          icon: Icons.local_hospital,
          title: 'Disease Care',
          category: 'diseased',
          color: Colors.red,
        ),
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
          color: Colors.orange,
        ),
        _buildCategoryCard(
          icon: Icons.eco,
          title: 'Fertilization',
          category: 'fertilization',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String category,
    required MaterialColor color,
  }) {
    final isSelected = selectedCategory == category;
    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = category;
          selectedTreeId = null; // Reset selected tree when changing category
        });
      },
      child: Card(
        elevation: isSelected ? 8 : 4,
        color: isSelected ? color.shade50 : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseCard(DiseaseModel disease) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          disease.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Severity: ${disease.severity}',
          style: TextStyle(
            color: _getSeverityColor(disease.severity),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(disease.description),
                const SizedBox(height: 8),
                _buildListSection('Symptoms', disease.symptoms),
                _buildListSection('Treatments', disease.treatments),
                _buildListSection(
                    'Preventive Measures', disease.preventiveMeasures),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
      ],
    );
  }

 Widget _buildDiseaseSpecificTips(TreeModel tree) {
  if (!tree.isDiseased || tree.diseaseId == null) {
    return const Center(
      child: Text('This tree has no disease treatment plan'),
    );
  }

  print('Building disease tips for tree: ${tree.id}, disease: ${tree.diseaseId}');

  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('diseases')
        .doc(tree.diseaseId)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.data!.exists) {
        return const Center(
          child: Text('Disease information not found'),
        );
      }

      final diseaseData = snapshot.data!.data() as Map<String, dynamic>;
      final disease = DiseaseModel.fromMap({...diseaseData, 'id': snapshot.data!.id});

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('treatment_steps')
            .where('diseaseId', isEqualTo: tree.diseaseId)
            .snapshots(),
        builder: (context, stepsSnapshot) {
          if (!stepsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          print('Found ${stepsSnapshot.data!.docs.length} treatment steps'); // Debug log

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Disease Information Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: _getSeverityColor(disease.severity)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Disease Treatment Plan: ${disease.name}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        if (tree.diseaseIdentifiedDate != null)
                          Text(
                            'Identified on: ${_formatDate(tree.diseaseIdentifiedDate!)}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        const SizedBox(height: 16),
                        _buildListSection('Required Treatments', disease.treatments),
                        _buildListSection('Preventive Measures', disease.preventiveMeasures),
                      ],
                    ),
                  ),
                ),

                // Treatment Steps Section
                if (stepsSnapshot.data!.docs.isNotEmpty) ... [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Treatment Steps',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TreatmentStepsWidget(
                      treeId: tree.id,
                      diseaseId: tree.diseaseId!,
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No treatment steps have been defined for this disease yet. '
                      'Please check back later or contact support for assistance.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

  Widget _buildCareTips(TreeModel tree) {
    // Simple query with just category filter
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('care_tips')
        .where('category', isEqualTo: selectedCategory);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter tips based on tree age in the UI
        final tips = snapshot.data!.docs.where((doc) {
          final tipData = doc.data() as Map<String, dynamic>;
          final minAge = tipData['minimumAge'] as int? ?? 0;
          final maxAge = tipData['maximumAge'] as int? ?? 999;
          return tree.ageInMonths >= minAge && tree.ageInMonths <= maxAge;
        }).toList();

        if (tips.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No care tips available for ${tree.name} in this category',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tips.length,
          itemBuilder: (context, index) {
            final tipData = tips[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(tipData['title'] ?? ''),
                subtitle: Text(tipData['description'] ?? ''),
                trailing: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('care_tip_completions')
                      .where('tipId', isEqualTo: tips[index].id)
                      .where('treeId', isEqualTo: tree.id)
                      .snapshots(),
                  builder: (context, completionSnapshot) {
                    final isCompleted = completionSnapshot.hasData &&
                        completionSnapshot.data!.docs.isNotEmpty;

                    return isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            onPressed: () => _markTipAsComplete(
                              tips[index].id,
                              tree.id,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Mark Complete'),
                          );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markTipAsComplete(String tipId, String treeId) async {
    try {
      await FirebaseFirestore.instance.collection('care_tip_completions').add({
        'tipId': tipId,
        'treeId': treeId,
        'userId': user?.uid,
        'completedDate': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Care tip marked as complete!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking tip as complete: $e')),
      );
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}