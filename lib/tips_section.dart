// growmate_care_settings.dart

import 'package:flutter/material.dart';

class TipsSection extends StatelessWidget {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for diseases or tips...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildCategoryCard(
                    icon: Icons.opacity,
                    title: 'Watering Tips',
                    description: 'Learn the best watering practices.',
                  ),
                  _buildCategoryCard(
                    icon: Icons.bug_report,
                    title: 'Pest Control',
                    description: 'Protect your trees from pests.',
                  ),
                  _buildCategoryCard(
                    icon: Icons.eco,
                    title: 'Fertilization',
                    description: 'Proper fertilization for healthy trees.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      {required IconData icon,
      required String title,
      required String description}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[700]),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Handle navigation to detailed tips page
        },
      ),
    );
  }
}
