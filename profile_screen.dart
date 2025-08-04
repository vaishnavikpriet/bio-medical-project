import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  String _gender = 'M';
  bool _hasHypertension = false;
  bool _hasDiabetes = false;
  bool _isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _loadProfile();
  }

  void _loadProfile() {
    final profile = _storage.getUserProfile();
    if (profile != null) {
      _nameController.text = profile.name;
      _ageController.text = profile.age.toString();
      _heightController.text = profile.height.toString();
      _weightController.text = profile.weight.toString();
      
      setState(() {
        _gender = profile.gender;
        _hasHypertension = profile.hasHypertension;
        _hasDiabetes = profile.hasDiabetes;
        _isEditing = false;
      });
    } else {
      setState(() {
        _isEditing = true;
        _animationController.forward();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final age = int.tryParse(_ageController.text) ?? 0;
      final height = double.tryParse(_heightController.text) ?? 0.0;
      final weight = double.tryParse(_weightController.text) ?? 0.0;
      
      final profile = UserProfile(
        name: _nameController.text,
        age: age,
        gender: _gender,
        height: height,
        weight: weight,
        hasHypertension: _hasHypertension,
        hasDiabetes: _hasDiabetes,
      );

      await _storage.saveUserProfile(profile);

      setState(() {
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile saved successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // FIXED: Removed the .animate().fadeIn() from the AppBar widget.
      appBar: AppBar(
        title: Text('Health Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check_circle_outline : Icons.edit,
                color: Colors.white),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
                _animationController.forward(from: 0.0);
              }
            },
          ).animate().shake(delay: 200.ms),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildPersonalInfoCard(),
                const SizedBox(height: 16),
                _buildHealthConditionsCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _isEditing
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                icon: Icon(Icons.save, color: Colors.white),
                label: Text("SAVE PROFILE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
                onPressed: _saveProfile,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                backgroundColor: Colors.teal.shade600,
              ),
            )
          : null,
    );
  }

  // --- FIXED: Added the missing widget-building methods ---

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.person_outline,
            size: 60,
            color: Colors.white,
          ),
        ).animate().scale(delay: 200.ms),
        const SizedBox(height: 16),
        // Use a ValueListenableBuilder to update the name in real-time
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameController,
          builder: (context, value, child) {
            return Text(
              value.text.isEmpty ? 'Your Profile' : value.text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            );
          },
        ).animate().fadeIn(delay: 300.ms),
        Text(
          _isEditing ? 'Edit your health information' : 'View your health profile',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      shadowColor: Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                Text(
                  'PERSONAL INFORMATION',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            _buildTextField(_nameController, 'Full Name', Icons.person),
            _buildTextField(_ageController, 'Age', Icons.cake, isNumber: true),
            _buildDropdownGender(),
            _buildTextField(_heightController, 'Height (cm)', Icons.height, isNumber: true),
            _buildTextField(_weightController, 'Weight (kg)', Icons.monitor_weight, isNumber: true),
          ],
        ),
      ),
    ).animate().slideX(
          begin: 0.2,
          end: 0,
          delay: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildHealthConditionsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      shadowColor: Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.medical_services_outlined, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Text(
                  'HEALTH CONDITIONS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade400,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            _buildConditionSwitch(
              'History of Hypertension',
              _hasHypertension,
              Icons.favorite_border,
              Colors.red.shade400,
              (value) => setState(() => _hasHypertension = value),
            ),
            _buildConditionSwitch(
              'History of Diabetes',
              _hasDiabetes,
              Icons.bloodtype_outlined,
              Colors.orange.shade400,
              (value) => setState(() => _hasDiabetes = value),
            ),
          ],
        ),
      ),
    ).animate().slideX(
          begin: 0.2,
          end: 0,
          delay: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
        style: TextStyle(color: Colors.grey[800], fontSize: 16),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (isNumber && double.tryParse(value) == null)
            return 'Please enter a valid number';
          return null;
        },
      ),
    ).animate().fadeIn().slideY(
          begin: 0.1,
          end: 0,
          delay: 100.ms,
        );
  }

  Widget _buildDropdownGender() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _gender,
        items: const [
          DropdownMenuItem(value: 'M', child: Text('Male')),
          DropdownMenuItem(value: 'F', child: Text('Female')),
          DropdownMenuItem(value: 'O', child: Text('Other')),
        ],
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: Icon(Icons.transgender, color: Colors.blueGrey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
        style: TextStyle(color: Colors.grey[800], fontSize: 16),
        onChanged: _isEditing ? (val) => setState(() => _gender = val!) : null,
      ),
    ).animate().fadeIn().slideY(
          begin: 0.1,
          end: 0,
          delay: 150.ms,
        );
  }

  Widget _buildConditionSwitch(String title, bool value, IconData icon,
      Color color, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: _isEditing ? onChanged : null,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.4),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(
          begin: 0.1,
          end: 0,
          delay: 200.ms,
        );
  }
}