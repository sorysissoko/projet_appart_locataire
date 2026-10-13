import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:service/database_service.dart';
import 'package:service/snackbar_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../locataire/details/models/date_status.dart';
import '../../../reservation/reservation.dart';
import '../../../reservation/price_utils.dart' as price_utils;
import '../../../utils/date_utils.dart';
import '../../../utils/reservation_utils.dart';
import '../utils/reservation_helpers.dart';

class ReservationBottomBar extends StatelessWidget {
  final Map<String, dynamic> appartement;
  final Map<String, dynamic>? disponibilite;
  final Map<String, dynamic>? reservation;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalPrice;
  final int totalNights;
  final DatabaseService databaseService;
  final DateStatus dateStatus;
  final Color statusColor;

  final VoidCallback onCancelReservation;
  final VoidCallback onContactSupport;
  final VoidCallback onDownloadReceipt;
  final VoidCallback onResetAndBookAgain;
  final VoidCallback onOpenRatingDialog;

  const ReservationBottomBar({
    super.key,
    required this.appartement,
    required this.disponibilite,
    required this.reservation,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.totalNights,
    required this.databaseService,
    required this.dateStatus,
    required this.statusColor,
    required this.onCancelReservation,
    required this.onContactSupport,
    required this.onDownloadReceipt,
    required this.onResetAndBookAgain,
    required this.onOpenRatingDialog,
  });

  // ============================================================
  // CONSTANTES
  // ============================================================

  static const Color primaryColor = Color(0xFFE85D26);
  static const Color orangeLight = Color(0xFFF16522);
  static const Color orangeDark = Color(0xFFC5521B);
  static const Color bottomColor = Color(0xFFFFE5CB);

  // BUILD PRINCIPAL
  @override
  Widget build(BuildContext context) {
    if (reservation != null) {
      final status = determineReservationStatus(reservation!);

      switch (status) {
        case ReservationStatus.confirmee:
          return _buildBottomBarLayout(
            context,
            leftWidget: _buildConfirmedWidget(),
            rightWidget: _buildActionButton(
              icon: Icons.file_download_rounded,
              text: 'Reçu',
              onPressed: onDownloadReceipt,
            ),
          );

        case ReservationStatus.enAttente:
          return _buildBottomBarLayout(
            context,
            leftWidget: _buildOutlineButton(
              text: 'Annuler la réservation',
              onPressed: onCancelReservation,
            ),
            rightWidget: _buildActionButton(
              text: 'Contacter',
              onPressed: onContactSupport,
            ),
          );

        case ReservationStatus.terminee:
          return _buildBottomBarLayout(
            context,
            leftWidget: _buildOutlineButton(
              icon: Icons.star_rate_rounded,
              text: 'Laisser un avis',
              onPressed: onOpenRatingDialog,
              color: primaryColor,
            ),
            rightWidget: _buildActionButton(
              text: 'Réserver à nouveau',
              onPressed: onResetAndBookAgain,
            ),
          );

        default:
          return _buildDefaultBottomBar(context);
      }
    }

    return _buildDefaultBottomBar(context);
  }

  // BARRE PAR DÉFAUT
  Widget _buildDefaultBottomBar(BuildContext context) {
    final price = DateUtilsHelper.safeParsePrice(appartement['prix']);

    final nbreSejour =
        appartement['nbre_sejour']?.toString() ?? 'Séjour';

    final bool canReserve = dateStatus == DateStatus.valid;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Petit écran
          final bool isSmall = width < 380;

          // Très grand écran/tablette
          final bool isLarge = width > 700;

          final double horizontalMargin = isLarge
              ? 80.w
              : isSmall
              ? 10.w
              : 15.w;

          final double buttonWidth = isSmall
              ? 145.w
              : isLarge
              ? 230.w
              : 180.w;

          final double containerHeight = isSmall ? 76.h : 80.h;

          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: horizontalMargin,
                vertical: 8.h,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 14.w : 20.w,
                vertical: 8.h,
              ),
              constraints: BoxConstraints(
                minHeight: containerHeight,
                maxHeight: 100.h,
              ),
              decoration: BoxDecoration(
                color: bottomColor,
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ====================================================
                  // PRIX
                  // ====================================================

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Prix / $nbreSejour',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: isSmall ? 11.sp : 13.sp,
                            color: const Color(0xFF9C7A63),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: price_utils.formatPrice(price),
                                  style: GoogleFonts.poppins(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmall ? 18.sp : 22.sp,
                                  ),
                                ),
                                TextSpan(
                                  text: ' Fcfa',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF9C7A63),
                                    fontSize: isSmall ? 12.sp : 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: isSmall ? 8.w : 12.w),

                  // ====================================================
                  // BOUTON RÉSERVER
                  // ====================================================

                  SizedBox(
                    width: buttonWidth,
                    height: isSmall ? 46.h : 52.h,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: dateStatus == DateStatus.valid
                              ? const [
                            orangeLight,
                            orangeDark,
                          ]
                              : [
                            statusColor,
                            statusColor.withValues(alpha: 0.35),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 8.w : 14.w,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        onPressed: canReserve
                            ? () => _reserve(context)
                            : null,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _getButtonText(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: dateStatus == DateStatus.valid
                                  ? (isSmall ? 16.sp : 20.sp)
                                  : (isSmall ? 12.sp : 14.sp),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // RÉSERVER
  // ============================================================

  void _reserve(BuildContext context) {
    final currentUser =
        Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      ReservationHelpers.showAppSnackBar(
        message: 'Vous devez être connecté pour réserver',
        type: SnackBarType.warning,
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

  // ============================================================
  // TEXTE DU BOUTON
  // ============================================================

  String _getButtonText() {
    switch (dateStatus) {
      case DateStatus.conflict:
        return 'Déjà réservé';

      case DateStatus.invalid:
        return 'Dates non autorisées';

      case DateStatus.valid:
        return '🏠 Réserver';

      case DateStatus.none:
        return 'Sélectionnez les dates';
    }
  }

  // ============================================================
  // BARRE POUR RÉSERVATION EXISTANTE
  // ============================================================

  Widget _buildBottomBarLayout(
      BuildContext context, {
        required Widget leftWidget,
        required Widget rightWidget,
      }) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final bool isSmall = width < 400;
          final bool isLarge = width > 700;

          final double horizontalPadding = isSmall
              ? 10.w
              : isLarge
              ? 40.w
              : 16.w;

          final double gap = isSmall ? 8.w : 12.w;

          return Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10.h,
              horizontalPadding,
              10.h,
            ),
            decoration: BoxDecoration(
              color: bottomColor,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, -3),
                ),
              ],
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                // ====================================================
                // BOUTON GAUCHE
                // ====================================================

                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: isSmall ? 44.h : 48.h,
                    child: leftWidget,
                  ),
                ),

                SizedBox(width: gap),

                // ====================================================
                // BOUTON DROIT
                // ====================================================

                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: isSmall ? 44.h : 48.h,
                    child: rightWidget,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CONFIRMÉE
  // ============================================================

  Widget _buildConfirmedWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF51C32F),
            Color(0xFF3D8B40),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 20.sp,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              'Réservation confirmée',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOUTON ACTION
  // ============================================================

  Widget _buildActionButton({
    IconData? icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            orangeLight,
            orangeDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18.sp,
                color: Colors.white,
              ),
              SizedBox(width: 5.w),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OUTLINED BUTTON
  // ============================================================

  Widget _buildOutlineButton({
    IconData? icon,
    required String text,
    required VoidCallback onPressed,
    Color color = Colors.grey,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: color,
          width: 1.5,
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18.sp,
              color: color,
            ),
            SizedBox(width: 5.w),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
