import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:service/rating/rating_widget.dart';
import '../../../details/appartement_detail_page.dart';
import '../../../reservation/liste_reservations.dart' hide safeParsePrice;
import '../../../utils/formatters.dart' hide safeParsePrice, formatPrice;
import '../../widgets/animated_favorite_button.dart';

class AppartementCard extends StatelessWidget {
  final Map<String, dynamic> app;
  final bool isNew;
  final bool isCompact;
  final VoidCallback onTap;

  const AppartementCard({
    super.key,
    required this.app,
    this.isNew = false,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Plus de variables inutilisées ici !
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isCompact ? double.infinity : 205.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isCompact ? 16.r : 20.r),
          border: Border.all(color: const Color(0xFFFDDBC7), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isCompact ? _buildHorizontalLayout() : _buildVerticalLayout(),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    final id = app['id'].toString();
    final images = (app['images'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          // ✅ CORRECTION 1 : Suppression du 'const' car .r est dynamique
          borderRadius: BorderRadius.vertical(top: Radius.circular(19.r)),
          child: Stack(
            children: [
              SizedBox(width: 205.w, height: 120.h, child: _buildImage(images)),
              if (isNew) Positioned(top: 8, left: 8, child: _buildNewBadge()),
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedFavoriteButton(
                  appartementId: id, // ✅ Utilisation de la variable 'id'
                  appartementData: app,
                  iconSize: 24.sp,
                ),
              ),
            ],
          ),
        ),
        Padding(padding: EdgeInsets.all(10.w), child: _buildInfo()),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    final id = app['id'].toString();
    final images = (app['images'] as List?)?.cast<String>() ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          // ✅ CORRECTION 2 : Suppression du 'const' car .r est dynamique
          borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
          child: Stack(
            children: [
              SizedBox(width: 115.w, height: 115.h, child: _buildImage(images)),
              Positioned(
                top: 4,
                left: 4,
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
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: _buildInfo(),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(List<String> images) {
    return images.isNotEmpty
        ? Image.network(
      images[0],
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _errorImage(),
    )
        : _errorImage();
  }

  Widget _errorImage() => Container(
    color: Colors.grey.shade100,
    child: Icon(
      Icons.broken_image_outlined,
      size: 24.sp,
      color: Colors.grey.shade400,
    ),
  );

  Widget _buildNewBadge() => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: const Color(0xFFE85D26),
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Text(
      "Nouveau",
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  Widget _buildInfo() {
    final priceText = safeParsePrice(app['prix']) > 0
        ? formatPrice(app['prix'])
        : "Prix non renseigné";
    final isCompact = this.isCompact;
    final location = (app['adresse'] as String? ?? '').isNotEmpty
        ? '${app['ville']}, ${app['adresse']}'
        : app['ville'];

    DateTime? dateDebut = app['date_debut'] != null
        ? DateTime.tryParse(app['date_debut'].toString())
        : null;
    DateTime? dateFin = app['date_fin'] != null
        ? DateTime.tryParse(app['date_fin'].toString())
        : null;
    String disponibility =
    getDisponibiliteFromDates(dateDebut: dateDebut, dateFin: dateFin);
    bool isAvailable = !disponibility.contains("Indisponible");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          app['titre'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isCompact ? 14.sp : 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 13.sp, color: const Color(0xFFE85D26)),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                location,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFFA0714A),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        Row(
          children: [
            Container(
              width: 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAvailable ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                disponibility,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: priceText,
                    style: TextStyle(
                      fontSize: isCompact ? 15.sp : 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE85D26),
                    ),
                  ),
                  TextSpan(
                    text: " /${app['nbre_sejour']}",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFA0714A),
                    ),
                  ),
                ],
              ),
            ),
            RatingWidget(
              rating: (app['avg_rating'] ?? 0.0).toDouble(),
              count: app['ratings_count'] ?? 0,
              size: 14,
              showCount: true,
            ),
          ],
        ),
      ],
    );
  }
}