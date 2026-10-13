import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../utils/reservation_utils.dart';

class ReservationStatusRow extends StatelessWidget {
  final Map<String, dynamic> appartement;
  final Map<String, dynamic>? reservation;
  final List<String> photos;
  final VoidCallback onFavoriteToggle;
  final bool isFavorite;

  const ReservationStatusRow({
    super.key,
    required this.appartement,
    required this.reservation,
    required this.photos,
    required this.onFavoriteToggle,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    ReservationStatus? reservationStatus;
    Map<String, dynamic>? cfg;

    if (reservation != null) {
      reservationStatus = determineReservationStatus(reservation!);
      cfg = getStatusConfig(reservationStatus);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (reservation != null && cfg != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: cfg['bg'],
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: cfg['border'], width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 6.h,
                    decoration: BoxDecoration(color: cfg['dot'], shape: BoxShape.circle),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    cfg['label'],
                    style: GoogleFonts.poppins(
                      color: cfg['text'],
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.share, size: 35.sp),
            onPressed: () async {
              final titre = appartement['titre'] ?? 'Appartement';
              final description = appartement['description'] ?? '';
              final imageUrl = photos.isNotEmpty ? photos.first : '';

              try {
                if (imageUrl.isNotEmpty) {
                  final response = await http.get(Uri.parse(imageUrl));
                  final bytes = response.bodyBytes;
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/appartement.jpg');
                  await file.writeAsBytes(bytes);

                  final textToShare =
                      "$titre\n${description.length > 100 ? '${description.substring(0, 100)}...' : description}";
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(file.path)],
                      text: textToShare,
                      subject: titre,
                    ),
                  );
                } else {
                  await SharePlus.instance.share(
                    ShareParams(
                      text:
                      "$titre\n${description.length > 100 ? '${description.substring(0, 100)}...' : description}",
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Erreur partage: $e');
              }
            },
          ),
          GestureDetector(
            onTap: onFavoriteToggle,
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 35.sp,
              color: isFavorite ? Colors.red : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}