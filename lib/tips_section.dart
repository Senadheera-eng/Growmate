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

class _TipsSectionState extends State<TipsSection>
    with SingleTickerProviderStateMixin {
  String? selectedTreeId;
  String selectedCategory = '';
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  List<DiseaseModel> _searchResults = [];
  bool _isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          _buildTipsHeader(),
          _buildSearchBar(),
          if (selectedCategory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTreeDropdown(),
            ),
          ],
          // This is the key change: Expanded widget with a SingleChildScrollView
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              // Use SingleChildScrollView to make content scrollable
              child: _isSearching ? _buildSearchResults() : _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Care Tips',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Learn how to care for your plants',
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for diseases or symptoms...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.green.shade700),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade600),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults.clear();
                        _isSearching = false;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onChanged: _handleSearch,
        ),
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
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
          );
        }

        final trees = snapshot.data!.docs.map((doc) {
          return TreeModel.fromMap(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id});
        }).toList();

        // Check if selectedTreeId exists in the trees list
        bool selectedTreeExists =
            trees.any((tree) => tree.id == selectedTreeId);

        // Reset selectedTreeId if it doesn't exist in the current tree list
        if (selectedTreeId != null && !selectedTreeExists) {
          // Use Future.microtask to avoid setState during build
          Future.microtask(() => setState(() => selectedTreeId = null));
        }

        if (trees.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              selectedCategory == 'diseased'
                  ? 'No diseased trees found'
                  : 'No healthy trees found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Select Tree',
              labelStyle: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.green.shade700, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            value: selectedTreeExists ? selectedTreeId : null,
            items: trees.map((tree) {
              return DropdownMenuItem(
                value: tree.id,
                child: Text(
                  '${tree.name} (${tree.ageInMonths} months)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedTreeId = value;
                _animationController.reset();
                _animationController.forward();
              });
            },
            icon: Icon(Icons.arrow_drop_down, color: Colors.green.shade700),
            dropdownColor: Colors.white,
          ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No diseases found matching your search',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 60,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Please select a tree to view specific care tips',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trees')
          .doc(selectedTreeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
          );
        }

        final treeData = snapshot.data!.data() as Map<String, dynamic>;
        final tree = TreeModel.fromMap({...treeData, 'id': snapshot.data!.id});

        // For diseased category, only show disease specific tips
        if (selectedCategory == 'diseased') {
          if (!tree.isDiseased) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.healing_rounded,
                    size: 60,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This tree has no disease treatment plan',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return _buildDiseaseSpecificTips(tree);
        }

        // For other categories (healthy trees), show care tips
        return _buildCareTips(tree);
      },
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildCategoryCard(
          icon: Icons.local_hospital_rounded,
          title: 'Disease Care',
          category: 'diseased',
          color: Colors.red,
        ),
        _buildCategoryCard(
          icon: Icons.opacity_rounded,
          title: 'Watering Tips',
          category: 'watering',
          color: Colors.blue,
        ),
        _buildCategoryCard(
          icon: Icons.bug_report_rounded,
          title: 'Pest Control',
          category: 'pest',
          color: Colors.orange,
        ),
        _buildCategoryCard(
          icon: Icons.eco_rounded,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedCategory = category;
            selectedTreeId = null; // Reset selected tree when changing category
            _animationController.reset();
            _animationController.forward();
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color.shade300, color.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withOpacity(0.4)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 10 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiseaseCard(DiseaseModel disease) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        expandedAlignment: Alignment.topLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getSeverityColor(disease.severity).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: _getSeverityColor(disease.severity),
            size: 22,
          ),
        ),
        title: Text(
          disease.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getSeverityColor(disease.severity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Severity: ${disease.severity}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getSeverityColor(disease.severity),
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                disease.description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildListSection('Symptoms', disease.symptoms),
              _buildListSection('Treatments', disease.treatments),
              _buildListSection(
                  'Preventive Measures', disease.preventiveMeasures),
            ],
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('diseases')
          .doc(tree.diseaseId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
          );
        }

        if (!snapshot.data!.exists) {
          return const Center(
            child: Text('Disease information not found'),
          );
        }

        final diseaseData = snapshot.data!.data() as Map<String, dynamic>;
        final disease =
            DiseaseModel.fromMap({...diseaseData, 'id': snapshot.data!.id});

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('treatment_steps')
              .where('diseaseId', isEqualTo: tree.diseaseId)
              .snapshots(),
          builder: (context, stepsSnapshot) {
            if (!stepsSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                ),
              );
            }

            // Use ListView instead of Column to make it scrollable
            return ListView(
              padding: EdgeInsets.zero, // Remove default padding
              shrinkWrap: true, // Take only needed space
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Disease Information Card
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade200,
                        Colors.red.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade400.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.warning_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Disease Treatment Plan',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    disease.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.white24,
                          thickness: 1,
                          height: 30,
                        ),
                        if (tree.diseaseIdentifiedDate != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Identified on: ${_formatDate(tree.diseaseIdentifiedDate!)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        _buildWhiteListSection(
                            'Required Treatments', disease.treatments),
                        _buildWhiteListSection(
                            'Preventive Measures', disease.preventiveMeasures),
                      ],
                    ),
                  ),
                ),

                // Treatment Steps Section
                if (stepsSnapshot.data!.docs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.checklist_rounded,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Treatment Steps',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
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
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No treatment steps have been defined for this disease yet. '
                          'Please check back later or contact support for assistance.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWhiteListSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
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
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
          );
        }

        // Filter tips based on tree age in the UI
        final tips = snapshot.data!.docs.where((doc) {
          final tipData = doc.data() as Map<String, dynamic>;
          final minAge = tipData['minimumAge'] as int? ?? 0;
          final maxAge = tipData['maximumAge'] as int? ?? 999;
          return tree.ageInMonths >= minAge && tree.ageInMonths <= maxAge;
        }).toList();

        if (tips.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.eco_outlined,
                  size: 50,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No care tips available for ${tree.name} in this category',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getCategoryIcon(),
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_getCategoryTitle()} for ${tree.name}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...tips.map((tipDoc) {
                final tipData = tipDoc.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('care_tip_completions')
                        .where('tipId', isEqualTo: tipDoc.id)
                        .where('treeId', isEqualTo: tree.id)
                        .snapshots(),
                    builder: (context, completionSnapshot) {
                      final isCompleted = completionSnapshot.hasData &&
                          completionSnapshot.data!.docs.isNotEmpty;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green.shade100
                                        : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isCompleted
                                        ? Icons.check_circle_rounded
                                        : _getTipIcon(tipData['title'] ?? ''),
                                    color: isCompleted
                                        ? Colors.green.shade700
                                        : Colors.blue.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tipData['title'] ?? '',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                          decoration: isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationColor:
                                              Colors.green.shade700,
                                          decorationThickness: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        tipData['description'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isCompleted)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () => _markTipAsComplete(
                                  tipDoc.id,
                                  tree.id,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Mark as Complete',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          if (isCompleted)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                                border: Border(
                                  top: BorderSide(color: Colors.green.shade100),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon() {
    switch (selectedCategory) {
      case 'watering':
        return Icons.opacity_rounded;
      case 'pest':
        return Icons.bug_report_rounded;
      case 'fertilization':
        return Icons.eco_rounded;
      default:
        return Icons.spa_rounded;
    }
  }

  String _getCategoryTitle() {
    switch (selectedCategory) {
      case 'watering':
        return 'Watering Tips';
      case 'pest':
        return 'Pest Control Tips';
      case 'fertilization':
        return 'Fertilization Tips';
      default:
        return 'Care Tips';
    }
  }

  IconData _getTipIcon(String title) {
    if (title.toLowerCase().contains('water')) {
      return Icons.opacity_rounded;
    } else if (title.toLowerCase().contains('pest') ||
        title.toLowerCase().contains('insect')) {
      return Icons.bug_report_rounded;
    } else if (title.toLowerCase().contains('fertiliz') ||
        title.toLowerCase().contains('nutrient')) {
      return Icons.eco_rounded;
    } else if (title.toLowerCase().contains('prune') ||
        title.toLowerCase().contains('cut')) {
      return Icons.content_cut_rounded;
    } else if (title.toLowerCase().contains('sun') ||
        title.toLowerCase().contains('light')) {
      return Icons.wb_sunny_rounded;
    } else {
      return Icons.tips_and_updates_rounded;
    }
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
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Care tip marked as complete!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking tip as complete: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
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
