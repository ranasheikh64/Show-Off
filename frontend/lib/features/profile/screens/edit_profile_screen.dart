import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

const _pink = Color(0xFFFF4D8D);
const _purple = Color(0xFF8B5CF6);
const _darkBg = Color(0xFF0B0C1F);
const _cardBg = Color(0xFF141527);
const _inputBg = Color(0xFF1C1E35);

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
  final List<Map<String, String>> _availablePassions = [
    {'label': '📸 Photography', 'value': 'Photography'},
    {'label': '🎵 Music', 'value': 'Music'},
    {'label': '✈️ Traveling', 'value': 'Traveling'},
    {'label': '🍳 Cooking', 'value': 'Cooking'},
    {'label': '🎮 Gaming', 'value': 'Gaming'},
    {'label': '📚 Reading', 'value': 'Reading'},
    {'label': '⚽ Sports', 'value': 'Sports'},
    {'label': '💪 Fitness', 'value': 'Fitness'},
    {'label': '🎨 Art', 'value': 'Art'},
    {'label': '🎬 Movies', 'value': 'Movies'},
    {'label': '💃 Dancing', 'value': 'Dancing'},
    {'label': '💻 Tech', 'value': 'Tech'},
  ];

  final List<Map<String, String>> _availableLookingFor = [
    {'label': '👫 Friendship', 'value': 'Friendship'},
    {'label': '❤️ Relationship', 'value': 'Relationship'},
    {'label': '🤝 Networking', 'value': 'Networking'},
    {'label': '☕ Casual', 'value': 'Casual'},
    {'label': '🏃 Activity Partner', 'value': 'Activity Partner'},
    {'label': '💬 Chatting', 'value': 'Chatting'},
  ];

  List<String> _selectedPassions = [];
  List<String> _selectedLookingFor = [];

  String? _gender;
  String? _petLover;
  File? _imageFile;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];
  final List<String> _petLoverOptions = ['Yes', 'No', 'Sometimes'];

  @override
  void initState() {
    super.initState();
    final user = _authCtrl.currentUser.value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _educationController = TextEditingController(text: user?.education ?? '');
    _selectedPassions = List<String>.from(user?.passion ?? []);
    _selectedLookingFor = List<String>.from(user?.preferences ?? []);

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
    super.dispose();
  }

  Future<void> _pickAge() async {
    final DateTime now = DateTime.now();
    final initialDate = DateTime(
      now.year - (int.tryParse(_ageController.text) ?? 20),
    );
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _pink,
              onPrimary: Colors.white,
              surface: _cardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final int age =
          now.year -
          picked.year -
          ((now.month < picked.month ||
                  (now.month == picked.month && now.day < picked.day))
              ? 1
              : 0);
      setState(() {
        _ageController.text = age.toString();
      });
    }
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
    final data = <String, dynamic>{'name': _nameController.text.trim()};
    if (age != null) data['age'] = age;
    if (_gender != null) data['gender'] = _gender;
    if (_educationController.text.isNotEmpty)
      data['education'] = _educationController.text.trim();
    if (_petLover != null) data['petLover'] = _petLover;
    if (_selectedPassions.isNotEmpty) data['passion'] = _selectedPassions;
    if (_selectedLookingFor.isNotEmpty)
      data['preferences'] = _selectedLookingFor;

    _authCtrl.updateProfile(data, context, imagePath: _imageFile?.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Obx(() {
        return CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24.h),
                      _buildSectionCard(
                        title: 'Basic Info',
                        icon: Icons.person_outline_rounded,
                        children: [
                          _buildTextField(
                            'Full Name',
                            'Enter your name',
                            _nameController,
                            icon: Icons.person_rounded,
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'Age',
                                  'Select age',
                                  _ageController,
                                  icon: Icons.cake_rounded,
                                  readOnly: true,
                                  onTap: _pickAge,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildDropdown(
                                  'Gender',
                                  _genderOptions,
                                  _gender,
                                  (v) => setState(() => _gender = v),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          _buildTextField(
                            'Education',
                            'Enter education',
                            _educationController,
                            icon: Icons.school_rounded,
                          ),
                          SizedBox(height: 14.h),
                          _buildDropdown(
                            'Pet Lover?',
                            _petLoverOptions,
                            _petLover,
                            (v) => setState(() => _petLover = v),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      _buildSectionCard(
                        title: 'Passions',
                        icon: Icons.favorite_rounded,
                        children: [
                          _buildChips(_availablePassions, _selectedPassions),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      _buildSectionCard(
                        title: 'Looking For',
                        icon: Icons.search_rounded,
                        children: [
                          _buildChips(
                            _availableLookingFor,
                            _selectedLookingFor,
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),
                      _buildSaveButton(),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSliverAppBar() {
    final user = _authCtrl.currentUser.value;
    return SliverAppBar(
      expandedHeight: 260.h,
      pinned: true,
      backgroundColor: _darkBg,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0530), _darkBg],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 180.w,
                  height: 180.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pink.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: -30,
                child: Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _purple.withOpacity(0.08),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: double.infinity),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 114.w,
                          height: 114.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [_pink, _purple, _pink],
                            ),
                          ),
                        ),
                        Container(
                          width: 108.w,
                          height: 108.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _darkBg,
                          ),
                        ),
                        Container(
                          width: 102.w,
                          height: 102.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : (user?.profileImage != null
                                      ? CachedNetworkImage(
                                          imageUrl: user!.profileImage!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              _avatarPlaceholder(),
                                        )
                                      : _avatarPlaceholder()),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_pink, _purple],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    user?.name ?? 'Your Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(colors: [_pink, _purple])
                            .createShader(bounds),
                    child: Text(
                      'Tap photo to change',
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ],
          ),
        ),
        titlePadding: EdgeInsets.zero,
        collapseMode: CollapseMode.pin,
      ),
      title: const Text(
        'Edit Profile',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _avatarPlaceholder() => Container(
    color: _inputBg,
    child: const Icon(Icons.person_rounded, size: 50, color: Colors.white24),
  );

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_pink, _purple]),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return CustomTextField(
      label: label,
      hint: hint,
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.white38, size: 18)
          : null,
      fillColor: _inputBg,
      textColor: Colors.white,
      hintColor: Colors.white38,
      labelColor: Colors.white,
      borderColor: Colors.transparent,
      focusedBorderColor: _pink,
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(color: Colors.white, fontSize: 13.sp),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1C1E35),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white38,
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.white38, fontSize: 13.sp),
            filled: true,
            fillColor: _inputBg,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: _pink, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChips(List<Map<String, String>> options, List<String> selected) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.map((opt) {
        final isSelected = selected.contains(opt['value']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selected.remove(opt['value']);
              } else {
                selected.add(opt['value']!);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: [_pink, _purple])
                  : null,
              color: isSelected ? null : _inputBg,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white12,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _pink.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              opt['label']!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: 'Save Changes',
      onPressed: _saveProfile,
      isLoading: _authCtrl.isLoading.value,
      gradient: const LinearGradient(colors: [_pink, _purple]),
      borderRadius: 30.r,
      height: 54.h,
    );
  }
}
