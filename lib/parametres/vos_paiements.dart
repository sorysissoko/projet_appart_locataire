import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/parametre_header.dart';

class VosPaiementsPage extends StatefulWidget {
  const VosPaiementsPage({super.key});

  @override
  State<VosPaiementsPage> createState() => _VosPaiementsPageState();
}

class _VosPaiementsPageState extends State<VosPaiementsPage> {

  // Liste des paiements (vide pour l'instant)
  final List<String> vospaiements = [];

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: Column(
            children: [
              // Header personnalisé avec bouton retour circulaire
              Container(
                padding: EdgeInsets.only(
                  top: 50.h,
                  left: 16.w,
                  right: 16.w,
                  bottom: 16.h,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF2E5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [

                    // Header
                    const ParametreHeader(title: "Modes de paiement"),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icône illustrant l'absence de paiements
                        Icon(
                          Icons.payment_outlined,
                          size: 80.sp,
                          color: const Color(0xFFCCCCCC),
                        ),
                        SizedBox(height: 20.h),

                        // Message principal
                        Text(
                          "Aucun paiement effectué",
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // Description
                        Text(
                          "Vous n'avez pas encore effectué de paiement.",
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: const Color(0xFF999999),
                          ),
                        ),
                        SizedBox(height: 8.h),

                        Text(
                          "Vos transactions apparaîtront ici",
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: const Color(0xFFCCCCCC),
                          ),
                        ),

                        SizedBox(height: 30.h),

                        // Bouton pour effectuer un paiement (optionnel)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A4E1E),
                            minimumSize: Size(200.w, 45.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          onPressed: () {
                            // Naviguer vers une page de paiement ou revenir en arrière
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Effectuer un paiement',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
}