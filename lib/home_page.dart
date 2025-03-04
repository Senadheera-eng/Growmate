import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'drag_and_drop_section.dart';
import 'my_trees_section.dart';
import 'tips_section.dart';
import 'settings_section.dart';
import 'login_page.dart';
import 'tree_dashboard_page.dart';
import 'tflite_service.dart'; // Import the TFLite service

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? currentUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ImagePicker _picker = ImagePicker();
  final PlantDiseaseDetector _detector = PlantDiseaseDetector();

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _detector.initialize(); // Initialize the TFLite model
  }

  @override
  void dispose() {
    _animationController.dispose();
    _detector.dispose(); // Dispose of the TFLite model
    super.dispose();
  }

  final List<Widget> _pages = [
    DragAndDropSection(),
    const MyTreesSection(),
    const TipsSection(),
    const TreeDashboardPage(),
    SettingsSection(
      onThemeChange: (bool value) {},
    ),
  ];

  Future<void> _handleSignOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error signing out. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _handleAccountAction(String value) async {
    switch (value) {
      case 'Switch Account':
        await _handleSignOut();
        break;
      case 'Create Account':
        Navigator.pushNamed(context, '/signup');
        break;
      case 'Sign Out':
        await _handleSignOut();
        break;
    }
  }

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  // Function to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        _processImageWithTFLite(imageFile);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to take a photo with the camera
  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        _processImageWithTFLite(imageFile);
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to process the image with TFLite
  Future<void> _processImageWithTFLite(File imageFile) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Analyzing your plant...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take a moment',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Process the image with TFLite
      final result = await _detector.detectDisease(imageFile);

      // Close the loading dialog
      Navigator.pop(context);

      // Show the results
      _showDetectionResults(imageFile, result);
    } catch (e) {
      // Close the loading dialog
      Navigator.pop(context);

      print('Error processing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to show detection results
  void _showDetectionResults(File imageFile, Map<String, dynamic> results) {
    final topResult = results['topResult'];
    final allResults = results['allResults'] as List<dynamic>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Detection Results',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    imageFile,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_florist,
                              color: Color(0xFF00C853),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detected Issue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  topResult['label'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  _getConfidenceColor(topResult['confidence'])
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    _getConfidenceColor(topResult['confidence'])
                                        .withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${(topResult['confidence'] * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getConfidenceColor(
                                    topResult['confidence']),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Treatment Recommendations:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on our analysis, we recommend the following treatment options for ${topResult['label']}:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTreatmentItem(
                          Icons.opacity, 'Adjust watering regime'),
                      _buildTreatmentItem(Icons.wb_sunny_outlined,
                          'Ensure proper sunlight exposure'),
                      _buildTreatmentItem(Icons.cleaning_services_outlined,
                          'Remove affected leaves'),
                      _buildTreatmentItem(Icons.eco_outlined,
                          'Apply organic fungicide if needed'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Other Possibilities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ...allResults.skip(1).take(3).map((result) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          result['label'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(result['confidence'] * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF00C853),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) {
      return const Color(0xFF00C853); // Green for high confidence
    } else if (confidence >= 0.4) {
      return Colors.orange; // Orange for medium confidence
    } else {
      return Colors.red; // Red for low confidence
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate bottom padding to ensure buttons don't overlap with nav bar
    final bottomPadding =
        screenHeight * 0.13; // Approximately 13% of screen height

    return Scaffold(
      extendBody: true,
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
              ),
            );
          }

          if (!snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            });
            return const SizedBox.shrink();
          }

          return Container(
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
                        child: Padding(
                          padding: EdgeInsets.only(bottom: bottomPadding),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: FadeTransition(
                              key: ValueKey<int>(_currentIndex),
                              opacity: _fadeAnimation,
                              child: _pages[_currentIndex],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(screenWidth),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // App Logo and Name
          Container(
            height: 42,
            width: 42,
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
          // User info container - Fixed to prevent overflow
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      currentUser?.email?.split('@')[0] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    onSelected: _handleAccountAction,
                    itemBuilder: (BuildContext context) {
                      return {
                        'Switch Account',
                        'Create Account',
                        'Sign Out',
                      }.map((String choice) {
                        IconData iconData;
                        switch (choice) {
                          case 'Switch Account':
                            iconData = Icons.swap_horiz_rounded;
                            break;
                          case 'Create Account':
                            iconData = Icons.person_add_rounded;
                            break;
                          case 'Sign Out':
                            iconData = Icons.logout_rounded;
                            break;
                          default:
                            iconData = Icons.settings;
                        }

                        return PopupMenuItem<String>(
                          value: choice,
                          child: Row(
                            children: [
                              Icon(
                                iconData,
                                size: 18,
                                color: const Color(0xFF00C853),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                choice,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    offset: const Offset(0, 50),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildBottomNavigationBar(double screenWidth) {
    // Make navigation bar bigger
    final double navBarHeight = 80; // Increased from 70
    final double horizontalMargin = screenWidth * 0.04; // 4% of screen width

    return Container(
      height: navBarHeight,
      margin: EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00C853),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double itemWidth = totalWidth / 5;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
                width: itemWidth,
                child: _buildNavItem(0, Icons.home_rounded, 'Home')),
            SizedBox(
                width: itemWidth,
                child: _buildNavItem(1, Icons.eco_rounded, 'Trees')),
            SizedBox(
                width: itemWidth,
                child: _buildNavItem(2, Icons.lightbulb_outline, 'Tips')),
            SizedBox(
                width: itemWidth,
                child: _buildNavItem(3, Icons.dashboard_rounded, 'Dash')),
            SizedBox(
                width: itemWidth,
                child: _buildNavItem(4, Icons.settings_rounded, 'Settings')),
          ],
        );
      }),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _changePage(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              size: 26, // Increased from 24
            ),
            const SizedBox(height: 6), // Increased from 4
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 12, // Increased from 11
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectButtons() {
    return Container(
      padding: const EdgeInsets.only(
          bottom: 120), // Increased to account for larger nav bar
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildActionButton(
              icon: Icons.photo_library_rounded,
              label: "Browse",
              onTap: _pickImageFromGallery, // Connect to the gallery function
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildActionButton(
              icon: Icons.camera_alt_rounded,
              label: "Take Photo",
              isPrimary: true,
              onTap: _takePhoto, // Connect to the camera function
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    // Bigger buttons with consistent size
    return Material(
      color: isPrimary ? const Color(0xFF00C853) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      shadowColor:
          isPrimary ? const Color(0xFF00C853).withOpacity(0.5) : Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFF00C853),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : const Color(0xFF424242),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
