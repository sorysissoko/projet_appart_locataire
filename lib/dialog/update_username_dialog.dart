import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateUsernameDialog extends StatefulWidget {
  const UpdateUsernameDialog({super.key});

  @override
  State<UpdateUsernameDialog> createState() => _UpdateUsernameDialogState();
}

class _UpdateUsernameDialogState extends State<UpdateUsernameDialog> {
  final _formKey = GlobalKey<FormState>();

  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool confirmPasswordVisible = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateNomPrenom() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    final email = user.email;
    if (email == null) throw Exception("Impossible de récupérer l’email");

    final cred =
    EmailAuthProvider.credential(email: email, password: passwordController.text.trim());
    await user.reauthenticateWithCredential(cred);

    await _firestore.collection("users").doc(user.uid).update({
      "nom": nomController.text.trim(),
      "prenom": prenomController.text.trim(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: Color(0xFF4A4AA3),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: Colors.white,
      titlePadding: EdgeInsets.only(top: 20),
      contentPadding: EdgeInsets.all(15),
      title: Center(
        child: Text(
          "Mettre à jour \n Nom et Prénom",
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                SizedBox(height: 16.h),

                TextFormField(
                  controller: nomController,
                  decoration: _inputDecoration("Nom"),
                  validator: (value) =>
                  value!.length < 2 ? 'Nom trop court' : null,
                ),

                SizedBox(height: 16.h),

                TextFormField(
                  controller: prenomController,
                  decoration: _inputDecoration("Prénom"),
                  validator: (value) =>
                  value!.length < 2 ? 'Prénom trop court' : null,
                ),

                SizedBox(height: 16.h),

                TextFormField(
                  controller: passwordController,
                  obscureText: !confirmPasswordVisible,
                  decoration: _inputDecoration("Mot de passe").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                              () => confirmPasswordVisible = !confirmPasswordVisible),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Entrez votre mot de passe'
                      : null,
                ),
              ],
            ),
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
              color: Color(0xFF0004FF),
              letterSpacing: 0.7,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);

            if (!_formKey.currentState!.validate()) return;

            setState(() => isLoading = true);

            try {
              await _updateNomPrenom();
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
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0004FF),
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
              color: Color(0xFFFFFFFF),
            ),
          ),
        ),
      ],
    );
  }
}