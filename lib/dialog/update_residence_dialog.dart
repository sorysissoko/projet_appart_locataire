import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service/auth_service.dart';

class UpdateResidenceDialog extends StatefulWidget {
  const UpdateResidenceDialog({super.key});

  @override
  State<UpdateResidenceDialog> createState() => _UpdateResidenceDialogState();
}

class _UpdateResidenceDialogState extends State<UpdateResidenceDialog> {
  final _formKey = GlobalKey<FormState>();
  final adresseController = TextEditingController();
  bool isLoading = false;

  final _authService = AuthService();

  @override
  void dispose() {
    adresseController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF4A4AA3),
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF4F50B6), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF0004FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Future<void> _updateAdresseResidence() async {

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await _authService.updateAdresseSimple(adresseController.text.trim());

      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 300.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          backgroundColor: const Color(0xCB0000FF),
          duration: const Duration(seconds: 3),
          content: Column(
            mainAxisSize: MainAxisSize.min, // adapte la taille à son contenu
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 40.sp), // ✅ Icône
              SizedBox(height: 8.h),
              Text(
                'Modifier !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 300.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: Colors.white,
      titlePadding: const EdgeInsets.only(top: 20),
      contentPadding: const EdgeInsets.all(15),
      title: Center(
        child: Text(
          "Mettre à jour \nAdresse de Residence",
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF000000),
          ),
        ),
      ),
      content: SizedBox(
        width: 400.w,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16.h),
              TextFormField(
                controller: adresseController,
                decoration: _inputDecoration("Adresse"),
                validator: (value) =>
                (value == null || value.trim().length < 2)
                    ? 'Adresse trop courte'
                    : null,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
          child: Text(
            "Annuler",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0004FF),
              letterSpacing: 0.7,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _updateAdresseResidence,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0004FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
          child: isLoading
              ? SizedBox(
            width: 20.w,
            height: 20.h,
            child: CircularProgressIndicator(
                color: Color(0xFFE85D26),
                strokeWidth: 2
            ),
          )
              : Text(
            "Mettre à jour",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
