import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class StatusRow extends StatelessWidget {
  final bool isDisponible;
  final String appartementId;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final List<String> photos;
  final String titre;
  final String description;

  const StatusRow({
    super.key,
    required this.isDisponible,
    required this.appartementId,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.photos,
    required this.titre,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Chip(
            label: Text(
              isDisponible ? 'Disponible' : 'Indisponible',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
            backgroundColor: isDisponible ? const Color(0xFF51C32F) : const Color(0xFF8A0000),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          ),
          SizedBox(width: 60.w),
          IconButton(
            icon: Icon(Icons.share, size: 30.sp),
            onPressed: () async {
              try {
                final imageUrl = photos.isNotEmpty ? photos.first : '';

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