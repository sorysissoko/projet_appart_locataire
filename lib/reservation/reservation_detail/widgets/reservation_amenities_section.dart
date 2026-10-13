import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ReservationAmenitiesSection extends StatelessWidget {
  final Map<String, dynamic>? appartementInfo;
  final Map<String, dynamic>? appartementRole;

  const ReservationAmenitiesSection({
    super.key,
    required this.appartementInfo,
    required this.appartementRole,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> amenities = {
      'wifi': {'icon': Icons.wifi, 'label': 'Wi-Fi', 'value': appartementInfo?['internet']},
      'parking': {'icon': Icons.local_parking, 'label': 'Parking', 'value': appartementInfo?['stationnement']},
      'climatisation': {'icon': Icons.ac_unit, 'label': 'Climatisation', 'value': appartementInfo?['climatisation']},
      'meuble': {'icon': Icons.chair, 'label': 'Meublé', 'value': appartementInfo?['meuble']},
      'service': {'icon': Icons.flash_on, 'label': 'Service inclus', 'value': appartementInfo?['service_inclus']},
      'animaux': {'icon': Icons.pets, 'label': 'Animaux acceptés', 'value': appartementRole?['animaux']},
      'fumeur': {'icon': Icons.smoking_rooms, 'label': 'Fumeurs acceptés', 'value': appartementRole?['fumeur']},
    };

    final availableAmenities = amenities.entries.where((entry) {
      final value = entry.value['value'];
      if (value == null) return false;
      final v = value.toString().toLowerCase().trim();
      return v == 'oui' ||
          v == 'true' ||
          v == '1' ||
          v.contains('accept') ||
          v.contains('yes') ||
          v.contains('accepter');
    }).toList();

    if (availableAmenities.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Équipements inclus",
            style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: availableAmenities.map((entry) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(entry.value['icon'], size: 14.sp, color: const Color(0xFFFF6B00)),
                    SizedBox(width: 6.w),
                    Text(entry.value['label'], style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey[700])),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}