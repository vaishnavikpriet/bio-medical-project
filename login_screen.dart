import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authentication.dart';
import 'screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({Key? key, required this.authService}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await widget.authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        // Add a small delay to allow the UI to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Ensure we're still mounted before navigating
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = _getFriendlyErrorMessage(e.toString());
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
  setState(() {
    _isGoogleLoading = true;
    _errorMessage = '';
  });

  try {
    await widget.authService.signInWithGoogle();
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    if (mounted) {
      setState(() {
        _errorMessage = _getGoogleSignInErrorMessage(e.code);
        _isGoogleLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _errorMessage = 'Failed to sign in with Google';
        _isGoogleLoading = false;
      });
    }
  }
}

// Add this method to handle friendly error messages
String _getFriendlyErrorMessage(String error) {
  if (error.contains('user-not-found')) {
    return 'No user found for that email.';
  } else if (error.contains('wrong-password')) {
    return 'Incorrect password. Please try again.';
  } else if (error.contains('invalid-email')) {
    return 'The email address is not valid.';
  } else if (error.contains('user-disabled')) {
    return 'This user account has been disabled.';
  } else if (error.contains('too-many-requests')) {
    return 'Too many attempts. Please try again later.';
  } else if (error.contains('network-request-failed')) {
    return 'Network error. Please check your connection.';
  } else {
    return 'Authentication failed. Please try again.';
  }
}

String _getGoogleSignInErrorMessage(String code) {
  switch (code) {
    case 'account-exists-with-different-credential':
      return 'Account exists with different sign-in method';
    case 'invalid-credential':
      return 'Invalid Google credentials';
    case 'operation-not-allowed':
      return 'Google sign-in is not enabled';
    case 'user-disabled':
      return 'This account has been disabled';
    case 'user-not-found':
      return 'No account found';
    case 'wrong-password':
      return 'Incorrect credentials';
    case 'invalid-verification-code':
      return 'Invalid verification code';
    case 'invalid-verification-id':
      return 'Invalid verification ID';
    default:
      return 'Google sign-in failed. Please try again.';
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and title (unchanged)
                    Hero(
                      tag: 'app-logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0066CC).withOpacity(0.8),
                              const Color(0xFF00B4D8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066CC).withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'BP Analyzer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066CC),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Healthcare Professional Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7A90),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error message (unchanged)
                    if (_errorMessage.isNotEmpty)
                      FadeTransition(
                        opacity: AlwaysStoppedAnimation(_errorMessage.isNotEmpty ? 1 : 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_errorMessage.isNotEmpty) const SizedBox(height: 20),

                    // Email and password fields (unchanged)
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: const TextStyle(
                          color: Color(0xFF6B7A90),
                          fontSize: 14,
                        ),
                        prefixIcon: Container(
                          padding: const EdgeInsets.only(right: 12),
                          margin: const EdgeInsets.only(left: 16, right: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF0066CC),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your email' : null,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(
                          color: Color(0xFF6B7A90),
                          fontSize: 14,
                        ),
                        prefixIcon: Container(
                          padding: const EdgeInsets.only(right: 12),
                          margin: const EdgeInsets.only(left: 16, right: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF0066CC),
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF6B7A90),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter password' : null,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          if (_emailController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your email first'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Color(0xFF0066CC),
                              ),
                            );
                            return;
                          }
                          try {
                            await widget.authService.sendPasswordResetEmail(
                                _emailController.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset email sent'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Color(0xFF0066CC),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_getFriendlyErrorMessage(e.toString())),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF0066CC),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign in button (unchanged)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0066CC),
                            Color(0xFF00B4D8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0066CC).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'SIGN IN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),

                    // Google Sign-In button
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Image.asset(
                              'assets/google.png', // Add this asset
                              height: 24,
                              width: 24,
                            ),
                      label: Text(
                        _isGoogleLoading ? 'Signing in...' : 'Sign in with Google',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                    ),
                    const SizedBox(height: 24),

                    // Sign up prompt (unchanged)
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Colors.grey,
                            thickness: 0.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: Colors.grey,
                            thickness: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Color(0xFF6B7A90),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Add navigation to sign up screen
                          },
                          child: const Text(
                            'Register now',
                            style: TextStyle(
                              color: Color(0xFF0066CC),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}