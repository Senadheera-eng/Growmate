// tree_dashboard_page.dart - Updated implementation
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'tree_model.dart';
import 'tree_stats_model.dart';
import 'tree_detail_page.dart';

class TreeDashboardPage extends StatefulWidget {
  const TreeDashboardPage({Key? key}) : super(key: key);

  @override
  _TreeDashboardPageState createState() => _TreeDashboardPageState();
}

class _TreeDashboardPageState extends State<TreeDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TreeStatsService _statsService = TreeStatsService();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSummaryStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSummaryStats() async {
    try {
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading summary stats: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tree Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Calendar'),
            Tab(text: 'Stats'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSummaryStats();
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // Improved calendar tab with ListView to avoid overflow
  Widget _buildCalendarTab() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Please sign in to view calendar'));
    }

    return ListView(
      children: [
        // Month selector
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.teal.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                        _selectedDate.year, _selectedDate.month - 1, 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                        _selectedDate.year, _selectedDate.month + 1, 1);
                  });
                },
              ),
            ],
          ),
        ),

        // Day of week headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: const Row(
            children: [
              Expanded(
                  child: Text('Sun',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  child: Text('Mon',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  child: Text('Tue',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  child: Text('Wed',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  child: Text('Thu',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  child: Text('Fri',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  child: Text('Sat',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),

        // Calendar grid - with fixed height and rows approach
        _buildCalendarGridWidget(),

        // Upcoming activities header
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Upcoming Activities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Activities list
        FutureBuilder<List<TreeActivity>>(
          future: _getUpcomingActivities(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final activities = snapshot.data!;

            if (activities.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No upcoming activities',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true, // Important to prevent nested ListView issues
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling of nested ListView
              padding: const EdgeInsets.all(8),
              itemCount: activities.length > 3 ? 3 : activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getEventColor(activity.type, activity.successful),
                      child: Icon(
                        _getEventIcon(activity.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle:
                        Text(DateFormat('MMM d, yyyy').format(activity.date)),
                    onTap: () => _navigateToTree(activity.treeId),
                  ),
                );
              },
            );
          },
        ),

        // Spacer at the bottom
        const SizedBox(height: 16),
      ],
    );
  }

  // Updated _buildStatsTab method with pie chart AND existing stats card
  Widget _buildStatsTab() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Please sign in to view statistics'));
    }

    return ListView(
      children: [
        // Pie Chart Card
        FutureBuilder<Map<String, dynamic>>(
          future: _statsService.getStatsSummary(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final stats = snapshot.data!;
            final healthyCount = stats['healthyTrees'];
            final diseasedCount = stats['diseasedTrees'];

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tree Health Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Simple pie chart implementation
                    Row(
                      children: [
                        // Custom pie chart
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(
                            painter: SimplePieChartPainter(
                              healthyCount: healthyCount,
                              diseasedCount: diseasedCount,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${healthyCount + diseasedCount}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Trees',
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Legend and stats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Healthy legend
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$healthyCount Healthy',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Diseased legend
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$diseasedCount Diseased',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Your existing Summary Statistics Card
        FutureBuilder<Map<String, dynamic>>(
          future: _statsService.getStatsSummary(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final stats = snapshot.data!;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total Trees',
                            stats['totalTrees'].toString(), Icons.forest),
                        _buildStatItem(
                            'Healthy',
                            stats['healthyTrees'].toString(),
                            Icons.check_circle,
                            color: Colors.green),
                        _buildStatItem('Diseased',
                            stats['diseasedTrees'].toString(), Icons.healing,
                            color: Colors.orange),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Care Tips',
                            stats['careTipsCompleted'].toString(), Icons.eco,
                            color: Colors.green),
                        _buildStatItem(
                            'Treatments',
                            stats['treatmentsCompleted'].toString(),
                            Icons.medical_services,
                            color: Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Tree List Header
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Your Trees',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Trees List with Progress Bars
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('trees')
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final trees = snapshot.data!.docs.map((doc) {
              return TreeModel.fromMap(
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id});
            }).toList();

            if (trees.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No trees added yet'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: trees.length,
              itemBuilder: (context, index) {
                final tree = trees[index];
                return _buildTreeCardWithProgressBars(tree);
              },
            );
          },
        ),
      ],
    );
  }

// Tree card with progress bars for care tips and treatment steps
  Widget _buildTreeCardWithProgressBars(TreeModel tree) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tree header
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: tree.photoUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      tree.photoUrls[0],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.eco, color: Colors.grey),
                  ),
            title: Text(
              tree.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tree.ageInMonths} months old'),
                if (tree.isDiseased)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Diseased',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TreeDetailPage(tree: tree),
                ),
              );
            },
          ),

          const Divider(height: 1),

          // Progress Bars Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Care Tips Progress Bar
                _buildProgressBarSection(
                  context: context,
                  treeId: tree.id,
                  title: 'Care Tips',
                  icon: Icons.eco,
                  color: Colors.green,
                  queryBuilder: () => _firestore
                      .collection('care_tip_completions')
                      .where('treeId', isEqualTo: tree.id)
                      .where('userId', isEqualTo: _auth.currentUser?.uid),
                  totalGetter: () => _getTotalCareTips(tree.ageInMonths),
                ),

                // Treatment Steps Progress Bar (only for diseased trees)
                if (tree.isDiseased && tree.diseaseId != null) ...[
                  const SizedBox(height: 16),
                  _buildProgressBarSection(
                    context: context,
                    treeId: tree.id,
                    title: 'Treatment Steps',
                    icon: Icons.medical_services,
                    color: Colors.orange,
                    queryBuilder: () => _firestore
                        .collection('treatment_progress')
                        .where('treeId', isEqualTo: tree.id)
                        .where('diseaseId', isEqualTo: tree.diseaseId)
                        .where('userId', isEqualTo: _auth.currentUser?.uid),
                    totalGetter: () => _getTotalTreatmentSteps(tree.diseaseId!),
                    completedFilter: (doc) =>
                        (doc.data() as Map<String, dynamic>)
                            .containsKey('completedDate') &&
                        (doc.data() as Map<String, dynamic>)['completedDate'] !=
                            null,
                  ),
                ],
              ],
            ),
          ),

          // Completed Care Tips Section
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('care_tip_completions')
                .where('treeId', isEqualTo: tree.id)
                .where('userId', isEqualTo: _auth.currentUser?.uid)
                .orderBy('completedDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 40,
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final completions = snapshot.data!.docs;

              if (completions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'No care tips completed yet',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(
                      'Completed Care Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completions.length > 3 ? 3 : completions.length,
                    itemBuilder: (context, index) {
                      final completion =
                          completions[index].data() as Map<String, dynamic>;
                      final date = DateTime.parse(completion['completedDate']);
                      final tipId = completion['tipId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            _firestore.collection('care_tips').doc(tipId).get(),
                        builder: (context, tipSnapshot) {
                          String tipTitle = 'Care tip completed';

                          if (tipSnapshot.hasData && tipSnapshot.data!.exists) {
                            final tipData = tipSnapshot.data!.data()
                                as Map<String, dynamic>;
                            tipTitle = tipData['title'] ?? 'Care tip completed';
                          }

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tipTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d').format(date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  if (completions.length > 3)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        '+ ${completions.length - 3} more',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Treatment Steps for Diseased Trees
          if (tree.isDiseased && tree.diseaseId != null)
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('treatment_progress')
                  .where('treeId', isEqualTo: tree.id)
                  .where('diseaseId', isEqualTo: tree.diseaseId)
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 40,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                final treatments = snapshot.data!.docs;
                final completedTreatments = treatments.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data.containsKey('completedDate') &&
                      data['completedDate'] != null;
                }).toList();

                if (completedTreatments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No treatment steps completed yet',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Completed Treatment Steps',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: completedTreatments.length > 3
                          ? 3
                          : completedTreatments.length,
                      itemBuilder: (context, index) {
                        final treatment = completedTreatments[index].data()
                            as Map<String, dynamic>;
                        final date = DateTime.parse(treatment['completedDate']);
                        final stepId = treatment['stepId'];
                        final isSuccessful =
                            treatment['outcomeAchieved'] == true;

                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore
                              .collection('treatment_steps')
                              .doc(stepId)
                              .get(),
                          builder: (context, stepSnapshot) {
                            String stepTitle = 'Treatment step';

                            if (stepSnapshot.hasData &&
                                stepSnapshot.data!.exists) {
                              final stepData = stepSnapshot.data!.data()
                                  as Map<String, dynamic>;
                              final stepNumber = stepData['stepNumber'];
                              stepTitle = 'Step $stepNumber completed';
                            }

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                              child: Row(
                                children: [
                                  Icon(
                                    isSuccessful
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color: isSuccessful
                                        ? Colors.teal
                                        : Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      stepTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d').format(date),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (completedTreatments.length > 3)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          '+ ${completedTreatments.length - 3} more',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

          // View details button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreeDetailPage(tree: tree),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(color: Colors.teal),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Improved calendar grid with fixed height layout
  Widget _buildCalendarGridWidget() {
    // Get the first day of the selected month
    final firstDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month, 1);

    // Get the last day of the selected month
    final lastDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    // Get the weekday of the first day (0 = Sunday, 6 = Saturday)
    final firstWeekday = firstDayOfMonth.weekday % 7;

    // Calculate the total number of days to display (including padding)
    final totalDays = firstWeekday + lastDayOfMonth.day;
    final totalWeeks = (totalDays / 7).ceil();

    // Build the calendar grid as rows of days
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalWeeks, (weekIndex) {
        return SizedBox(
          height: 40, // Fixed height for each week row
          child: Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex + 1 - firstWeekday;

              if (dayNumber < 1 || dayNumber > lastDayOfMonth.day) {
                // Empty cell for padding days
                return const Expanded(child: SizedBox());
              }

              final date =
                  DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
              final isToday = _isToday(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => _showDayActivities(date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.teal.withOpacity(0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: isToday ? Colors.teal : Colors.grey[300]!,
                        width: isToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        FutureBuilder<bool>(
                          future: _hasActivitiesForDay(date),
                          builder: (context, snapshot) {
                            final hasEvents = snapshot.data == true;

                            if (hasEvents) {
                              return Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.teal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

// Helper method for building a progress bar section
  Widget _buildProgressBarSection({
    required BuildContext context,
    required String treeId,
    required String title,
    required IconData icon,
    required Color color,
    required Query<Map<String, dynamic>> Function() queryBuilder,
    required Future<int> Function() totalGetter,
    bool Function(DocumentSnapshot)? completedFilter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: queryBuilder().snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final docs = snapshot.data!.docs;
            int completed = docs.length;

            // Apply filter if provided
            if (completedFilter != null) {
              completed = docs.where(completedFilter).length;
            }

            return FutureBuilder<int>(
              future: totalGetter(),
              builder: (context, totalSnapshot) {
                final total = totalSnapshot.data ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? completed / total : 0,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completed of $total complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

// Helper function to get total care tips
  Future<int> _getTotalCareTips(int treeAgeInMonths) async {
    final snapshot = await _firestore.collection('care_tips').get();

    // Count tips that apply to this tree's age
    int count = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final minAge = data['minimumAge'] ?? 0;
      final maxAge = data['maximumAge'] ?? 999;

      if (treeAgeInMonths >= minAge && treeAgeInMonths <= maxAge) {
        count++;
      }
    }

    return count > 0 ? count : 1; // Avoid division by zero
  }

// Helper function to get total treatment steps
  Future<int> _getTotalTreatmentSteps(String diseaseId) async {
    final snapshot = await _firestore
        .collection('treatment_steps')
        .where('diseaseId', isEqualTo: diseaseId)
        .get();

    return snapshot.docs.length > 0
        ? snapshot.docs.length
        : 1; // Avoid division by zero
  }

  // Helper method to detect today's date
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Efficient method to check for activities without loading full details
  Future<bool> _hasActivitiesForDay(DateTime date) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Check care tips
    final careTipsSnapshot = await _firestore
        .collection('care_tip_completions')
        .where('userId', isEqualTo: userId)
        .where('completedDate',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('completedDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .limit(1)
        .get();

    if (careTipsSnapshot.docs.isNotEmpty) {
      return true;
    }

    // Check treatment progress
    final treatmentsSnapshot = await _firestore
        .collection('treatment_progress')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in treatmentsSnapshot.docs) {
      final data = doc.data();

      // Check started date
      final startedDate = DateTime.parse(data['startedDate']);
      if (startedDate.year == date.year &&
          startedDate.month == date.month &&
          startedDate.day == date.day) {
        return true;
      }

      // Check completed date if exists
      if (data.containsKey('completedDate') && data['completedDate'] != null) {
        final completedDate = DateTime.parse(data['completedDate']);
        if (completedDate.year == date.year &&
            completedDate.month == date.month &&
            completedDate.day == date.day) {
          return true;
        }
      }
    }

    return false;
  }

  // Get full activities for a specific day
  Future<List<TreeActivity>> _getActivitiesForDay(DateTime date) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final List<TreeActivity> activities = [];

    try {
      // Care tips for this day
      final careTipsSnapshot = await _firestore
          .collection('care_tip_completions')
          .where('userId', isEqualTo: userId)
          .where('completedDate',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('completedDate',
              isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      for (var doc in careTipsSnapshot.docs) {
        final data = doc.data();
        final completedDate = DateTime.parse(data['completedDate']);
        final treeId = data['treeId'];

        // Get tree name
        String treeName = '';
        try {
          final treeDoc =
              await _firestore.collection('trees').doc(treeId).get();
          if (treeDoc.exists) {
            treeName = treeDoc.data()?['name'] ?? '';
          }
        } catch (e) {
          // Ignore errors getting tree
        }

        activities.add(TreeActivity(
          id: doc.id,
          treeId: treeId,
          title: treeName.isNotEmpty ? '$treeName: Care Tip' : 'Care Tip',
          description: 'Care activity was completed',
          date: completedDate,
          type: 'care_tip',
          successful: true,
        ));
      }

      // Treatment progress for this day - started treatments
      final treatmentsSnapshot = await _firestore
          .collection('treatment_progress')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in treatmentsSnapshot.docs) {
        final data = doc.data();
        final treeId = data['treeId'];
        String treeName = '';

        try {
          final treeDoc =
              await _firestore.collection('trees').doc(treeId).get();
          if (treeDoc.exists) {
            treeName = treeDoc.data()?['name'] ?? '';
          }
        } catch (e) {
          // Ignore errors getting tree
        }

        // Treatment started
        final startedDate = DateTime.parse(data['startedDate']);
        if (startedDate.year == date.year &&
            startedDate.month == date.month &&
            startedDate.day == date.day) {
          activities.add(TreeActivity(
            id: '${doc.id}_start',
            treeId: treeId,
            title: treeName.isNotEmpty
                ? '$treeName: Treatment Started'
                : 'Treatment Started',
            description: 'Treatment step was started',
            date: startedDate,
            type: 'treatment_start',
            successful: null,
          ));
        }

        // Treatment completed
        if (data.containsKey('completedDate') &&
            data['completedDate'] != null) {
          final completedDate = DateTime.parse(data['completedDate']);
          if (completedDate.year == date.year &&
              completedDate.month == date.month &&
              completedDate.day == date.day) {
            activities.add(TreeActivity(
              id: '${doc.id}_complete',
              treeId: treeId,
              title: treeName.isNotEmpty
                  ? '$treeName: Treatment Completed'
                  : 'Treatment Completed',
              description: 'Treatment step was completed',
              date: completedDate,
              type: 'treatment_complete',
              successful: data['outcomeAchieved'],
            ));
          }
        }
      }
    } catch (e) {
      print('Error getting activities: $e');
    }

    // Sort by time
    activities.sort((a, b) => a.date.compareTo(b.date));
    return activities;
  }

  // Get upcoming activities for the home screen
  Future<List<TreeActivity>> _getUpcomingActivities() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final List<TreeActivity> activities = [];
    final now = DateTime.now();

    try {
      // Get all trees
      final treesSnapshot = await _firestore
          .collection('trees')
          .where('userId', isEqualTo: userId)
          .get();

      final trees = treesSnapshot.docs;

      // For each tree with disease, check in-progress treatments
      for (var treeDoc in trees) {
        final treeData = treeDoc.data();
        final treeId = treeDoc.id;
        final treeName = treeData['name'] ?? '';

        if (treeData['isDiseased'] == true && treeData['diseaseId'] != null) {
          // Get in-progress treatment steps
          final treatmentsSnapshot = await _firestore
              .collection('treatment_progress')
              .where('treeId', isEqualTo: treeId)
              .where('diseaseId', isEqualTo: treeData['diseaseId'])
              .where('userId', isEqualTo: userId)
              .get();

          for (var doc in treatmentsSnapshot.docs) {
            final data = doc.data();
            if (data.containsKey('completedDate') &&
                data['completedDate'] != null) continue;

            final startedDate = DateTime.parse(data['startedDate']);
            final stepId = data['stepId'];

            // Default values
            int recommendedDays = 7;
            String stepName = 'Treatment Step';

            // Try to get step details
            try {
              final stepDoc = await _firestore
                  .collection('treatment_steps')
                  .doc(stepId)
                  .get();
              if (stepDoc.exists) {
                final stepData = stepDoc.data()!;
                recommendedDays = stepData['recommendedDays'] ?? 7;
                final stepNumber = stepData['stepNumber'];
                stepName = 'Treatment Step $stepNumber';
              }
            } catch (e) {
              // Ignore errors fetching step details
            }

            // Calculate target completion date
            final targetDate = startedDate.add(Duration(days: recommendedDays));

            if (targetDate.isAfter(now)) {
              activities.add(TreeActivity(
                id: doc.id,
                treeId: treeId,
                title: '$treeName: Complete $stepName',
                description: 'Treatment needs to be completed',
                date: targetDate,
                type: 'treatment_upcoming',
                successful: null,
              ));
            }
          }
        }

        // Get last watering to predict next
        final wateringTipsSnapshot = await _firestore
            .collection('care_tip_completions')
            .where('treeId', isEqualTo: treeId)
            .where('userId', isEqualTo: userId)
            .orderBy('completedDate', descending: true)
            .limit(1)
            .get();

        if (wateringTipsSnapshot.docs.isNotEmpty) {
          final lastWateringData = wateringTipsSnapshot.docs.first.data();
          final lastWateringDate =
              DateTime.parse(lastWateringData['completedDate']);

          // Predict next watering (7 days after last)
          final nextWateringDate =
              lastWateringDate.add(const Duration(days: 7));

          if (nextWateringDate.isAfter(now)) {
            activities.add(TreeActivity(
              id: 'watering_${treeId}_${nextWateringDate.millisecondsSinceEpoch}',
              treeId: treeId,
              title: '$treeName: Water your tree',
              description: 'Regular watering is important for healthy growth',
              date: nextWateringDate,
              type: 'watering_upcoming',
              successful: null,
            ));
          }
        }
      }

      // Sort by date
      activities.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      print('Error getting upcoming activities: $e');
    }

    return activities;
  }

  // Show bottom sheet with activities for a day
  void _showDayActivities(DateTime date) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(date);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Activities on $formattedDate',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<TreeActivity>>(
                future: _getActivitiesForDay(date),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final activities = snapshot.data!;

                  if (activities.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No activities on this day')),
                    );
                  }

                  return Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getEventColor(
                                activity.type, activity.successful),
                            child: Icon(
                              _getEventIcon(activity.type),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          title: Text(activity.title),
                          subtitle:
                              Text(DateFormat('h:mm a').format(activity.date)),
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToTree(activity.treeId);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Navigate to tree details page
  void _navigateToTree(String treeId) {
    _firestore.collection('trees').doc(treeId).get().then((doc) {
      if (doc.exists) {
        final tree = TreeModel.fromMap({...doc.data()!, 'id': doc.id});
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TreeDetailPage(tree: tree),
          ),
        );
      }
    });
  }

  // Helper to build stat item for summary section
  Widget _buildStatItem(String label, String value, IconData icon,
      {Color color = Colors.teal}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Build simplified tree card that won't overflow

  // Get event color based on type
  Color _getEventColor(String type, bool? successful) {
    if (type == 'care_tip') {
      return Colors.green;
    } else if (type == 'treatment_start') {
      return Colors.blue;
    } else if (type == 'treatment_complete') {
      if (successful == true) {
        return Colors.teal;
      } else if (successful == false) {
        return Colors.orange;
      }
      return Colors.grey;
    } else if (type == 'watering_upcoming') {
      return Colors.blue;
    } else if (type == 'treatment_upcoming') {
      return Colors.purple;
    }
    return Colors.grey;
  }

  // Get event icon based on type
  IconData _getEventIcon(String type) {
    switch (type) {
      case 'care_tip':
        return Icons.eco;
      case 'treatment_start':
        return Icons.medical_services;
      case 'treatment_complete':
        return Icons.check_circle;
      case 'watering_upcoming':
        return Icons.opacity;
      case 'treatment_upcoming':
        return Icons.healing;
      default:
        return Icons.event;
    }
  }
}

class SimplePieChartPainter extends CustomPainter {
  final int healthyCount;
  final int diseasedCount;

  SimplePieChartPainter({
    required this.healthyCount,
    required this.diseasedCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Calculate percentages
    final total = healthyCount + diseasedCount;
    final healthyPercent = total > 0 ? healthyCount / total : 0.0;
    final diseasedPercent = total > 0 ? diseasedCount / total : 0.0;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // If no trees, stop here
    if (total == 0) return;

    // Draw diseased section (red)
    if (diseasedPercent > 0) {
      final diseasedPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708, // Start from top (90 degrees in radians)
        diseasedPercent * 6.2832, // Full circle is 2*pi = 6.2832
        true,
        diseasedPaint,
      );
    }

    // Draw healthy section (green)
    if (healthyPercent > 0) {
      final healthyPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708 + diseasedPercent * 6.2832,
        healthyPercent * 6.2832,
        true,
        healthyPaint,
      );
    }

    // Draw inner white circle for donut effect
    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, innerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
