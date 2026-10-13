import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/full_screen_gallery.dart';

class ReservationHeader extends StatelessWidget {
  final List<String> photos;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final String adresse;
  final VoidCallback onGalleryTap;

  const ReservationHeader({
    super.key,
    required this.photos,
    required this.currentIndex,
    required this.onPageChanged,
    required this.adresse,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300.h,
      width: double.infinity,
      child: photos.isNotEmpty
          ? Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final img = photos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenGallery(
                        photos: photos,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: img.startsWith('http')
                      ? Image.network(
                    img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFFE85D26),
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    ),
                  )
                      : Image.asset(
                    img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 60.h,
            right: 20.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.41),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                "${currentIndex + 1} / ${photos.length}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            left: 15.w,
            bottom: 60.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 18),
                  SizedBox(width: 5.w),
                  Text(
                    adresse,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
          : Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
      ),
    );
  }
}