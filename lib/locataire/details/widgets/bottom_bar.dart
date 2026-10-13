import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../reservation/reservation.dart';
import '../../../reservation/liste_reservations.dart' as price_utils;
import '../models/date_status.dart';

class BottomBar extends StatelessWidget {
  final Map<String, dynamic> appartement;
  final Map<String, dynamic> disponibilite;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalPrice;
  final int totalNights;
  final DatabaseService databaseService;
  final DateStatus status;
  final Color statusColor;

  const BottomBar({
    super.key,
    required this.appartement,
    required this.disponibilite,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.totalNights,
    required this.databaseService,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final price = price_utils.safeParsePrice(appartement['prix']);
    final nbreSejour = appartement['nbre_sejour']?.toString() ?? "Séjour";
    bool canReserve = status == DateStatus.valid;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          height: 80.h,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5CB),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE85D26).withValues(alpha: 0.25),
                blurRadius: 5,
                spreadRadius: 1.5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Prix / $nbreSejour",
                      style: GoogleFonts.poppins(fontSize: 13.sp, color: const Color(0xFF9C7A63)),
                    ),
                    SizedBox(height: 2.h),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: price_utils.formatPrice(price),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFE85D26),
                              fontWeight: FontWeight.bold,
                              fontSize: 22.sp,
                            ),
                          ),
                          TextSpan(
                            text: " Fcfa",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF9C7A63),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 180.w,
                height: 52.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: status == DateStatus.valid
                        ? [const Color(0xFFF16522), const Color(0xFFC5521B)]
                        : [statusColor, statusColor.withValues(alpha: 0x5A)],
                  ),
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  onPressed: canReserve
                      ? () {
                    final currentUser = Supabase.instance.client.auth.currentUser;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(bottom: 100.h, left: 20.w, right: 20.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          backgroundColor: const Color(0xFFFF0505),
                          duration: const Duration(seconds: 3),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 40.sp),
                              SizedBox(height: 8.h),
                              Text(
                                'Vous devez être connecté pour réserver',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReservationPage(
                          appartement: appartement,
                          disponibilite: disponibilite,
                          startDate: startDate,
                          endDate: endDate,
                          totalPrice: totalPrice,
                          totalNights: totalNights,
                          databaseService: databaseService,
                        ),
                      ),
                    );
                  }
                      : null,
                  child: Center(
                    child: Text(
                      status == DateStatus.conflict
                          ? "Déjà réservé"
                          : status == DateStatus.invalid
                          ? "Dates non autorisées"
                          : status == DateStatus.valid
                          ? "🏠 Réserver"
                          : "Sélectionnez les dates",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: status == DateStatus.valid ? 20.sp : 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}