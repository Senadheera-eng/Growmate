//home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grow_mate_version2/controller/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'drag_and_drop_section.dart';
import 'my_trees_section.dart';
import 'tips_section.dart';
import 'settings_section.dart';
import 'login_page.dart';
import 'tree_dashboard_page.dart';
import '../controller/tflite_model.dart';

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

  // Image detection variables
  File? _selectedImage;
  bool _isProcessing = false;
  String _resultText = "";
  final TFLiteModel _model = TFLiteModel();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Add this notification refresh
    _refreshAllNotifications();

    currentUser = _auth.currentUser;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Initialize the TFLite model
    _initModel();
  }

  // Add this private method to HomePage class
  Future<void> _refreshAllNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationService().refreshAllNotifications();
      }
    } catch (e) {
      print('Error refreshing notifications: $e');
    }
  }

  Future<void> _initModel() async {
    await _model.loadModel();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.close(); // Close the model when not needed
    super.dispose();
  }

  // Method to get image from gallery
  Future<void> _getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _processImage(File(image.path));
    }
  }

  // Method to get image from camera
  Future<void> _getImageFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _processImage(File(photo.path));
    }
  }

  // Process the selected image with the model
  Future<void> _processImage(File imageFile) async {
    setState(() {
      _selectedImage = imageFile;
      _isProcessing = true;
      _resultText = "Processing...";
    });

    try {
      // Process the image with your model
      final result = await _model.processImage(imageFile);

      setState(() {
        _isProcessing = false;
        _resultText = result;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _resultText = "Error: ${e.toString()}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  List<Widget> get _pages {
    return [
      DragAndDropSection(
        onGalleryTap: _getImageFromGallery,
        onCameraTap: _getImageFromCamera,
        resultText: _resultText,
        isProcessing: _isProcessing,
        selectedImage: _selectedImage,
      ),
      MyTreesSection(),
      TipsSection(),
      TreeDashboardPage(),
      SettingsSection(
        onThemeChange: (bool value) {},
      ),
    ];
  }

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate bottom padding to ensure content doesn't overlap with nav bar
    final bottomPadding =
        screenHeight * 0.10; // Reduced to 10% of screen height

    return Scaffold(
      extendBody:
          true, // Important to allow the content to go behind the nav bar
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(const Color(0xFF00C853)),
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
              bottom:
                  false, // Don't apply safe area at bottom since we handle that manually
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
                            duration: const Duration(milliseconds: 250),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          Text.rich(
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
                    color: const Color.fromARGB(255, 53, 255, 60),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // User info container - Wrap with Flexible to prevent overflow
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
                mainAxisSize: MainAxisSize.min, // Make row take minimal space
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
                  // Wrap email text with Flexible
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
    // Professional navigation bar with proper dimensions
    final double navBarHeight = 60;
    final double horizontalMargin =
        screenWidth * 0.03; // Reduced to 3% for wider nav bar
    final double bottomMargin =
        10; // Reduced bottom margin to position it lower

    return Container(
      height: navBarHeight,
      margin: EdgeInsets.fromLTRB(
          horizontalMargin, 0, horizontalMargin, bottomMargin),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00C853),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home'),
          _buildNavItem(1, Icons.eco_rounded, 'Trees'),
          _buildNavItem(2, Icons.lightbulb_outline, 'Tips'),
          _buildNavItem(3, Icons.dashboard_rounded, 'Dash'),
          _buildNavItem(4, Icons.settings_rounded, 'Settings'),
        ],
      ),
    );
  }

  /* Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changePage(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.1,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  } */
  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changePage(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          margin: const EdgeInsets.symmetric(
              vertical: 4, horizontal: 4), // Reduced horizontal margin
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(height: 2),
              Flexible(
                // Wrap the Text in a Flexible widget
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.1,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

