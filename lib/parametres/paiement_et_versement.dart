import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_header.dart';

class PaiementEtVersementPage extends StatelessWidget {
  const PaiementEtVersementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFF2E5),
          body: SafeArea(
            child: Column(
              children: [
                // --- Header personnalisé ---
                const CustomHeader(title: "Paiement & versement"),
                const SizedBox(height: 20),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 35.w),
                  child: Row(
                    children: [
                      // Titre
                      Text(
                        "Déplacement",
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8A4E1E),
                        ),
                      ),

                      const SizedBox(height: 16),

                    ],
                  ),
                ),

                // --- Liste des paramètres scrollable ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          context,
                          icon: Icons.add_card_rounded,
                          title: "Modes de paiement",
                          onTap: () {
                            Navigator.pushNamed(context, '/mode_paiement');
                          },
                        ),

                        _buildSettingItem(
                          context,
                          icon: Icons.format_list_bulleted_rounded,
                          title: "Vos paiements",
                          onTap: () {
                            Navigator.pushNamed(context, '/vos_paiements');
                          },
                        ),

                        _buildSettingItem(
                          context,
                          icon: Icons.confirmation_number_outlined,
                          title: "Coupons",
                          onTap: () {
                            Navigator.pushNamed(context, '/coupons');
                          },
                        ),

                        const SizedBox(height: 40),

                        const Divider(
                          indent: 25,
                          height: 30,
                          thickness: 1,
                          endIndent: 25,
                          color: Color(0x80E85D26),
                        ),

                        const SizedBox(height: 15),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 35.w, vertical: 10.w),
                          child: Row(
                            children: [
                              // Titre
                              Text(
                                "Services",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8A4E1E),
                                ),
                              ),

                              const SizedBox(height: 16),

                            ],
                          ),
                        ),


                        _buildSettingItem(
                          context,
                          icon: Icons.notifications,
                          title: "Modes de retrait",
                        ),

                        _buildSettingItem(
                          context,
                          icon: Icons.payment,
                          title: "Historique des transactions",
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
          color: const Color(0xFFFFF2E5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor),
        ),
        child: Row(
          children: [
            iconWidget ??
                Icon(
                  icon,
                  size: 30.sp,
                  color: Color(0xFF8A4E1E),
                ),
            SizedBox(width: 15.w),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF8A4E1E),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF8A4E1E),
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}
