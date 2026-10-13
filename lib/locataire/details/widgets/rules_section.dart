import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/locataire/details/role.dart';

class RulesSection extends StatelessWidget {
  final Map<String, dynamic>? role;
  final Map<String, dynamic> appartement;
  final Widget dateSelectorSection;

  const RulesSection({
    super.key,
    required this.role,
    required this.appartement,
    required this.dateSelectorSection,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final bool isSmall = width < 380;
        final bool isLarge = width > 700;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall
                ? 12.w
                : isLarge
                ? 30.w
                : 16.w,
            vertical: 16.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // TITRE
              Text(
                "Les règles de l'appartement",
                style: GoogleFonts.poppins(
                  fontSize: isSmall
                      ? 20.sp
                      : isLarge
                      ? 24.sp
                      : 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 10.h),

              // RÈGLES
              if (role != null) ...[
                if (role!['heure_arrive'] != null)
                  _buildRule(
                    icon: Icons.login_rounded,
                    text:
                    'Arrivée à partir de : ${role!['heure_arrive']}',
                    isSmall: isSmall,
                  ),

                if (role!['heure_depart'] != null)
                  _buildRule(
                    icon: Icons.logout_rounded,
                    text:
                    'Départ avant : ${role!['heure_depart']}',
                    isSmall: isSmall,
                  ),

                if (role!['nombre_client'] != null)
                  _buildRule(
                    icon: Icons.people_alt_outlined,
                    text:
                    '${role!['nombre_client']} clients maximum',
                    isSmall: isSmall,
                  ),
              ] else
                Text(
                  'Aucune règle définie',
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 14.sp : 16.sp,
                  ),
                ),

              SizedBox(height: 25.h),

              // SÉLECTEUR DE DATE
              dateSelectorSection,

              SizedBox(height: 15.h),

              // BOUTON
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLarge ? 420.w : double.infinity,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: isSmall ? 46.h : 50.h,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF16522),
                            Color(0xFFC5521B),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE36830)
                                .withValues(alpha: 0.23),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(25.r),
                          ),
                        ),
                        onPressed: role != null
                            ? () {
                          showRulesModal(
                            context: context,
                            appartementRole: role!,
                            appartement: appartement,
                          );
                        }
                            : null,
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Voir plus de détails',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: isSmall
                                      ? 14.sp
                                      : 16.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.arrow_forward,
                              size: isSmall ? 18.sp : 20.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // LIGNE DE RÈGLE
  Widget _buildRule({
    required IconData icon,
    required String text,
    required bool isSmall,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 7.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isSmall ? 17.sp : 19.sp,
            color: const Color(0xFFE85D26),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: isSmall ? 14.sp : 16.sp,
                color: const Color(0xE58A4E1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
