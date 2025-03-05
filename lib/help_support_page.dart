import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  @override
  _HelpSupportPageState createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final List<HelpSection> _helpSections = [
    HelpSection(
      title: 'Getting Started',
      icon: Icons.play_circle_outlined,
      color: Colors.blue,
      guides: [
        HelpGuide(
          title: 'Creating an Account',
          description:
              'Learn how to create your GrowMate account and set up your profile.',
          steps: [
            'Open the GrowMate app on your device',
            'Tap "Sign Up" on the login screen',
            'Enter your email address and create a password',
            'Complete your profile information',
            'Verify your email address and start using GrowMate'
          ],
        ),
        HelpGuide(
          title: 'Adding Your First Tree',
          description:
              'Add your first tree to start tracking its growth and health.',
          steps: [
            'Navigate to the "My Trees" section',
            'Tap the "+" button at the bottom of the screen',
            'Fill in the tree details (name, age, location)',
            'Add at least one photo of your tree',
            'Select the health status of your tree',
            'Tap "Save Tree" to complete the process'
          ],
        ),
      ],
    ),
    HelpSection(
      title: 'Disease Detection',
      icon: Icons.search,
      color: Colors.red,
      guides: [
        HelpGuide(
          title: 'Scanning for Diseases',
          description:
              'Learn how to scan your plants for diseases using the GrowMate app.',
          steps: [
            'Tap on the "Detect" tab in the bottom navigation',
            'Take a clear photo of the affected plant part',
            'Make sure the affected area is in focus and well-lit',
            'Crop the image if needed to highlight the problem area',
            'Wait for GrowMate to analyze the image',
            'Review the diagnosis and suggested treatments'
          ],
        ),
        HelpGuide(
          title: 'Understanding Diagnosis Results',
          description:
              'How to interpret the disease detection results and confidence scores.',
          steps: [
            'Review the detected disease name and confidence percentage',
            'Higher percentages indicate greater confidence in the diagnosis',
            'Check the "Other Possibilities" section for alternative diagnoses',
            'View detailed information about the detected disease',
            'Follow the recommended treatment plans',
            'Save the diagnosis to your tree\'s health history if accurate'
          ],
        ),
      ],
    ),
    HelpSection(
      title: 'Plant Care',
      icon: Icons.eco_outlined,
      color: Colors.green,
      guides: [
        HelpGuide(
          title: 'Care Tips & Reminders',
          description: 'Learn how to access and use care tips for your plants.',
          steps: [
            'Navigate to the "Care Tips" section of the app',
            'Select a plant from your collection',
            'Browse through the care tips customized for your plant',
            'Mark tips as complete once you\'ve performed them',
            'Set up reminders for recurring care activities',
            'Check the calendar to view your care schedule'
          ],
        ),
        HelpGuide(
          title: 'Tracking Tree Growth',
          description:
              'How to record and monitor your plants\' growth over time.',
          steps: [
            'Regularly update your tree\'s height, diameter, and condition',
            'Take consistent photos from the same angle to track visual changes',
            'Record significant events like flowering or fruiting',
            'Note any treatments or fertilizers applied',
            'Review growth trends in the dashboard section',
            'Compare current status to historical data'
          ],
        ),
      ],
    ),
    HelpSection(
      title: 'Treatment Plans',
      icon: Icons.healing_outlined,
      color: Colors.orange,
      guides: [
        HelpGuide(
          title: 'Following Treatment Steps',
          description: 'How to implement and track disease treatment plans.',
          steps: [
            'Access the treatment plan from your tree\'s disease diagnosis',
            'Review all treatment steps before beginning',
            'Follow each step in the recommended order',
            'Mark steps as complete as you perform them',
            'Record the outcome of each treatment step',
            'Check if additional treatments are needed after completion'
          ],
        ),
        HelpGuide(
          title: 'Preventive Measures',
          description:
              'Learn how to prevent common diseases and maintain plant health.',
          steps: [
            'Implement regular inspection routines',
            'Follow proper watering and fertilizing practices',
            'Maintain appropriate spacing between plants',
            'Remove dead leaves and plant debris promptly',
            'Apply recommended preventive treatments',
            'Monitor environmental conditions affecting plant health'
          ],
        ),
      ],
    ),
    HelpSection(
      title: 'Troubleshooting',
      icon: Icons.build_outlined,
      color: Colors.purple,
      guides: [
        HelpGuide(
          title: 'App Issues & Solutions',
          description:
              'Common problems and their solutions when using GrowMate.',
          steps: [
            'If the app crashes, close and restart it',
            'For login issues, try resetting your password',
            'Clear the app cache if you experience performance issues',
            'Ensure your app is updated to the latest version',
            'Check your internet connection for upload/download problems',
            'Contact support if issues persist'
          ],
        ),
        HelpGuide(
          title: 'Improving Disease Detection',
          description:
              'Tips to get the most accurate disease diagnosis results.',
          steps: [
            'Take photos in natural daylight when possible',
            'Ensure the affected area fills most of the frame',
            'Take multiple photos from different angles',
            'Keep the camera steady to avoid blurry images',
            'Clean your camera lens before taking photos',
            'Include both healthy and affected parts for comparison'
          ],
        ),
      ],
    ),
  ];

  int _selectedSectionIndex = 0;
  int _selectedGuideIndex = 0;
  bool _showingGuideDetail = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        // Background gradient like HomePage
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade400, Colors.green.shade700],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: _showingGuideDetail
                        ? _buildGuideDetail()
                        : Column(
                            children: [
                              _buildHeader(),
                              _buildSectionTabs(),
                              _buildGuidesList(),
                              _buildSupportOptions(),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // App Logo and Name
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF5F5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: const Icon(
                  Icons.eco_rounded,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Grow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'Mate',
                  style: TextStyle(
                    color: Color.fromARGB(255, 53, 255, 60),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Help & Support text
          const Text(
            'Help & Support',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 3),
          // Contact support icon button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.contact_support_outlined,
                color: Colors.white,
              ),
              onPressed: _showContactDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
          CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 22,
            child: Icon(
              _helpSections[_selectedSectionIndex].icon,
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
                  _helpSections[_selectedSectionIndex].title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Learn how to use GrowMate effectively',
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

  Widget _buildSectionTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _helpSections.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final section = _helpSections[index];
          final isSelected = index == _selectedSectionIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSectionIndex = index;
                  _selectedGuideIndex = 0;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? section.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuidesList() {
    final currentSection = _helpSections[_selectedSectionIndex];

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(20),
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
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: currentSection.guides.length,
          separatorBuilder: (context, index) => Divider(
            color: Colors.grey.shade200,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final guide = currentSection.guides[index];

            // This container makes the whole card clickable
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedGuideIndex = index;
                    _showingGuideDetail = true;
                  });
                },
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon container on the left - made it lighter green like in the screenshot
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            _getIconForGuide(guide.title),
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title and description - centered vertically with the icon
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              guide.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              guide.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Arrow icon
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuideDetail() {
    final currentSection = _helpSections[_selectedSectionIndex];
    final currentGuide = currentSection.guides[_selectedGuideIndex];

    return Column(
      children: [
        // Back and title header
        Container(
          padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                currentSection.color.withOpacity(0.8),
                currentSection.color,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: currentSection.color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showingGuideDetail = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentGuide.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Step-by-step guide',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Guide content
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Description
                Text(
                  currentGuide.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Steps header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentSection.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.format_list_numbered_rounded,
                        color: currentSection.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Step by Step Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Steps list
                ...List.generate(currentGuide.steps.length, (index) {
                  final stepNumber = index + 1;
                  final step = currentGuide.steps[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: currentSection.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              stepNumber.toString(),
                              style: TextStyle(
                                color: currentSection.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 30),

                // Navigation between guides
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_selectedGuideIndex > 0)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedGuideIndex--;
                          });
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Previous'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.grey.shade800,
                          elevation: 0,
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                    if (_selectedGuideIndex < currentSection.guides.length - 1)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedGuideIndex++;
                          });
                        },
                        icon: const Text('Next'),
                        label: const Icon(Icons.arrow_forward_rounded),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportOptions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
          const Text(
            'Need More Help?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSupportOptionButton(
                icon: Icons.email_outlined,
                label: 'Email Us',
                color: Colors.blue,
                onTap: () => _launchEmail('growmate2002@gmail.com'),
              ),
              _buildSupportOptionButton(
                icon: Icons.help_outline,
                label: 'FAQs',
                color: Colors.orange,
                onTap: _showFaqSection,
              ),
              _buildSupportOptionButton(
                icon: Icons.chat_outlined,
                label: 'Live Chat',
                color: Colors.green,
                onTap: _showLiveChatUnavailable,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveChatUnavailable() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Live Chat'),
          content: const Text(
            'Live chat support is currently unavailable. Please try again during our operating hours (9AM-5PM EST, Monday-Friday) or send us an email at growmate2002@gmail.com.',
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  void _showFaqSection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
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
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  IconButton(
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200),
              Expanded(
                child: ListView(
                  children: [
                    _buildFaqItem(
                      'How does plant disease detection work?',
                      'GrowMate uses advanced image recognition technology to identify plant diseases. When you take a photo of your plant, our AI model analyzes the visual patterns, comparing them to thousands of examples of plant diseases to provide an accurate diagnosis. The system then recommends appropriate treatments based on the identified disease.',
                    ),
                    _buildFaqItem(
                      'How accurate is the disease detection?',
                      'Our disease detection system has an average accuracy of 85-90% for common plant diseases. The accuracy depends on factors like image quality, lighting conditions, and how clearly visible the symptoms are. We continuously improve our AI models with new training data to increase accuracy over time.',
                    ),
                    _buildFaqItem(
                      'Can I use GrowMate offline?',
                      'Some features of GrowMate work offline, such as viewing your saved plants and care schedules. However, the disease detection feature requires an internet connection to process images through our AI system. Any data you enter while offline will sync when you reconnect to the internet.',
                    ),
                    _buildFaqItem(
                      'How do I improve detection results?',
                      'For best results: 1) Take photos in natural daylight, 2) Ensure the affected area is clearly visible and fills most of the frame, 3) Take multiple photos from different angles, 4) Keep the camera steady to avoid blur, and 5) Include both healthy and diseased parts for comparison when possible.',
                    ),
                    _buildFaqItem(
                      'Can GrowMate identify all plant species?',
                      'GrowMate specializes in coconut trees and common garden plants. While our system can identify many plant species, some rare or uncommon varieties might not be recognized. We\'re constantly expanding our database to include more species.',
                    ),
                    _buildFaqItem(
                      'How do I backup my plant data?',
                      'All your plant data is automatically backed up to your GrowMate account in the cloud. If you switch devices, simply log in with the same account to access all your plants and history. For additional security, you can export your data from the settings menu.',
                    ),
                    _buildFaqItem(
                      'Is there a limit to how many plants I can add?',
                      'The free version of GrowMate allows you to add up to 5 plants. With GrowMate Premium, you can add unlimited plants and access additional features like detailed growth analytics and priority support.',
                    ),
                    _buildFaqItem(
                      'How do I update my account information?',
                      'To update your account information, go to the Settings tab, select "Account Settings," and you can change your name, email, password, and profile picture there.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
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
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF00C853),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF424242),
                ),
              ),
            ),
          ],
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: Colors.blue.shade700,
                  ),
                ),
                title: const Text('Email Support'),
                subtitle: const Text('growmate2002@gmail.com'),
                onTap: () {
                  Navigator.pop(context);
                  _launchEmail('growmate2002@gmail.com');
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chat_outlined,
                    color: Colors.purple.shade700,
                  ),
                ),
                title: const Text('Live Chat'),
                subtitle: const Text('Available 9AM-5PM EST, Mon-Fri'),
                onTap: () {
                  Navigator.pop(context);
                  _showLiveChatUnavailable();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=GrowMate Support Request&body=Hello GrowMate Support Team,',
    );

    try {
      await launchUrl(emailUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch email client: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getIconForGuide(String guideTitle) {
    if (guideTitle.toLowerCase().contains('account')) {
      return Icons.person_outline;
    } else if (guideTitle.toLowerCase().contains('tree') ||
        guideTitle.toLowerCase().contains('adding')) {
      return Icons.eco_outlined;
    } else if (guideTitle.toLowerCase().contains('scanning') ||
        guideTitle.toLowerCase().contains('detection')) {
      return Icons.search;
    } else if (guideTitle.toLowerCase().contains('diagnosis') ||
        guideTitle.toLowerCase().contains('understanding')) {
      return Icons.analytics_outlined;
    } else if (guideTitle.toLowerCase().contains('tips') ||
        guideTitle.toLowerCase().contains('care')) {
      return Icons.tips_and_updates_outlined;
    } else if (guideTitle.toLowerCase().contains('tracking') ||
        guideTitle.toLowerCase().contains('growth')) {
      return Icons.trending_up_outlined;
    } else if (guideTitle.toLowerCase().contains('treatment')) {
      return Icons.healing_outlined;
    } else if (guideTitle.toLowerCase().contains('preventive') ||
        guideTitle.toLowerCase().contains('prevent')) {
      return Icons.security_outlined;
    } else if (guideTitle.toLowerCase().contains('issues')) {
      return Icons.build_outlined;
    } else if (guideTitle.toLowerCase().contains('improving')) {
      return Icons.photo_camera_outlined;
    }

    return Icons.help_outline;
  }
}

extension on Color {
  get shade800 => null;
}

class HelpSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<HelpGuide> guides;

  HelpSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.guides,
  });
}

class HelpGuide {
  final String title;
  final String description;
  final List<String> steps;

  HelpGuide({
    required this.title,
    required this.description,
    required this.steps,
  });
}
