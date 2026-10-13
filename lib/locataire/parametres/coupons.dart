import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../widgets/parametre_header.dart';


class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  final List<Coupon> _coupons = [];
  final TextEditingController _couponController = TextEditingController();

  // Liste de coupons prédéfinis pour la démonstration
  final Map<String, CouponInfo> _validCoupons = {
    'WELCOME20': CouponInfo(
      discount: 20,
      description: '20% de réduction sur votre première course',
      expiryDate: '31/12/2024',
    ),
    'SAVE10': CouponInfo(
      discount: 10,
      description: '10€ de réduction',
      expiryDate: '30/11/2024',
    ),
    'FREE15': CouponInfo(
      discount: 15,
      description: '15% de réduction',
      expiryDate: '15/12/2024',
    ),
  };

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _showAddCouponDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            "Ajouter un coupon",
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8A4E1E),
            ),
          ),
          content: TextField(
            controller: _couponController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: "Code du coupon",
              hintText: "Ex: WELCOME20",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFF8A4E1E), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _couponController.clear();
                Navigator.pop(ctx);
              },
              child: Text(
                "Annuler",
                style: GoogleFonts.inter(
                  color: const Color(0xFF999999),
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A4E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              onPressed: () => _addCoupon(ctx),
              child: Text(
                "Ajouter",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addCoupon(BuildContext ctx) {
    String code = _couponController.text.trim().toUpperCase();

    if (code.isEmpty) {
      _showSnackBar("Veuillez entrer un code de coupon", Colors.orange);
      return;
    }

    // Vérifier si le coupon existe déjà
    if (_coupons.any((coupon) => coupon.code == code)) {
      _showSnackBar("Ce coupon a déjà été ajouté ❌", Colors.red);
      _couponController.clear();
      Navigator.pop(ctx);
      return;
    }

    // Vérifier si le coupon est valide
    CouponInfo? couponInfo = _validCoupons[code];
    if (couponInfo != null) {
      setState(() {
        _coupons.add(Coupon(
          code: code,
          discount: couponInfo.discount,
          description: couponInfo.description,
          expiryDate: couponInfo.expiryDate,
        ));
      });
      _couponController.clear();
      Navigator.pop(ctx);
      _showSnackBar("Coupon ajouté avec succès ! 🎉", Colors.green);
    } else {
      _showSnackBar("Code de coupon invalide ❌", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  void _removeCoupon(int index) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            "Retirer le coupon",
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Voulez-vous vraiment retirer ce coupon ?",
            style: GoogleFonts.inter(fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Annuler",
                style: GoogleFonts.inter(color: const Color(0xFF999999)),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _coupons.removeAt(index);
                });
                Navigator.pop(ctx);
                _showSnackBar("Coupon retiré", Colors.orange);
              },
              child: Text(
                "Retirer",
                style: GoogleFonts.inter(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFF2E5),
          body: Column(
            children: [
              // ✅ CORRECTED: Header with proper title
              const ParametreHeader(title: "Mes Coupons"),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistiques des coupons
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF8A4E1E).withValues(alpha: 0.1),
                              const Color(0xFF8A4E1E).withValues(alpha:0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFF8A4E1E).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coupons disponibles',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF8A4E1E),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${_coupons.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF8A4E1E),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8A4E1E).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.local_offer,
                                size: 32.sp,
                                color: const Color(0xFF8A4E1E),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Bouton "Ajouter un coupon"
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A4E1E),
                            minimumSize: Size(200.w, 50.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _showAddCouponDialog,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 20.sp, color: Colors.white),
                              SizedBox(width: 8.w),
                              Text(
                                'Ajouter un coupon',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Liste des coupons
                      if (_coupons.isEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Column(
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                size: 64.sp,
                                color: const Color(0xFFCCCCCC),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Aucun coupon pour le moment',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  color: const Color(0xFF999999),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Ajoutez un coupon pour profiter de réductions',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: const Color(0xFFCCCCCC),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
                              child: Text(
                                'Mes coupons actifs',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8A4E1E),
                                ),
                              ),
                            ),
                            ..._coupons.asMap().entries.map((entry) {
                              int index = entry.key;
                              Coupon coupon = entry.value;
                              return _buildCouponCard(coupon, index);
                            }),
                          ],
                        ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponCard(Coupon coupon, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF2E5),
            const Color(0xFFFFE8D9),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE85D26).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Décoration de coupon (ligne pointillée)
          Positioned(
            right: 80.w,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1.w,
              color: const Color(0xFFE85D26).withValues(alpha: 0.3),
            ),
          ),

          Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Zone de réduction
                Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A4E1E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${coupon.discount}',
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8A4E1E),
                          ),
                        ),
                        Text(
                          coupon.discount >= 20 ? '%' : '€',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8A4E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Informations du coupon
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.code,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8A4E1E),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        coupon.description,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12.sp,
                            color: const Color(0xFF999999),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Expire le ${coupon.expiryDate}',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bouton supprimer
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20.sp,
                    color: const Color(0xFFCCCCCC),
                  ),
                  onPressed: () => _removeCoupon(index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Modèles de données
class Coupon {
  final String code;
  final int discount;
  final String description;
  final String expiryDate;

  Coupon({
    required this.code,
    required this.discount,
    required this.description,
    required this.expiryDate,
  });
}

class CouponInfo {
  final int discount;
  final String description;
  final String expiryDate;

  CouponInfo({
    required this.discount,
    required this.description,
    required this.expiryDate,
  });
}