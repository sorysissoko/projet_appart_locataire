import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/custom_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFF2E5),
          body: SafeArea(
            child: Column(
              children: [
                // --- Header personnalisé ---
                const CustomHeader(title: "Paramètres de profile"),
                const SizedBox(height: 20),

                // --- Liste des paramètres scrollable ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          context,
                          icon: Icons.manage_accounts_outlined,
                          title: "Information personnelle",
                          onTap: () {
                            Navigator.pushNamed(context, '/information_personnelle');
                          },
                        ),

                        _buildSettingItem(
                          context,
                          icon: Icons.security,
                          title: "Connexion & sécurité",
                          onTap: () {
                            Navigator.pushNamed(context, '/connexion_securite');
                          },
                        ),

                        _buildSettingItem(
                          context,
                          icon: Icons.lock_outline_rounded,
                          title: "Confidentialité",
                          onTap: () {
                            Navigator.pushNamed(context, '/confidentialite');
                          },
                        ),

                        _buildSettingItem(
                          context,
                          icon: Icons.notifications,
                          title: "Notifications",
                        ),

                        _buildSettingItem(
                          context,
                          icon: Icons.payment,
                          title: "Paiements",
                          onTap: () {
                            Navigator.pushNamed(context, '/paiement_versement');
                          },
                        ),

                        _buildSettingItem(
                          context,
                          icon: Icons.accessibility_new,
                          title: "Accessibilité",
                          onTap: () {
                            Navigator.pushNamed(context, '/accessibilite');
                          },
                        ),
                        const SizedBox(height: 60),
                        Divider(
                          color: Color(0x80E85D26),
                          height: 1.h,
                          thickness: 1.h,
                          indent: 16.w,
                          endIndent: 16.w,
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
                          child: Row(
                            children: [
                              // Titre
                              Text(
                                "Version 71.00.09 (849400) ",
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF8A4E1E),
                                ),
                              ),

                              const SizedBox(height: 16),

                            ],
                          ),
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

  Widget _buildSettingItem(
      BuildContext context, {
        IconData? icon,
        Widget? iconWidget,
        required String title,
        VoidCallback? onTap,
      }) {
    final Color accentColor = const Color(0x80E85D26);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        height: 60.h,
        decoration: BoxDecoration(
          color: Color(0xFFFFF2E5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: accentColor,),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            iconWidget ??
                Icon(
                  icon,
                  size: 30.sp,
                  color: Color (0x80E85D26),
                ),
            SizedBox(width: 15.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Color (0xFF8A4E1E),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Color (0xFF8A4E1E),
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}
