import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'appartement_card.dart';

class AppartementSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> apps;
  final Color accentColor;
  final bool isNewSection;
  final VoidCallback onTapAll;
  final Function(Map<String, dynamic>) onTapCard;

  // ✅ AJOUT
  final Map<String, bool> disponibilites;

  const AppartementSection({
    super.key,
    required this.title,
    required this.apps,
    required this.accentColor,
    this.isNewSection = false,
    required this.onTapAll,
    required this.onTapCard,

    // ✅ AJOUT
    this.disponibilites = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width;

    final cardHeight = width < 600
        ? 250.h
        : width < 900
        ? 270.h
        : 285.h;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TITRE
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 8.h,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              GestureDetector(
                onTap: onTapAll,
                child: Text(
                  'Voir tout →',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // CARTES
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
            ),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              final appId = app['id']?.toString() ?? '';

              return Padding(
                padding: EdgeInsets.only(
                  right: 12.w,
                ),
                child: AppartementCard(
                  app: app,
                  isNew: isNewSection,
                  isCompact: false,

                  // ✅ AJOUT
                  isDisponible: disponibilites[appId] ?? false,

                  onTap: () => onTapCard(app),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 12.h),
      ],
    );
  }
}