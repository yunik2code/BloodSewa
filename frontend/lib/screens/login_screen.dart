import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../main.dart'; // For MainScreen navigation
import './register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController(); // Changed from _passwordController
  bool _isLoading = false;
  bool _obscurePin = true; // Changed from _obscurePassword
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _pinController.dispose(); // Changed from _passwordController
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    print('Attempting login with phone: ${_phoneController.text.trim()}');

    final result = await ApiService.login(
      _phoneController.text.trim(),
      _pinController.text, // Changed from _passwordController
    );

    print('Login result: $result');

    setState(() {
      _isLoading = false;
    });

    // Check if login was successful
    if (result['success'] == true) {
      // Navigate to main screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Login successful!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      // Login failed - extract error message
      String errorMessage = 'Login failed';
      
      if (result['data'] != null) {
        if (result['data']['error'] != null) {
          errorMessage = result['data']['error'].toString();
        } else if (result['data']['detail'] != null) {
          errorMessage = result['data']['detail'].toString();
        } else if (result['data']['message'] != null) {
          errorMessage = result['data']['message'].toString();
        } else if (result['data']['non_field_errors'] != null) {
          // Handle Django validation errors
          final errors = result['data']['non_field_errors'];
          if (errors is List && errors.isNotEmpty) {
            errorMessage = errors[0].toString();
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red[300]!,
              Colors.red[500]!,
              Colors.red[700]!,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: isTablet ? 48 : 20,
                      right: isTablet ? 48 : 20,
                      top: 20,
                      bottom: keyboardHeight > 0 ? keyboardHeight + 20 : 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxWidth: isTablet ? 400 : double.infinity,
                      ),
                      child: Center(
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Dynamic spacing based on screen size
                              SizedBox(height: isTablet ? 40 : 20),

                              // App Logo/Icon with enhanced shadow
                              Container(
                                alignment: Alignment.center,
                                child: Hero(
                                  tag: 'app_logo',
                                  child: Container(
                                    width: isTablet ? 140 : 100,
                                    height: isTablet ? 140 : 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 25,
                                          spreadRadius: 5,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.bloodtype,
                                      size: isTablet ? 70 : 50,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: isTablet ? 40 : 24),

                              // Title with responsive font size
                              Text(
                                'Welcome Back',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 36 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 8),

                              Text(
                                'Enter your phone and PIN to continue',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w300,
                                ),
                              ),

                              SizedBox(height: isTablet ? 50 : 32),

                              // Login Form Card with enhanced design
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 30,
                                      spreadRadius: 0,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(isTablet ? 32 : 24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Phone Number Field with enhanced styling
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: TextFormField(
                                          controller: _phoneController,
                                          autofocus: false,
                                          keyboardType: TextInputType.phone,
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Phone Number',
                                            labelStyle: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: isTablet ? 16 : 14,
                                            ),
                                            prefixIcon: Container(
                                              margin: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.phone,
                                                color: Colors.red[600],
                                                size: isTablet ? 24 : 20,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: Colors.red[600]!,
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: Colors.red[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: isTablet ? 20 : 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your phone number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),

                                      SizedBox(height: isTablet ? 24 : 20),

                                      // PIN Field with enhanced styling
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: TextFormField(
                                          controller: _pinController,
                                          autofocus: false,
                                          obscureText: _obscurePin,
                                          keyboardType: TextInputType.number,
                                          maxLength: 4,
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            letterSpacing: 8, // Add spacing between digits
                                          ),
                                          decoration: InputDecoration(
                                            labelText: '4-Digit PIN',
                                            labelStyle: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: isTablet ? 16 : 14,
                                            ),
                                            counterText: "", // Hide character counter
                                            prefixIcon: Container(
                                              margin: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.pin,
                                                color: Colors.red[600],
                                                size: isTablet ? 24 : 20,
                                              ),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePin
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                                color: Colors.grey[600],
                                                size: isTablet ? 24 : 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePin = !_obscurePin;
                                                });
                                              },
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: Colors.red[600]!,
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: Colors.red[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: isTablet ? 20 : 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your PIN';
                                            }
                                            if (value.length != 4) {
                                              return 'PIN must be exactly 4 digits';
                                            }
                                            if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                                              return 'PIN must contain only numbers';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),

                                      SizedBox(height: isTablet ? 36 : 28),

                                      // Enhanced Login Button
                                      Container(
                                        width: double.infinity,
                                        height: isTablet ? 64 : 56,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            colors: [Colors.red[500]!, Colors.red[600]!],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red[600]!.withOpacity(0.4),
                                              blurRadius: 15,
                                              offset: Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: _isLoading
                                              ? SizedBox(
                                                  height: isTablet ? 26 : 24,
                                                  width: isTablet ? 26 : 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : Text(
                                                  'Login',
                                                  style: TextStyle(
                                                    fontSize: isTablet ? 20 : 18,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: isTablet ? 40 : 24),

                              // Register Link with enhanced styling
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => RegisterScreen(),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              return SlideTransition(
                                                position: animation.drive(
                                                  Tween(begin: Offset(1.0, 0.0), end: Offset.zero),
                                                ),
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Register',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bottom spacing
                              SizedBox(height: isTablet ? 20 : 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}