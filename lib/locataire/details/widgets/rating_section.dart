import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingSection extends StatelessWidget {
  final double average;
  final int count;
  final int? currentRating;
  final VoidCallback onTap;

  const RatingSection({
    super.key,
    required this.average,
    required this.count,
    required this.currentRating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Avis & Expérience",
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 24.sp),
              SizedBox(width: 4.w),
              Text(
                average > 0 ? average.toStringAsFixed(1) : "Aucune note",
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF673A15),
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                "($count avis)",
                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Center(
            child: Container(
              width: 300.w,
              height: 50.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF16522), Color(0xFFC5521B)],
                ),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE36830),
                  foregroundColor: Colors.white,
                  shadowColor: const Color(0x80E36830),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                onPressed: onTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      currentRating != null
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 24.sp,
                      color: Colors.amber,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      currentRating != null
                          ? "Modifier ma note ($currentRating/5)"
                          : "Noter l'appartement",
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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
  }
}