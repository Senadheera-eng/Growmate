// tree_dashboard_page.dart - Updated implementation with improved UI
import 'package:animations/animations.dart';
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

    // Add listener for smooth animations
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
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
        SnackBar(
          content: Text('Error loading summary stats: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          _buildDashboardHeader(),

          // Premium segment control style selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTabSelector(
                        0, Icons.calendar_month_rounded, "Calendar"),
                    _buildTabSelector(
                        1, Icons.insert_chart_rounded, "Statistics"),
                  ],
                ),
              ),
            ),
          ),

          // Content area with page transition
          Expanded(
            child: PageTransitionSwitcher(
              duration: const Duration(milliseconds: 400),
              reverse: _tabController.previousIndex > _tabController.index,
              transitionBuilder: (child, animation, secondaryAnimation) {
                return FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              },
              child: _tabController.index == 0
                  ? _buildCalendarTab()
                  : _buildStatsTab(),
            ),
          ),
        ],
      ),
    );
  }

  // Custom tab selector widget
  Widget _buildTabSelector(int index, IconData icon, String text) {
    final isSelected = _tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      const Color(0xFF00C853),
                      const Color(0xFF1B5E20),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00C853).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
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
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tree Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track your plant progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () {
              _loadSummaryStats();
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
          ),
        ],
      ),
    );
  }

  // Improved calendar tab with ListView to avoid overflow
  Widget _buildCalendarTab() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Please sign in to view calendar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Month selector
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime(
                          _selectedDate.year, _selectedDate.month - 1, 1);
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime(
                          _selectedDate.year, _selectedDate.month + 1, 1);
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Calendar container
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
            children: [
              // Day of week headers
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('Sun',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C853),
                            ))),
                    Expanded(
                        child: Text('Mon',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ))),
                    Expanded(
                        child: Text('Tue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ))),
                    Expanded(
                        child: Text('Wed',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ))),
                    Expanded(
                        child: Text('Thu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ))),
                    Expanded(
                        child: Text('Fri',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ))),
                    Expanded(
                        child: Text('Sat',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C853),
                            ))),
                  ],
                ),
              ),

              // Divider
              Divider(
                color: Colors.grey.shade200,
                height: 1,
              ),

              // Calendar grid
              _buildCalendarGridWidget(),
            ],
          ),
        ),

        // Upcoming activities section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: Color(0xFF00C853),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Upcoming Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Activities list
              FutureBuilder<List<TreeActivity>>(
                future: _getUpcomingActivities(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                        ),
                      ),
                    );
                  }

                  final activities = snapshot.data!;

                  if (activities.isEmpty) {
                    return Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No upcoming activities',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activities.length > 3 ? 3 : activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _navigateToTree(activity.treeId),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getEventColor(
                                            activity.type, activity.successful)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getEventIcon(activity.type),
                                    color: _getEventColor(
                                        activity.type, activity.successful),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF424242),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d, yyyy')
                                            .format(activity.date),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Color(0xFF00C853),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Updated _buildStatsTab method with pie chart AND existing stats card
  Widget _buildStatsTab() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Please sign in to view statistics',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Pie Chart Card
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
          child: FutureBuilder<Map<String, dynamic>>(
            future: _statsService.getStatsSummary(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                    ),
                  ),
                );
              }

              final stats = snapshot.data!;
              final healthyCount = stats['healthyTrees'];
              final diseasedCount = stats['diseasedTrees'];

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.pie_chart_rounded,
                            color: Color(0xFF00C853),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Tree Health Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Simple pie chart implementation
                    Row(
                      children: [
                        // Custom pie chart
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
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
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  const Text(
                                    'Trees',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Legend and stats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Healthy legend
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$healthyCount Healthy',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Diseased legend
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$diseasedCount Diseased',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Your existing Summary Statistics Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          child: FutureBuilder<Map<String, dynamic>>(
            future: _statsService.getStatsSummary(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                    ),
                  ),
                );
              }

              final stats = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            color: Color(0xFF00C853),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                              'Total Trees',
                              stats['totalTrees'].toString(),
                              Icons.forest_rounded),
                          _buildStatItem(
                              'Healthy',
                              stats['healthyTrees'].toString(),
                              Icons.check_circle_rounded,
                              color: Colors.green),
                          _buildStatItem(
                              'Diseased',
                              stats['diseasedTrees'].toString(),
                              Icons.healing_rounded,
                              color: Colors.orange),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                              'Care Tips',
                              stats['careTipsCompleted'].toString(),
                              Icons.eco_rounded,
                              color: Colors.green),
                          _buildStatItem(
                              'Treatments',
                              stats['treatmentsCompleted'].toString(),
                              Icons.medical_services_rounded,
                              color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Tree List Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.forest_rounded,
                  color: Color(0xFF00C853),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Trees',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                  ),
                ),
              );
            }

            final trees = snapshot.data!.docs.map((doc) {
              return TreeModel.fromMap(
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id});
            }).toList();

            if (trees.isEmpty) {
              return Container(
                margin: const EdgeInsets.all(20),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No trees added yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add trees to start tracking their progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tree header
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TreeDetailPage(tree: tree),
                ),
              );
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Tree image or placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: tree.photoUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              tree.photoUrls[0],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.broken_image_rounded,
                                    color: Colors.grey),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.eco_rounded,
                                color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 16),

                  // Tree info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tree.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tree.ageInMonths} months old',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (tree.isDiseased)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  size: 14,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Diseased',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF00C853),
                  ),
                ],
              ),
            ),
          ),

          Divider(color: Colors.grey.shade200, height: 1),

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
                  icon: Icons.eco_rounded,
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
                    icon: Icons.medical_services_rounded,
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
                return SizedBox(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.green.shade300),
                    ),
                  ),
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

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Completed Care Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            completions.length > 3 ? 3 : completions.length,
                        itemBuilder: (context, index) {
                          final completion =
                              completions[index].data() as Map<String, dynamic>;
                          final date =
                              DateTime.parse(completion['completedDate']);
                          final tipId = completion['tipId'];

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('care_tips')
                                .doc(tipId)
                                .get(),
                            builder: (context, tipSnapshot) {
                              String tipTitle = 'Care tip completed';

                              if (tipSnapshot.hasData &&
                                  tipSnapshot.data!.exists) {
                                final tipData = tipSnapshot.data!.data()
                                    as Map<String, dynamic>;
                                tipTitle =
                                    tipData['title'] ?? 'Care tip completed';
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.green.shade700,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        tipTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF424242),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM d').format(date),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
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
                    ),
                    if (completions.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 8),
                        child: Text(
                          '+ ${completions.length - 3} more',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
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
                  return SizedBox(
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange.shade300),
                      ),
                    ),
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
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'No treatment steps completed yet',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services_rounded,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Completed Treatment Steps',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.orange.shade100,
                            width: 1,
                          ),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: completedTreatments.length > 3
                              ? 3
                              : completedTreatments.length,
                          itemBuilder: (context, index) {
                            final treatment = completedTreatments[index].data()
                                as Map<String, dynamic>;
                            final date =
                                DateTime.parse(treatment['completedDate']);
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
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: isSuccessful
                                              ? Colors.teal.shade100
                                              : Colors.orange.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isSuccessful
                                              ? Icons.check
                                              : Icons.warning_rounded,
                                          color: isSuccessful
                                              ? Colors.teal.shade700
                                              : Colors.orange.shade700,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          stepTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM d').format(date),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
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
                      ),
                      if (completedTreatments.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Text(
                            '+ ${completedTreatments.length - 3} more',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

          // View details button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreeDetailPage(tree: tree),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF00C853),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
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
                          ? const Color(0xFF00C853).withOpacity(0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: isToday
                            ? const Color(0xFF00C853)
                            : Colors.grey.shade300,
                        width: isToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFF424242),
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
                                    color: Color(0xFF00C853),
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
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: queryBuilder().snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                backgroundColor: Color(0xFFE0E0E0),
                minHeight: 8,
              );
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
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            flex: completed,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    color.withOpacity(0.7),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Flexible(
                            flex: total > completed ? total - completed : 1,
                            child: const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completed of $total complete',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${total > 0 ? ((completed / total) * 100).toInt() : 0}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: Color(0xFF00C853),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Activities on $formattedDate',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              FutureBuilder<List<TreeActivity>>(
                future: _getActivitiesForDay(date),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                        ),
                      ),
                    );
                  }

                  final activities = snapshot.data!;

                  if (activities.isEmpty) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No activities on this day',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: _getEventColor(
                                        activity.type, activity.successful)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getEventIcon(activity.type),
                                color: _getEventColor(
                                    activity.type, activity.successful),
                                size: 22,
                              ),
                            ),
                            title: Text(
                              activity.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('h:mm a').format(activity.date),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Color(0xFF00C853),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToTree(activity.treeId);
                            },
                          ),
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
      {Color color = const Color(0xFF00C853)}) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

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
        return Icons.eco_rounded;
      case 'treatment_start':
        return Icons.medical_services_rounded;
      case 'treatment_complete':
        return Icons.check_circle_rounded;
      case 'watering_upcoming':
        return Icons.opacity_rounded;
      case 'treatment_upcoming':
        return Icons.healing_rounded;
      default:
        return Icons.event_note_rounded;
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
