import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grow_mate_version2/login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signup(BuildContext context) async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email is already in use.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade400, Colors.green.shade700],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // App Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF5F5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 3,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
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
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App Name
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Grow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: 'Mate',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 53, 255, 60),
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  // Signup Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          spreadRadius: 2,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Text(
                            'Sign up to get started',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF757575),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Email Field
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(
                                Icons.email_rounded,
                                color: Color(0xFF2E7D32),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Color(0xFFB2DFDB),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Color(0xFF00C853),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFE8F5E9),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF424242),
                            ),
                          ),
                          const SizedBox(height: 22),
                          // Password Field
                          TextField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_rounded,
                                color: Color(0xFF2E7D32),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: const Color(0xFF2E7D32),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Color(0xFFB2DFDB),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Color(0xFF00C853),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFE8F5E9),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF424242),
                            ),
                          ),
                          const SizedBox(height: 22),
                          // Confirm Password Field
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFF2E7D32),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: const Color(0xFF2E7D32),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Color(0xFFB2DFDB),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Color(0xFF00C853),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFE8F5E9),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => signup(context),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF424242),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading ? null : () => signup(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C853),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 3,
                                shadowColor:
                                    const Color(0xFF00C853).withOpacity(0.5),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'SIGN UP',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Login Container
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: Color(0xFF424242),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
