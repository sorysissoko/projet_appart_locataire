import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:service/rating/rating_widget.dart';
import '../models/favorite_model.dart';

class FavoriteCard extends StatelessWidget {
  final FavoriteModel favorite;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  // ✅ Correction 1 : Utilisation de "super.key"
  const FavoriteCard({
    super.key,
    required this.favorite,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appartement = favorite.appartement;
    // ✅ Correction 2 : Suppression de la variable inutilisée
    // final appartementId = appartement['id']?.toString() ?? ''; <-- SUPPRIMÉE

    final title = appartement['titre'] ?? 'Titre inconnu';
    final location = appartement['ville'] ?? 'Ville inconnue';
    final num price = safeParsePrice(appartement['prix']);
    final images = (appartement['images'] as List?)?.cast<String>() ?? [];
    final priceText = price > 0 ? formatPrice(price) : "Prix non renseigné";
    final nbreSejour = appartement['nbre_sejour']?.toString() ?? "Séjour";
    final rating = (appartement['avg_rating'] as double?) ?? 0.0;

    DateTime? dateDebut = appartement['date_debut'] != null
        ? DateTime.tryParse(appartement['date_debut'].toString())
        : null;
    DateTime? dateFin = appartement['date_fin'] != null
        ? DateTime.tryParse(appartement['date_fin'].toString())
        : null;
    String disponibility = getDisponibiliteFromDates(dateDebut: dateDebut, dateFin: dateFin);
    bool isAvailable = !disponibility.contains("Indisponible");

    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EC),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFFFDDCF), width: 1.sp),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE85D26).withValues(alpha: 0.04),
            blurRadius: 1,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(24.r),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 180.h,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: images.isNotEmpty && images[0].startsWith('http')
                          ? Image.network(
                        images[0],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFE85D26),
                                  strokeWidth: 2
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        ),
                      )
                          : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.home_work_rounded, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0x6A), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                  // Badge disponibilité
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isAvailable ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isAvailable ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(width: 6.w, height: 6.h, decoration: BoxDecoration(color: isAvailable ? const Color(0xFF10B981) : const Color(0xFFDC2626), shape: BoxShape.circle)),
                          SizedBox(width: 6.w),
                          Text(
                            isAvailable ? "Disponible" : "Indisponible",
                            style: TextStyle(
                              color: isAvailable ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Rating
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: RatingChip(rating: rating, count: rating > 0 ? 1 : 0),
                  ),
                  // Bouton favori (cœur)
                  Positioned(
                    bottom: 12.h,
                    right: 12.w,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Icon(Icons.favorite, size: 30.sp, color: Colors.white),
                      ),
                    ),
                  ),
                  // Titre et localisation
                  Positioned(
                    bottom: 12.h,
                    left: 16.w,
                    right: 16.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: Colors.white.withValues(alpha: 0x8A), size: 12.sp),
                            SizedBox(width: 4.w),
                            Expanded(child: Text(location, style: TextStyle(color: Colors.white.withValues(alpha: 0x8A), fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Footer
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(priceText.split(' ')[0], style: const TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.w900)),
                            SizedBox(width: 2.w),
                            Text("FCFA", style: TextStyle(color: const Color(0xFFFF6B00), fontSize: 11.sp, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text("/$nbreSejour", style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        elevation: 0,
                      ),
                      child: const Text("Voir", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  String formatPrice(num price) {
    final formatter = NumberFormat("#,###", "fr_FR");
    return "${formatter.format(price)} FCFA";
  }

  num safeParsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  String getDisponibiliteFromDates({DateTime? dateDebut, DateTime? dateFin}) {
    if (dateDebut == null || dateFin == null) return "Indisponible";
    final now = DateTime.now();
    final debut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
    final fin = DateTime(dateFin.year, dateFin.month, dateFin.day);
    final today = DateTime(now.year, now.month, now.day);

    if (today.isAfter(fin)) return "Indisponible";
    if (!today.isBefore(debut)) return "Disponible maintenant";
    return "Disponible le ${debut.day.toString().padLeft(2, '0')}/${debut.month.toString().padLeft(2, '0')}/${debut.year}";
  }
}