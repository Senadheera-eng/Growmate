/* // statistics_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'tree_model.dart';
import 'care_tip_tracking_model.dart';
import 'treatment_step_model.dart';
import 'tree_detail_page.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<dynamic>> _events = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _loadEvents();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEvents() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    // Load care tip completions
    final tipCompletions = await _firestore
        .collection('care_tip_completions')
        .where('userId', isEqualTo: userId)
        .get();
    
    // Load treatment progress
    final treatmentProgress = await _firestore
        .collection('treatment_progress')
        .where('userId', isEqualTo: userId)
        .get();
    
    final Map<DateTime, List<dynamic>> newEvents = {};
    
    // Process care tips
    for (var doc in tipCompletions.docs) {
      final data = doc.data();
      final date = DateTime.parse(data['completedDate'] as String);
      final day = DateTime(date.year, date.month, date.day);
      
      if (newEvents[day] == null) {
        newEvents[day] = [];
      }
      
      newEvents[day]!.add({
        'type': 'care_tip',
        'id': doc.id,
        'treeId': data['treeId'],
        'tipId': data['tipId'],
        'date': date,
      });
    }
    
    // Process treatment steps
    for (var doc in treatmentProgress.docs) {
      final data = doc.data();
      
      // Handle started dates
      final startDate = DateTime.parse(data['startedDate'] as String);
      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      
      if (newEvents[startDay] == null) {
        newEvents[startDay] = [];
      }
      
      newEvents[startDay]!.add({
        'type': 'treatment_start',
        'id': doc.id,
        'treeId': data['treeId'],
        'diseaseId': data['diseaseId'],
        'stepId': data['stepId'],
        'date': startDate,
      });
      
      // Handle completed dates if any
      if (data['completedDate'] != null) {
        final completedDate = DateTime.parse(data['completedDate'] as String);
        final completedDay = DateTime(completedDate.year, completedDate.month, completedDate.day);
        
        if (newEvents[completedDay] == null) {
          newEvents[completedDay] = [];
        }
        
        newEvents[completedDay]!.add({
          'type': 'treatment_complete',
          'id': doc.id,
          'treeId': data['treeId'],
          'diseaseId': data['diseaseId'],
          'stepId': data['stepId'],
          'date': completedDate,
          'outcomeAchieved': data['outcomeAchieved'],
        });
      }
    }
    
    setState(() {
      _events.clear();
      _events.addAll(newEvents);
    });
  }
  
  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tree Statistics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Calendar'),
            Tab(text: 'Tree Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildTreeStatsTab(),
        ],
      ),
    );
  }
  
  Widget _buildCalendarTab() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            markerDecoration: const BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.teal.shade600,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.teal.shade200,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonShowsNext: false,
            titleCentered: true,
          ),
        ),
        const Divider(),
        Expanded(
          child: _selectedDay == null
              ? const Center(child: Text('Select a day to see events'))
              : _buildEventsList(_getEventsForDay(_selectedDay!)),
        ),
      ],
    );
  }
  
  Widget _buildEventsList(List<dynamic> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text('No events for this day'),
      );
    }
    
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('trees').doc(event['treeId']).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text('Loading...'),
                ),
              );
            }
            
            final treeData = snapshot.data!.data() as Map<String, dynamic>?;
            if (treeData == null) {
              return const SizedBox.shrink(); // Tree was deleted
            }
            
            final tree = TreeModel.fromMap({...treeData, 'id': snapshot.data!.id});
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getEventColor(event['type']),
                  child: Icon(
                    _getEventIcon(event['type']),
                    color: Colors.white,
                  ),
                ),
                title: Text(tree.name),
                subtitle: FutureBuilder<String>(
                  future: _getEventDescription(event),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Loading details...');
                    }
                    return Text(snapshot.data!);
                  },
                ),
                trailing: Text(
                  DateFormat('hh:mm a').format(event['date']),
                  style: TextStyle(color: Colors.grey[600]),
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
            );
          },
        );
      },
    );
  }
  
  Widget _buildTreeStatsTab() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Please sign in to view statistics'));
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('trees')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final trees = snapshot.data!.docs.map((doc) {
          return TreeModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
        }).toList();
        
        if (trees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No trees added yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trees.length,
          itemBuilder: (context, index) {
            final tree = trees[index];
            return _buildTreeStatCard(tree);
          },
        );
      },
    );
  }
  
  Widget _buildTreeStatCard(TreeModel tree) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with tree image and name
          SizedBox(
            height: 120,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: tree.photoUrls.isNotEmpty
                      ? Image.network(
                          tree.photoUrls[0],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 120,
                          color: Colors.grey[200],
                          child: const Icon(Icons.eco, size: 50, color: Colors.grey),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tree.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${tree.ageInMonths} months old',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        if (tree.isDiseased)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Diseased',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Stats section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Care tips stats
                _buildStatisticRow(
                  context,
                  'Care Tips',
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('care_tip_completions')
                        .where('treeId', isEqualTo: tree.id)
                        .where('userId', isEqualTo: _auth.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading...');
                      }
                      
                      final completed = snapshot.data!.docs.length;
                      
                      return FutureBuilder<int>(
                        future: _getTotalCareTipsCount(tree.ageInMonths),
                        builder: (context, totalSnapshot) {
                          if (!totalSnapshot.hasData) {
                            return Text('$completed completed');
                          }
                          
                          final total = totalSnapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$completed of $total completed'),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: total > 0 ? completed / total : 0,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Treatment progress stats
                if (tree.isDiseased && tree.diseaseId != null)
                  _buildStatisticRow(
                    context,
                    'Treatment Progress',
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('treatment_progress')
                          .where('treeId', isEqualTo: tree.id)
                          .where('diseaseId', isEqualTo: tree.diseaseId)
                          .where('userId', isEqualTo: _auth.currentUser?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Text('Loading...');
                        }
                        
                        final completedSteps = snapshot.data!.docs
                            .where((doc) => doc.data() is Map && (doc.data() as Map).containsKey('completedDate') && (doc.data() as Map)['completedDate'] != null)
                            .length;
                        
                        return FutureBuilder<int>(
                          future: _getTotalTreatmentStepsCount(tree.diseaseId!),
                          builder: (context, totalSnapshot) {
                            if (!totalSnapshot.hasData) {
                              return Text('$completedSteps steps completed');
                            }
                            
                            final total = totalSnapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$completedSteps of $total steps completed'),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: total > 0 ? completedSteps / total : 0,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Next scheduled activity
                _buildStatisticRow(
                  context,
                  'Next Scheduled Activity',
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _getNextScheduledActivity(tree.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading...');
                      }
                      
                      final nextActivity = snapshot.data;
                      if (nextActivity == null) {
                        return const Text('No upcoming activities');
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nextActivity['title'] as String),
                          Text(
                            DateFormat('MMM d, yyyy').format(nextActivity['date'] as DateTime),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // View Details button
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatisticRow(BuildContext context, String label, Widget content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
  
  Color _getEventColor(String type) {
    switch (type) {
      case 'care_tip':
        return Colors.green;
      case 'treatment_start':
        return Colors.blue;
      case 'treatment_complete':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getEventIcon(String type) {
    switch (type) {
      case 'care_tip':
        return Icons.eco;
      case 'treatment_start':
        return Icons.medical_services;
      case 'treatment_complete':
        return Icons.check_circle;
      default:
        return Icons.event;
    }
  }
  
  Future<String> _getEventDescription(Map<String, dynamic> event) async {
    final type = event['type'];
    
    if (type == 'care_tip') {
      try {
        final tipDoc = await _firestore.collection('care_tips').doc(event['tipId']).get();
        if (tipDoc.exists) {
          final tipData = tipDoc.data();
          return 'Care tip completed: ${tipData?['title'] ?? 'Unknown tip'}';
        }
      } catch (e) {
        print('Error fetching care tip: $e');
      }
      return 'Care tip completed';
    } else if (type == 'treatment_start') {
      try {
        final stepDoc = await _firestore.collection('treatment_steps').doc(event['stepId']).get();
        if (stepDoc.exists) {
          final stepData = stepDoc.data();
          return 'Started treatment step ${stepData?['stepNumber'] ?? '?'}: ${stepData?['instruction']?.substring(0, 30)}...';
        }
      } catch (e) {
        print('Error fetching treatment step: $e');
      }
      return 'Started treatment step';
    } else if (type == 'treatment_complete') {
      try {
        final stepDoc = await _firestore.collection('treatment_steps').doc(event['stepId']).get();
        if (stepDoc.exists) {
          final stepData = stepDoc.data();
          final outcome = event['outcomeAchieved'] == true ? 'successfully' : 'needs attention';
          return 'Completed step ${stepData?['stepNumber'] ?? '?'} $outcome';
        }
      } catch (e) {
        print('Error fetching treatment step: $e');
      }
      return 'Completed treatment step';
    }
    
    return 'Unknown event';
  }
  
  Future<int> _getTotalCareTipsCount(int treeAge) async {
    final snapshot = await _firestore
        .collection('care_tips')
        .where('minimumAge', isLessThanOrEqualTo: treeAge)
        .where('maximumAge', isGreaterThanOrEqualTo: treeAge)
        .get();
    
    return snapshot.docs.length;
  }
  
  Future<int> _getTotalTreatmentStepsCount(String diseaseId) async {
    final snapshot = await _firestore
        .collection('treatment_steps')
        .where('diseaseId', isEqualTo: diseaseId)
        .get();
    
    return snapshot.docs.length;
  }
  
  Future<Map<String, dynamic>?> _getNextScheduledActivity(String treeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    
    // Check for in-progress treatment steps
    final treatmentProgress = await _firestore
        .collection('treatment_progress')
        .where('treeId', isEqualTo: treeId)
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
        final stepData = stepDoc.data();
        final startDate = DateTime.parse(progressData['startedDate']);
        final recommendedDays = stepData?['recommendedDays'] ?? 7;
        final targetDate = startDate.add(Duration(days: recommendedDays));
        
        return {
          'title': 'Complete treatment step ${stepData?['stepNumber']}',
          'date': targetDate,
          'type': 'treatment',
        };
      }
    }
    
    // If no treatment in progress, suggest next watering based on last watering
    final lastWatering = await _firestore
        .collection('care_tip_completions')
        .where('treeId', isEqualTo: treeId)
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
        
        return {
          'title': 'Water your tree',
          'date': nextDate,
          'type': 'watering',
        };
      }
    }
    
    // Default fallback
    return {
      'title': 'Check on your tree',
      'date': DateTime.now().add(const Duration(days: 1)),
      'type': 'checkup',
    };
  }
} */