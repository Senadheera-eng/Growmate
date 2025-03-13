// tree_stats_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../model/tree_model.dart';
import '../model/tree_stats_model.dart';
import 'tree_detail_page.dart';

class TreeStatsPage extends StatefulWidget {
  const TreeStatsPage({Key? key}) : super(key: key);

  @override
  _TreeStatsPageState createState() => _TreeStatsPageState();
}

class _TreeStatsPageState extends State<TreeStatsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TreeStatsService _statsService = TreeStatsService();
  
  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tree Statistics'),
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: Text('Please sign in to view statistics')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tree Statistics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return _buildEmptyState();
          }
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummarySection(trees),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Your Trees',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: trees.length,
                  itemBuilder: (context, index) {
                    return _buildTreeCard(trees[index]);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
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
          const SizedBox(height: 8),
          Text(
            'Add your first tree to start tracking!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummarySection(List<TreeModel> trees) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsService.getStatsSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final stats = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Trees', 
                        stats['totalTrees'].toString(),
                        Icons.forest, 
                        Colors.teal,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Healthy', 
                        stats['healthyTrees'].toString(),
                        Icons.check_circle, 
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Diseased', 
                        stats['diseasedTrees'].toString(),
                        Icons.healing, 
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Care Tips Done', 
                        stats['careTipsCompleted'].toString(),
                        Icons.eco, 
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Treatments Done', 
                        stats['treatmentsCompleted'].toString(),
                        Icons.check_circle, 
                        Colors.teal,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'In Progress', 
                        stats['treatmentsInProgress'].toString(),
                        Icons.pending, 
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildTreeCard(TreeModel tree) {
    return FutureBuilder<TreeStats>(
      future: _statsService.getTreeStats(tree),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (tree.photoUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        tree.photoUrls[0],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.eco, color: Colors.grey),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tree.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${tree.ageInMonths} months old',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
        
        final stats = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TreeDetailPage(tree: tree),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tree header
                  Row(
                    children: [
                      if (tree.photoUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            tree.photoUrls[0],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.eco, color: Colors.grey),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tree.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${tree.ageInMonths} months old',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (tree.isDiseased)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
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
                      ),
                    ],
                  ),
                  
                  // Divider and Stats
                  const Divider(height: 32),
                  
                  // Activity counts
                  Row(
                    children: [
                      // Care Tips Count
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Care Tips',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stats.careTipsCompleted.toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'completed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Vertical divider
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      
                      // Treatment steps (only if diseased)
                      Expanded(
                        child: tree.isDiseased ? Column(
                          children: [
                            const Text(
                              'Treatments',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stats.treatmentStepsCompleted.toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              stats.treatmentStepsInProgress > 0
                                ? '${stats.treatmentStepsInProgress} in progress'
                                : 'completed',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ) : const Column(
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 4),
                            Icon(Icons.check_circle, color: Colors.green, size: 22),
                            Text(
                              'Healthy',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Recent activities
                  if (stats.recentActivities.isNotEmpty) ...[
                    const Divider(height: 32),
                    const Text(
                      'Recent Activities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...stats.recentActivities.take(3).map((activity) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: _getEventColor(activity.type, activity.successful),
                              child: Icon(
                                _getEventIcon(activity.type),
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.title,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(activity.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ).toList(),
                  ],
                  
                  // View Tree Details button
                  const SizedBox(height: 8),
                  SizedBox(
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'View Tree Details',
                        style: TextStyle(color: Colors.teal),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
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
    }
    return Colors.grey;
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
}