import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service/rating/rating_widget.dart';

import '../../../../reservation/liste_reservations.dart';
import '../../widgets/animated_favorite_button.dart';

class AppartementCard extends StatelessWidget {
  final Map<String, dynamic> app;
  final bool isNew;
  final bool isCompact;
  final VoidCallback onTap;

  //Statut de disponibilité passé par le parent
  final bool isDisponible;

  const AppartementCard({
    super.key,
    required this.app,
    this.isNew = false,
    this.isCompact = false,
    required this.onTap,
    this.isDisponible = false,
  });


  // LARGEUR DE LA CARTE

  double _getCardWidth(double screenWidth) {
    if (screenWidth < 360) return 190;
    if (screenWidth < 600) return 205;
    if (screenWidth < 900) return 225;
    return 240;
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final cardWidth = _getCardWidth(screenWidth);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: isCompact ? double.infinity : cardWidth.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                isCompact ? 16.r : 20.r,
              ),
              border: Border.all(
                color: const Color(0xFFFDDBC7),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isCompact
                ? _buildHorizontalLayout(context)
                : _buildVerticalLayout(context, cardWidth),
          ),
        );
      },
    );
  }

  // ============================================================
  // IMAGES
  // ============================================================

  List<String> _getImages() {
    final photoUrls = app['photo_urls'];

    if (photoUrls is List) {
      final urls = photoUrls
          .map((e) => e?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      if (urls.isNotEmpty) return urls;
    }

    final images = app['images'];

    if (images is List) {
      return images
          .map((e) => e?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return [];
  }

  // ============================================================
  // FORMAT VERTICAL
  // ============================================================

  Widget _buildVerticalLayout(
      BuildContext context,
      double cardWidth,
      ) {
    final id = app['id']?.toString() ?? '';
    final images = _getImages();

    final imageHeight =
    MediaQuery.sizeOf(context).width < 600 ? 120.h : 135.h;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(19.r),
          ),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: imageHeight,
                child: _buildImage(images),
              ),

              if (isNew)
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: _buildNewBadge(),
                ),

              Positioned(
                top: 8.h,
                right: 8.w,
                child: AnimatedFavoriteButton(
                  appartementId: id,
                  appartementData: app,
                  iconSize: 24.sp,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: EdgeInsets.all(10.w),
          child: _buildInfo(),
        ),
      ],
    );
  }

  // ============================================================
  // FORMAT HORIZONTAL
  // ============================================================

  Widget _buildHorizontalLayout(BuildContext context) {
    final id = app['id']?.toString() ?? '';
    final images = _getImages();

    final screenWidth = MediaQuery.sizeOf(context).width;

    final imageWidth = screenWidth < 360
        ? 95.w
        : screenWidth < 600
        ? 115.w
        : 140.w;

    final imageHeight = screenWidth < 600 ? 115.h : 130.h;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(16.r),
          ),
          child: SizedBox(
            width: imageWidth,
            height: imageHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildImage(images),
                ),

                Positioned(
                  top: 4.h,
                  left: 4.w,
                  child: AnimatedFavoriteButton(
                    appartementId: id,
                    appartementData: app,
                    iconSize: 18.sp,
                    hasBackground: true,
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
            child: _buildInfo(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IMAGE
  // ============================================================

  Widget _buildImage(List<String> images) {
    if (images.isEmpty) {
      return _errorImage();
    }

    return Image.network(
      images.first,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => _errorImage(),
    );
  }

  Widget _errorImage() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 24.sp,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  // ============================================================
  // BADGE NOUVEAU
  // ============================================================

  Widget _buildNewBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE85D26),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        'Nouveau',
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATIONS
  // ============================================================

  Widget _buildInfo() {
    final price = safeParsePrice(app['prix']);

    final priceText = price > 0
        ? formatPrice(app['prix'])
        : 'Prix non renseigné';

    // ============================================================
// ✅ LOCALISATION — depuis la résidence en priorité
// ============================================================

    String ville = '';
    String adresse = '';

// 1. Essayer depuis la résidence
    final residenceData = app['residence'];

    if (residenceData is Map) {
      ville = residenceData['ville']?.toString().trim() ?? '';
      adresse = residenceData['adresse']?.toString().trim() ?? '';
    }

// 2. Fallback : appartement
    if (ville.isEmpty) {
      ville = app['ville']?.toString().trim() ?? '';
    }

    if (adresse.isEmpty) {
      adresse = app['adresse']?.toString().trim() ?? '';
    }

// 3. Formatage
    final location = (adresse.isNotEmpty && ville.isNotEmpty)
        ? '$adresse, $ville'
        : (ville.isNotEmpty
        ? ville
        : (adresse.isNotEmpty ? adresse : 'Localisation inconnue'));

    // ============================================================
    // ✅ DISPONIBILITÉ — calculée par le parent et passée en paramètre
    // ============================================================

    final disponibiliteTexte =
    isDisponible ? 'Disponible' : 'Indisponible';

    final rating = double.tryParse(
      app['avg_rating']?.toString() ?? '0',
    ) ??
        0.0;

    final ratingCount = int.tryParse(
      app['ratings_count']?.toString() ?? '0',
    ) ??
        0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // TITRE
        // ========================================================

        Text(
          app['titre']?.toString() ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: 4.h),

        // ========================================================
        // LOCALISATION
        // ========================================================

        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 13.sp,
              color: const Color(0xFFE85D26),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: const Color(0xFFA0714A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 5.h),

        // ========================================================
        // DISPONIBILITÉ (badge avec point coloré)
        // ========================================================

        Row(
          children: [
            Container(
              width: 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDisponible
                    ? Colors.green
                    : Colors.red,
              ),
            ),

            SizedBox(width: 5.w),

            Expanded(
              child: Text(
                disponibiliteTexte,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: isDisponible
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 8.h),

        // ========================================================
        // PRIX + NOTE
        // ========================================================

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: priceText,
                      style: GoogleFonts.poppins(
                        fontSize: isCompact ? 15.sp : 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE85D26),
                      ),
                    ),
                    TextSpan(
                      text: ' /${app['nbre_sejour'] ?? ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFA0714A),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 6.w),

            RatingWidget(
              rating: rating,
              count: ratingCount,
              size: 14,
              showCount: true,
            ),
          ],
        ),
      ],
    );
  }
}