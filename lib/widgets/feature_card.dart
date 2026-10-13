import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class FeatureItemData {
  final IconData icon;
  final String label;
  final String value;
  const FeatureItemData(this.icon, this.label, this.value);
}

class FeatureRow extends StatelessWidget {
  final FeatureItemData item;
  const FeatureRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isYes = item.value.toLowerCase() == 'oui';
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 22.sp, color: const Color(0xFFE36830)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF673A15)
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.value,
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isYes ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final List<FeatureItemData> items;
  final double width;
  const FeatureCard({
    super.key,
    required this.title,
    required this.items,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFFF5EC),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0x1A),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 20.h, right: 10.w, left: 15.w, bottom: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0C0C0C),
                ),
              ),
              SizedBox(height: 12.h),
              ...items.map((item) => FeatureRow(item: item)),
            ],
          ),
        ),
      ),
    );
  }
}