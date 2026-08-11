import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_header.dart';


class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // --- Header personnalisé ---
                const CustomHeader(title: "Centre d'aide"),
                const SizedBox(height: 20),

                // --- Liste des paramètres scrollable ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Column(
                      children: [
                        _buildHelpItem(
                          context,
                          icon: Icons.help_outline_rounded,
                          title: "Visitez le centre d'aide",
                          backgroundColor: const Color(0xD5FFFFFF),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(
      BuildContext context, {
        IconData? icon,
        Widget? iconWidget,
        required String title,
        Widget? page,
        Color? backgroundColor,
      }) {
    return InkWell(
      onTap: () {
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        height: 60.h,
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE4E4E4)),
        ),
        child: Row(
          children: [
            iconWidget ??
                Icon(
                  icon,
                  size: 30.sp,
                  color: Colors.black87,
                ),
            SizedBox(width: 15.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 28.sp,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}
