import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController(); // Changed from password
  final _confirmPinController = TextEditingController(); // Added confirm PIN
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedBloodGroup;
  bool _isDonor = false;
  bool _isLoading = false;
  bool _obscurePin = true; // Changed from password
  bool _obscureConfirmPin = true; // Added for confirm PIN
  Position? _currentPosition;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _heroAnimation;

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _heroAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _pinController.dispose(); // Changed from password
    _confirmPinController.dispose(); // Added
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      PermissionStatus permission = await Permission.location.request();

      if (permission.isGranted) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Please enable location services'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Location obtained successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Location permission denied'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error getting location: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Please select your blood group'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      pin: _pinController.text, // Changed from password to pin
      confirmPin: _confirmPinController.text, // Added confirm PIN
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      bloodGroup: _selectedBloodGroup!,
      phone: _phoneController.text.trim(),
      isDonor: _isDonor,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Registration successful! Please login.'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _usernameController.clear();
      _emailController.clear();
      _pinController.clear(); // Changed from password
      _confirmPinController.clear(); // Added
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
      setState(() {
        _selectedBloodGroup = null;
        _isDonor = false;
        _currentPosition = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                  child: Text(result['data']['error']?.toString() ??
                      'Registration failed')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        style: TextStyle(
          fontSize: isTablet ? 18 : 16, // Increased from 16/14
          fontWeight: FontWeight.w500,
          // Add letter spacing for PIN fields
          letterSpacing: (label.contains('PIN') && obscureText == false) ? 4.0 : null,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: isTablet ? 16 : 14, // Increased from 14/12
            fontWeight: FontWeight.w500,
          ),
          counterText: maxLength != null ? "" : null, // Hide character counter for PIN
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.red[600], size: isTablet ? 26 : 22), // Increased from 24/20
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[600]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[400]!, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[600]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 20 : 16,
          ),
          errorStyle: TextStyle(
            fontSize: isTablet ? 14 : 12, // Increased error text size
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final maxWidth = isTablet ? 500.0 : double.infinity;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isTablet ? 24 : 20, // Increased from 22/18
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        height: screenSize.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red[700]!,
              Colors.red[500]!,
              Colors.pink[300]!,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: FadeTransition(
                opacity: _fadeAnimation ?? AlwaysStoppedAnimation(1.0),
                child: SlideTransition(
                  position: _slideAnimation ?? AlwaysStoppedAnimation(Offset.zero),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: isTablet ? 32 : 24,
                      right: isTablet ? 32 : 24,
                      top: isTablet ? 24 : 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 
                             (isTablet ? 32 : 24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Logo
                        ScaleTransition(
                          scale: _heroAnimation,
                          child: Container(
                            height: isTablet ? 140 : 100,
                            width: isTablet ? 140 : 100,
                            margin: EdgeInsets.only(bottom: isTablet ? 32 : 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person_add,
                              color: Colors.red[600],
                              size: isTablet ? 70 : 50,
                            ),
                          ),
                        ),

                        // Registration Form Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(isTablet ? 32 : 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Header
                                Text(
                                  'Join Our Community',
                                  style: TextStyle(
                                    fontSize: isTablet ? 32 : 28, // Increased from 28/24
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[600],
                                  ),
                                ),
                                SizedBox(height: isTablet ? 32 : 24),

                                // Username
                                _buildInputField(
                                  controller: _usernameController,
                                  label: 'Username',
                                  icon: Icons.person,
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Please enter username'
                                      : null,
                                ),

                                SizedBox(height: isTablet ? 20 : 16),

                                // Email
                                _buildInputField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true)
                                      return 'Please enter email';
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value!)) {
                                      return 'Please enter valid email';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: isTablet ? 20 : 16),

                                // PIN Field (replaces password)
                                _buildInputField(
                                  controller: _pinController,
                                  label: '4-Digit PIN',
                                  icon: Icons.pin,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  obscureText: _obscurePin,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePin
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.red[600],
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePin = !_obscurePin),
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true)
                                      return 'Please enter PIN';
                                    if (value!.length != 4)
                                      return 'PIN must be exactly 4 digits';
                                    if (!RegExp(r'^\d{4}$').hasMatch(value))
                                      return 'PIN must contain only numbers';
                                    
                                    // Check for weak/common PINs
                                    final weakPins = ['0000', '1111', '2222', '3333', '4444', 
                                                     '5555', '6666', '7777', '8888', '9999', 
                                                     '1234', '4321', '1122', '2211', '0123', '3210'];
                                    if (weakPins.contains(value)) {
                                      return 'PIN is too common. Choose a different PIN';
                                    }
                                    
                                    return null;
                                  },
                                ),

                                SizedBox(height: isTablet ? 20 : 16),

                                // Confirm PIN Field (new)
                                _buildInputField(
                                  controller: _confirmPinController,
                                  label: 'Confirm PIN',
                                  icon: Icons.pin,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  obscureText: _obscureConfirmPin,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPin
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.red[600],
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureConfirmPin = !_obscureConfirmPin),
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true)
                                      return 'Please confirm your PIN';
                                    if (value!.length != 4)
                                      return 'PIN must be exactly 4 digits';
                                    if (value != _pinController.text)
                                      return 'PINs do not match';
                                    return null;
                                  },
                                ),

                                SizedBox(height: isTablet ? 20 : 16),

                                // First Name and Last Name Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                        controller: _firstNameController,
                                        label: 'First Name',
                                        icon: Icons.person_outline,
                                        validator: (value) => value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 16 : 12),
                                    Expanded(
                                      child: _buildInputField(
                                        controller: _lastNameController,
                                        label: 'Last Name',
                                        icon: Icons.person_outline,
                                        validator: (value) => value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: isTablet ? 20 : 16),

                                // Phone
                                _buildInputField(
                                  controller: _phoneController,
                                  label: 'Phone Number',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true)
                                      return 'Please enter phone number';
                                    if (value!.length < 10)
                                      return 'Please enter valid phone number';
                                    return null;
                                  },
                                ),

                                SizedBox(height: isTablet ? 20 : 16),

                                // Blood Group Dropdown
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedBloodGroup,
                                    decoration: InputDecoration(
                                      labelText: 'Blood Group',
                                      labelStyle: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: isTablet ? 16 : 14, // Increased from 14/12
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Container(
                                        margin: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.bloodtype, 
                                            color: Colors.red[600], 
                                            size: isTablet ? 26 : 22), // Increased from 24/20
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: Colors.red[600]!, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 20 : 16,
                                        vertical: isTablet ? 20 : 16,
                                      ),
                                    ),
                                    items: _bloodGroups.map((String bloodGroup) {
                                      return DropdownMenuItem<String>(
                                        value: bloodGroup,
                                        child: Text(
                                          bloodGroup,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red[600],
                                            fontSize: isTablet ? 18 : 16, // Increased from 16/14
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedBloodGroup = newValue;
                                      });
                                    },
                                    dropdownColor: Colors.white,
                                  ),
                                ),

                                SizedBox(height: isTablet ? 24 : 20),

                                // Donor Toggle
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _isDonor
                                          ? [Colors.red[50]!, Colors.red[100]!]
                                          : [Colors.grey[50]!, Colors.grey[100]!],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isDonor
                                          ? Colors.red[200]!
                                          : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isDonor ? Colors.red : Colors.grey)
                                            .withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _isDonor
                                              ? Colors.red[100]
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.volunteer_activism,
                                          color: _isDonor
                                              ? Colors.red[600]
                                              : Colors.grey[600],
                                          size: isTablet ? 26 : 22, // Increased from 24/20
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Become a Blood Donor',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: isTablet ? 20 : 18, // Increased from 18/16
                                                color: _isDonor
                                                    ? Colors.red[600]
                                                    : Colors.grey[800],
                                              ),
                                            ),
                                            Text(
                                              'Help save lives by donating blood',
                                              style: TextStyle(
                                                fontSize: isTablet ? 16 : 14, // Increased from 14/12
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: _isDonor,
                                        onChanged: (bool value) {
                                          setState(() {
                                            _isDonor = value;
                                          });
                                        },
                                        activeColor: Colors.red[600],
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: isTablet ? 20 : 16),

                                // Location Button
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_currentPosition != null ? Colors.green : Colors.red)
                                            .withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: OutlinedButton.icon(
                                    onPressed: _getCurrentLocation,
                                    icon: Icon(
                                      _currentPosition != null
                                          ? Icons.check_circle
                                          : Icons.location_on,
                                      color: _currentPosition != null
                                          ? Colors.green
                                          : Colors.red[600],
                                      size: isTablet ? 26 : 22, // Increased from 24/20
                                    ),
                                    label: Text(
                                      _currentPosition != null
                                          ? 'Location Obtained'
                                          : 'Get Current Location',
                                      style: TextStyle(
                                        color: _currentPosition != null
                                            ? Colors.green
                                            : Colors.red[600],
                                        fontWeight: FontWeight.w600,
                                        fontSize: isTablet ? 18 : 16, // Increased from 16/14
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: _currentPosition != null
                                            ? Colors.green
                                            : Colors.red[600]!,
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isTablet ? 16 : 12,
                                      ),
                                    ),
                                  ),
                                ),

                                if (_isDonor && _currentPosition == null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Location is required for donors to be found by others',
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14, // Increased from 14/12
                                        color: Colors.orange[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                SizedBox(height: isTablet ? 36 : 30),

                                // Register Button
                                Container(
                                  width: double.infinity,
                                  height: isTablet ? 64 : 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.red[600]!,
                                        Colors.red[500]!,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.4),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                height: isTablet ? 24 : 20,
                                                width: isTablet ? 24 : 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Creating Account...',
                                                style: TextStyle(
                                                  fontSize: isTablet ? 20 : 18, // Increased from 18/16
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.person_add, 
                                                   size: isTablet ? 26 : 22), // Increased from 24/20
                                              SizedBox(width: 8),
                                              Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  fontSize: isTablet ? 22 : 20, // Increased from 20/18
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),

                                SizedBox(height: isTablet ? 24 : 16),

                                // Login Link
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: isTablet ? 18 : 16, // Increased from 16/14
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: Text(
                                          'Sign In',
                                          style: TextStyle(
                                            color: Colors.red[600],
                                            fontWeight: FontWeight.w600,
                                            fontSize: isTablet ? 18 : 16, // Increased from 16/14
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: isTablet ? 32 : 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }}