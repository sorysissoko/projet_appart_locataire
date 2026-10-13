import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/date_utils.dart';
import '../models/date_status.dart';

class DateSelectorSection extends StatelessWidget {
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final int totalNights;
  final double totalPrice;
  final double pricePerNight;
  final double totalReduction;
  final DateStatus status;
  final Color statusColor;
  final String statusMessage;
  final VoidCallback onTap;

  const DateSelectorSection({
    super.key,
    required this.selectedStartDate,
    required this.selectedEndDate,
    required this.totalNights,
    required this.totalPrice,
    required this.pricePerNight,
    required this.totalReduction,
    required this.status,
    required this.statusColor,
    required this.statusMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDates =
        selectedStartDate != null &&
            selectedEndDate != null &&
            totalNights > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================================
        // DATES DE SÉJOUR
        // ==========================================================

        Text(
          'Dates de séjour',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF673A15),
          ),
        ),

        SizedBox(height: 12.h),

        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 16.h,
              horizontal: 20.w,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFFFFC189),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: const Color(0xFFE36830),
                  size: 26.sp,
                ),

                SizedBox(width: 15.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDates
                            ? '${DateUtilsHelper.formatDateShortFR(selectedStartDate!)} → ${DateUtilsHelper.formatDateShortFR(selectedEndDate!)}'
                            : 'Sélectionnez vos dates',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF673A15),
                        ),
                      ),

                      if (hasDates)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            statusMessage,
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  size: 18.sp,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),

        // ==========================================================
        // DÉTAIL DU PRIX
        // ==========================================================

        if (hasDates) ...[
          SizedBox(height: 12.h),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFFE8C7A8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // TITRE
                // ==================================================

                Text(
                  'Détail du prix',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF673A15),
                  ),
                ),

                SizedBox(height: 14.h),

                // ==================================================
                // MESSAGE DE CONFLIT
                // ==================================================

                if (status == DateStatus.conflict)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 18.sp,
                          ),

                          SizedBox(width: 8.w),

                          Expanded(
                            child: Text(
                              statusMessage,
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ==================================================
                // NUITS
                // ==================================================

                _buildPriceLine(
                  label: 'nuits',
                  value: totalNights.toDouble(),
                  showCurrency: false,
                ),

                SizedBox(height: 6.h),

                // ==================================================
                // PRIX PUBLIC PAR NUIT
                // ==================================================

                _buildPriceLine(
                  label: 'Prix par nuit',
                  value: pricePerNight,
                ),

                // ==================================================
                // RÉDUCTION
                // ==================================================

                if (totalReduction > 0) ...[
                  SizedBox(height: 6.h),

                  _buildPriceLine(
                    label: 'Réduction',
                    value: -totalReduction,
                    isReduction: true,
                  ),
                ],

                SizedBox(height: 12.h),

                const Divider(
                  color: Color(0xFFE0BFA0),
                  height: 1,
                ),

                SizedBox(height: 12.h),

                // ==================================================
                // TOTAL
                // ==================================================

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.poppins(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF673A15),
                      ),
                    ),

                    Text(
                      '${_formatPrice(totalPrice)} FCFA',
                      style: GoogleFonts.poppins(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE85D26),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==============================================================
  // LIGNE DU DÉTAIL DU PRIX
  // ==============================================================

  Widget _buildPriceLine({
    required String label,
    required double value,
    bool isReduction = false,
    bool isBold = false,
    bool showCurrency = true,
  }) {
    final String formattedValue = value < 0
        ? '- ${_formatPrice(value.abs())}'
        : _formatPrice(value.abs());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight:
              isBold ? FontWeight.w700 : FontWeight.w400,
              color: isReduction
                  ? const Color(0xFF2E8B57)
                  : const Color(0xFF673A15),
            ),
          ),
        ),

        SizedBox(width: 10.w),

        Text(
          showCurrency
              ? '$formattedValue FCFA'
              : formattedValue,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight:
            isBold ? FontWeight.w700 : FontWeight.w500,
            color: isReduction
                ? const Color(0xFF2E8B57)
                : const Color(0xFF673A15),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // FORMAT PRIX
  // ==============================================================

  String _formatPrice(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
    );
  }
}