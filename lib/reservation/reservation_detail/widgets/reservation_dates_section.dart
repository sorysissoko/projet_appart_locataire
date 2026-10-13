import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/date_utils.dart';
import '../../../utils/reservation_utils.dart';

class ReservationDatesSection extends StatelessWidget {
  final Map<String, dynamic>? reservation;
  final int totalNights;
  final VoidCallback onModifyDates;
  final bool canModify;

  const ReservationDatesSection({
    super.key,
    required this.reservation,
    required this.totalNights,
    required this.onModifyDates,
    required this.canModify,
  });

  @override
  Widget build(BuildContext context) {
    final checkIn = reservation?['check_in']?.toString() ?? '14:00';
    final checkOut = reservation?['check_out']?.toString() ?? '12:00';
    final nights = reservation?['nuits']?.toString() ?? totalNights.toString();

    final dateDebut = reservation?['date_debut'] != null
        ? DateTime.tryParse(reservation!['date_debut'].toString())
        : null;

    final status = reservation != null ? determineReservationStatus(reservation!) : null;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5EC),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Dates du séjour",
                    style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                  ),
                  if (canModify)
                    GestureDetector(
                      onTap: onModifyDates,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE36830),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 14.sp, color: Colors.white),
                            SizedBox(width: 4.w),
                            Text(
                              "Modifier",
                              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4ED),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFFF6B00), width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Arrivée", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[500])),
                            SizedBox(height: 4.h),
                            Text(
                              DateUtilsHelper.formatDateLong(reservation?['date_debut']?.toString()),
                              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.grey[900]),
                            ),
                            SizedBox(height: 4.h),
                            Text("à partir de $checkIn", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60.w,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text("$nights nuits", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Départ", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[500])),
                            SizedBox(height: 4.h),
                            Text(
                              DateUtilsHelper.formatDateLong(reservation?['date_fin']?.toString()),
                              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.grey[900]),
                            ),
                            SizedBox(height: 4.h),
                            Text("avant $checkOut", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (status != ReservationStatus.terminee && dateDebut != null) _buildCancellationInfo(dateDebut),
        if (status == ReservationStatus.terminee)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    '✅ Séjour terminé',
                    style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCancellationInfo(DateTime startDate) {
    final freeCancelDate = startDate.subtract(const Duration(days: 2));
    final now = DateTime.now();
    final isFree = now.isBefore(freeCancelDate);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isFree ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isFree ? Colors.green.shade300 : Colors.orange.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFree ? Icons.check_circle_outline : Icons.info_outline,
            color: isFree ? Colors.green : Colors.orange,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFree ? '✅ Annulation gratuite' : '⚠️ Annulation avec frais',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isFree ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isFree
                      ? 'Annulation gratuite jusqu\'au ${DateUtilsHelper.formatDateFrench(freeCancelDate)}'
                      : 'L\'annulation est gratuite jusqu\'au ${DateUtilsHelper.formatDateFrench(freeCancelDate)}. Passé cette date, des frais peuvent s\'appliquer.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: isFree ? Colors.green.shade600 : Colors.orange.shade700,
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