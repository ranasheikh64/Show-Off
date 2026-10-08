import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/showoff_controller.dart';

class ShowoffFilterBottomSheet extends StatefulWidget {
  const ShowoffFilterBottomSheet({super.key});

  @override
  State<ShowoffFilterBottomSheet> createState() => _ShowoffFilterBottomSheetState();
}

class _ShowoffFilterBottomSheetState extends State<ShowoffFilterBottomSheet> {
  final ShowOffController _ctrl = Get.find<ShowOffController>();
  
  double _minAge = 18;
  double _maxAge = 100;
  final List<Map<String, String>> _genderOptions = [
    {'label': 'All', 'value': 'All'},
    {'label': 'Male', 'value': 'Male'},
    {'label': 'Female', 'value': 'Female'},
    {'label': 'Other', 'value': 'Other'},
  ];

  final List<Map<String, String>> _petLoverOptions = [
    {'label': 'All', 'value': 'All'},
    {'label': 'Yes', 'value': 'Yes'},
    {'label': 'No', 'value': 'No'},
  ];

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

  List<String> _selectedGender = ['All'];
  List<String> _selectedPetLover = ['All'];
  List<String> _selectedPassions = [];
  List<String> _selectedLookingFor = [];

  @override
  void initState() {
    super.initState();
    final filters = _ctrl.currentFilters;
    if (filters['minAge'] != null) _minAge = double.parse(filters['minAge'].toString());
    if (filters['maxAge'] != null) _maxAge = double.parse(filters['maxAge'].toString());
    if (filters['gender'] != null) _selectedGender = [filters['gender'].toString()];
    if (filters['petLover'] != null) _selectedPetLover = [filters['petLover'].toString()];
    
    if (filters['passion'] != null) {
      _selectedPassions = List<String>.from(
        (filters['passion'] as String).split(',').map((e) => e.trim())
      );
    }
    if (filters['lookingFor'] != null) {
      _selectedLookingFor = List<String>.from(
        (filters['lookingFor'] as String).split(',').map((e) => e.trim())
      );
    }
  }

  void _applyFilters() {
    final Map<String, dynamic> filters = {};
    if (_minAge > 18 || _maxAge < 100) {
      filters['minAge'] = _minAge.toInt();
      filters['maxAge'] = _maxAge.toInt();
    }
    if (_selectedGender.isNotEmpty && _selectedGender.first != 'All') filters['gender'] = _selectedGender.first;
    if (_selectedPetLover.isNotEmpty && _selectedPetLover.first != 'All') filters['petLover'] = _selectedPetLover.first;
    
    if (_selectedPassions.isNotEmpty) {
      filters['passion'] = _selectedPassions.join(',');
    }
    if (_selectedLookingFor.isNotEmpty) {
      filters['lookingFor'] = _selectedLookingFor.join(',');
    }

    _ctrl.applyFilters(filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    _ctrl.applyFilters({});
    Navigator.pop(context);
  }

  Widget _buildChips(List<Map<String, String>> options, List<String> selectedList, bool isSingleSelect) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.map((opt) {
        final isSelected = selectedList.contains(opt['value']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSingleSelect) {
                selectedList.clear();
                selectedList.add(opt['value']!);
              } else {
                if (isSelected) {
                  selectedList.remove(opt['value']);
                } else {
                  selectedList.add(opt['value']!);
                }
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: [Color(0xFFFF4D8D), Color(0xFF91A3F4)])
                  : null,
              color: isSelected ? null : const Color(0xFF282C4A),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white12,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF4D8D).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              opt['label']!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14.sp,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E213A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 24.h),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Posts',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text('Reset', style: TextStyle(color: Colors.redAccent, fontSize: 16.sp)),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              // Age Range
              Text('Age Range: ${_minAge.toInt()} - ${_maxAge.toInt()}', style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
              RangeSlider(
                values: RangeValues(_minAge, _maxAge),
                min: 18,
                max: 100,
                divisions: 82,
                activeColor: const Color(0xFFFF4D8D),
                inactiveColor: Colors.white12,
                onChanged: (values) {
                  setState(() {
                    _minAge = values.start;
                    _maxAge = values.end;
                  });
                },
              ),
              
              // Gender
              SizedBox(height: 16.h),
              Text('Gender', style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
              SizedBox(height: 8.h),
              _buildChips(_genderOptions, _selectedGender, true),

              // Pet Lover
              SizedBox(height: 16.h),
              Text('Pet Lover', style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
              SizedBox(height: 8.h),
              _buildChips(_petLoverOptions, _selectedPetLover, true),

              // Passion
              SizedBox(height: 16.h),
              Text('Passion', style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
              SizedBox(height: 8.h),
              _buildChips(_availablePassions, _selectedPassions, false),

              // Looking For
              SizedBox(height: 16.h),
              Text('Looking For', style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
              SizedBox(height: 8.h),
              _buildChips(_availableLookingFor, _selectedLookingFor, false),

              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D8D),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
