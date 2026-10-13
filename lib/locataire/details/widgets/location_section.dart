import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationSection extends StatelessWidget {
  final String ville;
  final String adresse;
  final String? localisation;

  const LocationSection({
    super.key,
    required this.ville,
    required this.adresse,
    this.localisation,
  });

  Future<void> _openMaps() async {
    final url = localisation;

    if (url == null || url.trim().isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url.trim());

    if (uri == null) {
      return;
    }

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('⚠️ Impossible d\'ouvrir : $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocalisation =
        localisation != null && localisation!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ============================================================
        // TITRE
        // ============================================================
        Padding(
          padding: EdgeInsets.only(top: 15.h, left: 15.w, right: 15.w),
          child: Text(
            'Où vous allez être',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ============================================================
        // ADRESSE + VILLE
        // ============================================================
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: const Color(0xFFE36830),
                size: 18.sp,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  '$adresse, $ville, Mali',
                  style: GoogleFonts.poppins(
                    color: const Color(0xE58A4E1E),
                    fontSize: 16.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // ============================================================
        // BOUTON "VOIR SUR LA CARTE"
        // ============================================================
        if (hasLocalisation)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openMaps,
                icon: Icon(
                  Icons.map_outlined,
                  color: const Color(0xFFE36830),
                  size: 20.sp,
                ),
                label: Text(
                  'Voir sur la carte',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFE36830),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFE36830),
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ),

        // ============================================================
        // FALLBACK : image statique si pas de localisation
        // ============================================================
        if (!hasLocalisation) ...[
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Center(
              child: Image.asset(
                'assets/images/map.png',
                height: 250.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250.h,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 50.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'Carte non disponible',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}