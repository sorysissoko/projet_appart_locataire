import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/full_screen_gallery.dart';

class HeaderImage extends StatefulWidget {
  final List<String> photos;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const HeaderImage({
    super.key,
    required this.photos,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  State<HeaderImage> createState() => _HeaderImageState();
}

class _HeaderImageState extends State<HeaderImage> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300.h,
      width: double.infinity,
      child: widget.photos.isNotEmpty
          ? Stack(
        children: [
          PageView.builder(
            itemCount: widget.photos.length,
            onPageChanged: widget.onPageChanged,
            itemBuilder: (context, index) {
              final img = widget.photos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenGallery(
                        photos: widget.photos,
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
                    loadingBuilder: (context, child, progress) {
                      return progress == null
                          ? child
                          : Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFFE85D26),
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  )
                      : Image.asset(
                    img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
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
                color: Colors.black.withValues(alpha: 0x6A),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                "${widget.currentIndex + 1} / ${widget.photos.length}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
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