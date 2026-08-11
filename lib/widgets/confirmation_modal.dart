// widgets/confirmation_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum ConfirmationType {
  logout,
  delete,
  cancel,
  warning,
  info,
}

class ConfirmationModal extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final ConfirmationType type;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final IconData? customIcon;
  final Color? customIconColor;
  final Color? confirmColor;

  const ConfirmationModal({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = 'Confirmer',
    this.cancelText = 'Annuler',
    this.type = ConfirmationType.warning,
    this.onCancel,
    this.customIcon,
    this.customIconColor,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 36.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de drag
          Container(
            width: 40.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 24.h),

          // Icône
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: _getIconBackgroundColor().withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              customIcon ?? _getDefaultIcon(),
              color: customIconColor ?? _getDefaultIconColor(),
              size: 32.sp,
            ),
          ),
          SizedBox(height: 18.h),

          // Titre
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D1F16),
              letterSpacing: -0.01,
            ),
          ),
          SizedBox(height: 10.h),

          // Message
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF7A6E65),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28.h),

          // Boutons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50.h,
                  child: OutlinedButton(
                    onPressed: onCancel ?? () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9F8F7),
                      side: const BorderSide(color: Color(0xFFEAE7E4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: const Color(0xFF5A4A40),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor ?? _getDefaultConfirmColor(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getIconBackgroundColor() {
    switch (type) {
      case ConfirmationType.logout:
      case ConfirmationType.delete:
        return const Color(0xFFEE4444);
      case ConfirmationType.cancel:
        return const Color(0xFFFFA500);
      case ConfirmationType.warning:
        return const Color(0xFFFFA500);
      case ConfirmationType.info:
        return const Color(0xFF2196F3);
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case ConfirmationType.logout:
        return PhosphorIconsFill.signOut;
      case ConfirmationType.delete:
        return PhosphorIconsFill.trash;
      case ConfirmationType.cancel:
        return PhosphorIconsFill.warningCircle;
      case ConfirmationType.warning:
        return PhosphorIconsFill.warningCircle;
      case ConfirmationType.info:
        return PhosphorIconsFill.info;
    }
  }

  Color _getDefaultIconColor() {
    switch (type) {
      case ConfirmationType.logout:
      case ConfirmationType.delete:
        return const Color(0xFFEE4444);
      case ConfirmationType.cancel:
        return const Color(0xFFFFA500);
      case ConfirmationType.warning:
        return const Color(0xFFFFA500);
      case ConfirmationType.info:
        return const Color(0xFF2196F3);
    }
  }

  Color _getDefaultConfirmColor() {
    switch (type) {
      case ConfirmationType.logout:
      case ConfirmationType.delete:
        return const Color(0xFFEE4444);
      case ConfirmationType.cancel:
        return const Color(0xFFFFA500);
      case ConfirmationType.warning:
        return const Color(0xFFFFA500);
      case ConfirmationType.info:
        return const Color(0xFF2196F3);
    }
  }
}

// Fonction utilitaire pour afficher le modal
void showConfirmationModal({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'Confirmer',
  String cancelText = 'Annuler',
  ConfirmationType type = ConfirmationType.warning,
  IconData? customIcon,
  Color? customIconColor,
  Color? confirmColor,
  VoidCallback? onCancel,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.44),
    builder: (modalContext) => ConfirmationModal(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      type: type,
      onConfirm: () {
        if (modalContext.mounted) {
          Navigator.pop(modalContext);
        }
        onConfirm();
      },
      onCancel: onCancel ?? () {
        if (modalContext.mounted) {
          Navigator.pop(modalContext);
        }
      },
      customIcon: customIcon,
      customIconColor: customIconColor,
      confirmColor: confirmColor,
    ),
  );
}