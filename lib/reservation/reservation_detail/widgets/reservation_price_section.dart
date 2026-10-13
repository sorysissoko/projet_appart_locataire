import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../price_utils.dart' as price_utils;

class ReservationPriceSection extends StatelessWidget {
  final int totalNights;
  final double totalPrice;
  final double pricePerNight;
  final Map<String, dynamic>? appartement;
  final Map<String, dynamic>? reservation;

  const ReservationPriceSection({
    super.key,
    required this.totalNights,
    required this.totalPrice,
    required this.pricePerNight,
    required this.appartement,
    required this.reservation,
  });

  @override
  Widget build(BuildContext context) {
    if (reservation == null) return const SizedBox.shrink();

    final prixProprietaire = double.tryParse(
      appartement?['prix_proprietaire']?.toString() ?? '0',
    ) ?? 0.0;
    final fraisService = double.tryParse(
      appartement?['frais_service']?.toString() ?? '0',
    ) ?? 0.0;

    final reductions = price_utils.calculerPrixAvecReduction(
      prixProprietaire: prixProprietaire,
      fraisService: fraisService,
      nuits: totalNights,
    );

    final reductionProprio = reductions['reductionProprietaire']!;
    final reductionService = reductions['reductionService']!;
    final totalProprioAvant = prixProprietaire * totalNights;
    final totalServiceAvant = fraisService * totalNights;
    final fraisDuProApres = totalProprioAvant - reductionProprio;
    final fraisServiceApres = totalServiceAvant - reductionService;

    final prixSansReduction = pricePerNight * totalNights;
    final economie = prixSansReduction - totalPrice;

    Widget buildPriceRow(String label, String value, {bool isTotal = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isTotal ? 16.sp : 14.sp,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? Colors.black : Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: isTotal ? 18.sp : 14.sp,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? const Color(0xFFFF6B00) : Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(
            "Détail du prix",
            style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
          SizedBox(height: 16.h),
          buildPriceRow('Nuitées', '$totalNights nuit${totalNights > 1 ? 's' : ''}'),
          buildPriceRow('Prix par nuit', price_utils.formatPrice(pricePerNight)),
          buildPriceRow('Sous-total', price_utils.formatPrice(prixSansReduction)),
          if (economie > 0)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Réduction', style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.green)),
                  Text(
                    '- ${price_utils.formatPrice(economie)}',
                    style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          buildPriceRow('Frais du propriétaire', price_utils.formatPrice(fraisDuProApres)),
          buildPriceRow('Frais de service', price_utils.formatPrice(fraisServiceApres)),
          Divider(color: Colors.grey[200], height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price_utils.formatPrice(totalPrice),
                      style: GoogleFonts.poppins(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFFFF7B32)),
                    ),
                    Container(height: 3, color: const Color(0xFFFF7B32)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4ED),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, size: 16, color: Color(0xFFFF6B00)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text("Paiement à l'arrivée", style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[600])),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text("En espèces", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}