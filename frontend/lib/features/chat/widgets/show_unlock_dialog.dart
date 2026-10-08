// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:frontend/core/constants/app_theme.dart';

// void showUnlockDialog({required String chatId, required String password}) {
//     final TextEditingController pwdCtrl = TextEditingController();
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Dialog(
//             backgroundColor: const Color(0xFF1E213A),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20.r),
//             ),
//             child: Padding(
//               padding: EdgeInsets.all(24.w),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.lock_person_outlined,
//                     color: AppTheme.primaryBlue,
//                     size: 48.sp,
//                   ),
//                   SizedBox(height: 16.h),
//                   Text(
//                     'Unlock Chat',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20.sp,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 8.h),
//                   Text(
//                     'This chat is private. Enter your password to view and send messages.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 13.sp,
//                     ),
//                   ),
//                   SizedBox(height: 24.h),
//                   TextField(
//                     controller: pwdCtrl,
//                     obscureText: true,
//                     style: const TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                       hintText: 'Enter Password',
//                       hintStyle: TextStyle(color: Colors.grey[400]),
//                       filled: true,
//                       fillColor: Colors.black26,
//                       prefixIcon: const Icon(Icons.key, color: Colors.grey),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12.r),
//                         borderSide: BorderSide.none,
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12.r),
//                         borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 24.h),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () {
//                             Navigator.pop(context); // Close dialog
//                             Navigator.pop(context); // Go back from screen
//                           },
//                           style: OutlinedButton.styleFrom(
//                             padding: EdgeInsets.symmetric(vertical: 12.h),
//                             side: const BorderSide(color: Colors.grey),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12.r),
//                             ),
//                           ),
//                           child: Text(
//                             'Cancel',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 14.sp,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 16.w),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             if (pwdCtrl.text.isNotEmpty) {
//                               Navigator.pop(context);
//                               _chatCtrl.loadMessages(
//                                 widget.chatId,
//                                 password: pwdCtrl.text.trim(),
//                                 onUnlockFailed: () {
//                                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                                     _showUnlockDialog();
//                                   });
//                                 },
//                               );
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content: Text('Password cannot be empty')),
//                               );
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppTheme.primaryBlue,
//                             padding: EdgeInsets.symmetric(vertical: 12.h),
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12.r),
//                             ),
//                           ),
//                           child: Text(
//                             'Unlock',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 14.sp,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }