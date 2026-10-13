import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service/auth_service.dart';

class UpdatePwdPageDialog extends StatefulWidget {
  const UpdatePwdPageDialog({super.key});

  @override
  State<UpdatePwdPageDialog> createState() => _UpdatePwdPageDialogState();
}

class _UpdatePwdPageDialogState extends State<UpdatePwdPageDialog> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  bool passwordVisible = false;
  bool newPasswordVisible = false;
  bool confirmNewPasswordVisible = false;

  final _authService = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
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
    );
  }

  Future<void> _updatePwd() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text;
    final oldPassword = passwordController.text;
    final newPassword = newPasswordController.text;

    setState(() => isLoading = true);

    try {
      await _authService.updatePassword(
        email: email,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

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
                style: GoogleFonts.poppins(
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
      title: Text(
        'Mettre à jour votre mot de passe',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1F2937),
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: _inputDecoration("Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez un email';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Entrez un email valide';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Ancien mot de passe
              TextFormField(
                controller: passwordController,
                obscureText: !passwordVisible,
                decoration: _inputDecoration("Mot de passe actuel").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => passwordVisible = !passwordVisible),
                  ),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Entrez votre mot de passe actuel' : null,
              ),
              SizedBox(height: 16.h),

              // Nouveau mot de passe
              TextFormField(
                controller: newPasswordController,
                obscureText: !newPasswordVisible,
                decoration: _inputDecoration("Nouveau mot de passe").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(newPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => newPasswordVisible = !newPasswordVisible),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez un nouveau mot de passe';
                  }
                  if (value.length < 8) {
                    return 'Minimum 8 caractères';
                  }
                  if (value == passwordController.text) {
                    return 'Doit être différent de l’ancien mot de passe';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Confirmation mot de passe
              TextFormField(
                controller: confirmNewPasswordController,
                obscureText: !confirmNewPasswordVisible,
                decoration:
                _inputDecoration("Confirmer le nouveau mot de passe").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(confirmNewPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setState(() =>
                    confirmNewPasswordVisible = !confirmNewPasswordVisible),
                  ),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Annuler",
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF0004FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _updatePwd,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0004FF),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: Color(0xFFE85D26),
                strokeWidth: 2
            ),
          )
              : Text("Mettre à jour", style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    );
  }
}
