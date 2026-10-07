import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthController _authCtrl = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _educationController;
  late TextEditingController _passionController; // Comma separated for now
  late TextEditingController _preferencesController; // Comma separated for now

  String? _gender;
  String? _petLover;
  File? _imageFile;

  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _petLoverOptions = ['Yes', 'No', 'Sometimes'];

  @override
  void initState() {
    super.initState();
    final user = _authCtrl.currentUser.value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _educationController = TextEditingController(text: user?.education ?? '');
    _passionController = TextEditingController(text: user?.passion.join(', ') ?? '');
    _preferencesController = TextEditingController(text: user?.preferences.join(', ') ?? '');
    
    _gender = user?.gender;
    if (_gender != null && !_genderOptions.contains(_gender)) {
      _gender = 'Prefer not to say';
    }
    
    _petLover = user?.petLover;
    if (_petLover != null && !_petLoverOptions.contains(_petLover)) {
      _petLover = 'No';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _educationController.dispose();
    _passionController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    
    final int? age = int.tryParse(_ageController.text.trim());
    final List<String> passions = _passionController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final List<String> preferences = _preferencesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
    };
    if (age != null) data['age'] = age;
    if (_gender != null) data['gender'] = _gender;
    if (_educationController.text.isNotEmpty) data['education'] = _educationController.text.trim();
    if (_petLover != null) data['petLover'] = _petLover;
    if (passions.isNotEmpty) data['passion'] = passions;
    if (preferences.isNotEmpty) data['preferences'] = preferences;

    _authCtrl.updateProfile(data, context, imagePath: _imageFile?.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C1F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (_authCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePicker(),
                SizedBox(height: 30.h),
                _buildTextField('Name', _nameController, icon: Icons.person_rounded),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Age', _ageController, icon: Icons.cake_rounded, isNumber: true)),
                    SizedBox(width: 16.w),
                    Expanded(child: _buildDropdown('Gender', _genderOptions, _gender, (v) => setState(() => _gender = v))),
                  ],
                ),
                SizedBox(height: 20.h),
                _buildTextField('Education', _educationController, icon: Icons.school_rounded),
                SizedBox(height: 20.h),
                _buildDropdown('Pet Lover?', _petLoverOptions, _petLover, (v) => setState(() => _petLover = v)),
                SizedBox(height: 20.h),
                _buildTextField('Passions (comma separated)', _passionController, icon: Icons.favorite_rounded),
                SizedBox(height: 20.h),
                _buildTextField('Looking for (comma separated)', _preferencesController, icon: Icons.search_rounded),
                SizedBox(height: 40.h),
                SizedBox(
                  width: double.infinity,
                  height: 55.h,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D8D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildImagePicker() {
    final user = _authCtrl.currentUser.value;
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF4D8D), width: 3),
              ),
              child: ClipOval(
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : (user?.profileImage != null
                        ? CachedNetworkImage(
                            imageUrl: user!.profileImage!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.person, size: 60, color: Colors.white54),
                          )
                        : const Icon(Icons.person, size: 60, color: Colors.white54)),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4D8D),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white54) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF1A1040),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
      ),
    );
  }
}
