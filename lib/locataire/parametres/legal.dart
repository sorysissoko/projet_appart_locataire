import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/custom_header.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

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
                const CustomHeader(title: "Légal"),

                // --- Liste des paramètres scrollable ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Column(
                      children: [
                        _buildLegalItem(
                          context,
                          icon: Icons.description_outlined,
                          title: "Conditions d'utilisation",
                          backgroundColor: const Color(0xD5FFFFFF),
                          onTap: () {
                            Navigator.pushNamed(context, '/conditions');
                          },
                        ),

                        _buildLegalItem(
                          context,
                          icon: Icons.description_outlined,
                          title: "politique de confidentialité",
                          backgroundColor: const Color(0xD5FFFFFF),
                          onTap: () {
                            Navigator.pushNamed(context, '/politiques');
                          },
                        ),

                        _buildLegalItem(
                          context,
                          icon: Icons.auto_stories_outlined,
                          title: "Licences open source",
                          backgroundColor: const Color(0xD5FFFFFF),
                          onTap: () {
                            Navigator.pushNamed(context, '/licence');
                          },
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

  Widget _buildLegalItem(
      BuildContext context, {
        IconData? icon,
        Widget? iconWidget,
        required String title,
        Widget? page,
        VoidCallback? onTap,
        Color? backgroundColor,
        List<Widget>? actions,
      }) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap(); // ✅ priorité au onTap
        } else if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
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
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),

            if (actions != null) ...actions,

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
