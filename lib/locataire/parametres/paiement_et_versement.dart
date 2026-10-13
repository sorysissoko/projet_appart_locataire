import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/parametre_header.dart';

class PaiementEtVersementPage extends StatelessWidget {
  const PaiementEtVersementPage({super.key});

  // ============================================================
  // COULEURS (identiques à InformationPersonnellePage)
  // ============================================================

  static const Color _orange = Color(0xFFE85D26);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // --------------------------------------------------
              // HEADER
              // --------------------------------------------------
              const ParametreHeader(title: 'Paiement & versement'),

              // --------------------------------------------------
              // CONTENU
              // --------------------------------------------------
              Padding(
                padding: EdgeInsets.only(
                  top: 150.h,
                  left: 16.w,
                  right: 16.w,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 40.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // SECTION : DÉPLACEMENT
                      // ==================================================

                      _buildSectionTitle('DÉPLACEMENT'),

                      _buildSettingItem(
                        title: 'Modes de paiement',
                        icon: Icons.add_card_rounded,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/mode_paiement',
                          );
                        },
                      ),

                      _buildSettingItem(
                        title: 'Vos paiements',
                        icon: Icons.format_list_bulleted_rounded,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/vos_paiements',
                          );
                        },
                      ),

                      _buildSettingItem(
                        title: 'Coupons',
                        icon: Icons.confirmation_number_outlined,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/coupons',
                          );
                        },
                      ),

                      SizedBox(height: 20.h),

                      // ==================================================
                      // SECTION : SERVICES
                      // ==================================================

                      _buildSectionTitle('SERVICES'),

                      _buildSettingItem(
                        title: 'Modes de retrait',
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: () {
                          // TODO: route
                        },
                      ),

                      _buildSettingItem(
                        title: 'Historique des transactions',
                        icon: Icons.receipt_long_outlined,
                        onTap: () {
                          // TODO: route
                        },
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // TITRE SECTION
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: 5.w,
        bottom: 8.h,
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: _orange,
        ),
      ),
    );
  }

  // ============================================================
  // ITEM (équivalent de _buildEditableItem)
  // ============================================================

  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 7.h),
        padding: EdgeInsets.symmetric(
          horizontal: 13.w,
          vertical: 13.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // ------------------------------------------------
            // ICON BOX
            // ------------------------------------------------
            _buildIconBox(icon),

            SizedBox(width: 12.w),

            // ------------------------------------------------
            // TITRE
            // ------------------------------------------------
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // ------------------------------------------------
            // CHEVRON
            // ------------------------------------------------
            Icon(
              Icons.chevron_right,
              size: 22.sp,
              color: _orange,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ICON BOX
  // ============================================================

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 21.sp,
        color: _orange,
      ),
    );
  }
}