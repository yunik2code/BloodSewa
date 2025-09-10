import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../main.dart';
import './login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;

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
      parent: _animationController!,
      curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _loadUserProfile();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final result = await ApiService.getProfile();

      if (result['success']) {
        setState(() {
          _userProfile = result['data'];
          _isLoading = false;
        });
        _animationController?.forward();
      } else {
        setState(() {
          _isLoading = false;
        });

        // If token is expired, redirect to login
        if (result['statusCode'] == 401) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to load profile'),
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
              Expanded(child: Text('Error loading profile: $e')),
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

  Future<void> _logout() async {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          elevation: 10,
          title: Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[50]!, Colors.red[100]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.logout, color: Colors.red[600], 
                           size: isTablet ? 24 : 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                    fontSize: isTablet ? 20 : 18,
                  ),
                ),
              ],
            ),
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 8),
            child: Text(
              'Are you sure you want to logout?',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red[600]!, Colors.red[500]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => AuthCheck()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon,
      {Color? valueColor}) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[50]!, Colors.red[100]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.red[600],
              size: isTablet ? 24 : 20,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: isTablet ? 28 : 24),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isExpanded = true,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    Widget button = Container(
      height: isTablet ? 56 : 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: isTablet ? 22 : 20),
        label: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
    
    return isExpanded ? Expanded(child: button) : button;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final maxWidth = isTablet ? 600.0 : double.infinity;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: isTablet ? 80 : 60,
                            height: isTablet ? 80 : 60,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 4,
                            ),
                          ),
                          SizedBox(height: isTablet ? 32 : 24),
                          Text(
                            'Loading profile...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation ?? AlwaysStoppedAnimation(1.0),
                      child: SlideTransition(
                        position: _slideAnimation ?? AlwaysStoppedAnimation(Offset.zero),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: isTablet ? 32 : 24,
                            right: isTablet ? 32 : 24,
                            top: isTablet ? 24 : 16,
                            bottom: isTablet ? 32 : 24,
                          ),
                          child: Column(
                            children: [
                              // Header Section
                              Container(
                                padding: EdgeInsets.all(isTablet ? 32 : 24),
                                child: Column(
                                  children: [
                                    // Profile Avatar
                                    ScaleTransition(
                                      scale: _scaleAnimation ?? AlwaysStoppedAnimation(1.0),
                                      child: Container(
                                        width: isTablet ? 150 : 120,
                                        height: isTablet ? 150 : 120,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 25,
                                              spreadRadius: 5,
                                              offset: Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${(_userProfile?['first_name']?.toString().isNotEmpty == true) ? _userProfile!['first_name'][0].toUpperCase() : 'U'}${(_userProfile?['last_name']?.toString().isNotEmpty == true) ? _userProfile!['last_name'][0].toUpperCase() : 'S'}',
                                            style: TextStyle(
                                              fontSize: isTablet ? 48 : 36,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: isTablet ? 24 : 16),

                                    // User Name
                                    Text(
                                      '${_userProfile?['first_name'] ?? 'Unknown'} ${_userProfile?['last_name'] ?? 'User'}',
                                      style: TextStyle(
                                        fontSize: isTablet ? 32 : 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 8),

                                    // Username
                                    Text(
                                      '@${_userProfile?['username'] ?? 'unknown'}',
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    SizedBox(height: isTablet ? 24 : 16),

                                    // Donor Status Badge
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 24 : 16, 
                                          vertical: isTablet ? 12 : 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: (_userProfile?['is_donor'] ?? false)
                                              ? [Colors.green[600]!, Colors.green[500]!]
                                              : [Colors.orange[600]!, Colors.orange[500]!],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: ((_userProfile?['is_donor'] ?? false) 
                                                ? Colors.green 
                                                : Colors.orange).withOpacity(0.4),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            (_userProfile?['is_donor'] ?? false)
                                                ? Icons.volunteer_activism
                                                : Icons.person,
                                            color: Colors.white,
                                            size: isTablet ? 20 : 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            (_userProfile?['is_donor'] ?? false)
                                                ? 'Blood Donor'
                                                : 'Recipient',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: isTablet ? 16 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Stats Section
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 8 : 0),
                                child: Row(
                                  children: [
                                    _buildStatCard(
                                        'Blood Type',
                                        _userProfile?['blood_group'] ?? 'N/A',
                                        Icons.bloodtype,
                                        Colors.blue[600]!),
                                    SizedBox(width: isTablet ? 16 : 12),
                                    _buildStatCard(
                                        'Status',
                                        (_userProfile?['is_donor'] ?? false)
                                            ? 'Active'
                                            : 'User',
                                        Icons.health_and_safety,
                                        Colors.green[600]!),
                                  ],
                                ),
                              ),

                              SizedBox(height: isTablet ? 32 : 24),

                              // Profile Details Section
                              Container(
                                padding: EdgeInsets.all(isTablet ? 32 : 24),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Personal Information',
                                      style: TextStyle(
                                        fontSize: isTablet ? 24 : 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[600],
                                      ),
                                    ),

                                    SizedBox(height: isTablet ? 24 : 16),

                                    // Email
                                    _buildInfoCard(
                                      'Email Address',
                                      _userProfile?['email'] ?? 'Not provided',
                                      Icons.email,
                                    ),

                                    SizedBox(height: isTablet ? 16 : 12),

                                    // Phone
                                    _buildInfoCard(
                                      'Phone Number',
                                      _userProfile?['phone'] ?? 'Not provided',
                                      Icons.phone,
                                    ),

                                    SizedBox(height: isTablet ? 16 : 12),

                                    // Blood Group
                                    _buildInfoCard(
                                      'Blood Group',
                                      _userProfile?['blood_group'] ??
                                          'Not specified',
                                      Icons.bloodtype,
                                      valueColor: Colors.red[600],
                                    ),

                                    SizedBox(height: isTablet ? 16 : 12),

                                    // Location Status
                                    _buildInfoCard(
                                      'Location Status',
                                      (_userProfile?['latitude'] != null &&
                                              _userProfile?['longitude'] != null)
                                          ? 'Location Available'
                                          : 'Location Not Set',
                                      Icons.location_on,
                                      valueColor: (_userProfile?['latitude'] !=
                                                  null &&
                                              _userProfile?['longitude'] != null)
                                          ? Colors.green[600]
                                          : Colors.orange[600],
                                    ),

                                    SizedBox(height: isTablet ? 32 : 24),

                                    // Action Buttons
                                    Row(
                                      children: [
                                        _buildActionButton(
                                          label: 'Refresh',
                                          icon: Icons.refresh,
                                          onPressed: _loadUserProfile,
                                          color: Colors.blue[600]!,
                                        ),
                                        SizedBox(width: isTablet ? 16 : 12),
                                        _buildActionButton(
                                          label: 'Logout',
                                          icon: Icons.logout,
                                          onPressed: _logout,
                                          color: Colors.red[600]!,
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: isTablet ? 32 : 24),

                                    // App Info
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.grey[50]!, Colors.grey[100]!],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border:
                                            Border.all(color: Colors.grey[200]!, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.red[50]!, Colors.red[100]!],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.bloodtype,
                                              color: Colors.red[600],
                                              size: isTablet ? 28 : 24,
                                            ),
                                          ),
                                          SizedBox(height: isTablet ? 12 : 8),
                                          Text(
                                            'Blood Donation App',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isTablet ? 20 : 16,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Connecting donors with those in need',
                                            style: TextStyle(
                                              fontSize: isTablet ? 14 : 12,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
  }
}