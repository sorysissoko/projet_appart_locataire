import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'appartement_card.dart'; // Assurez-vous que ce fichier existe et est importé

class AppartementSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> apps;
  final Color accentColor;
  final bool isNewSection;
  final VoidCallback onTapAll;
  final Function(Map<String, dynamic>) onTapCard;

  const AppartementSection({
    super.key,
    required this.title,
    required this.apps,
    required this.accentColor,
    this.isNewSection = false,
    required this.onTapAll,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: onTapAll,
                child: Text(
                  "Voir tout →",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: AppartementCard(
                  app: app,
                  isNew: isNewSection,
                  isCompact: false, // C'est le format vertical/horizontal
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