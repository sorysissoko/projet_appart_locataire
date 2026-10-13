import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPasswordWidget extends StatefulWidget {
  const ResetPasswordWidget({super.key});

  static const routeName = '/reset_password';

  @override
  State<ResetPasswordWidget> createState() => _ResetPasswordWidgetState();
}

class _ResetPasswordWidgetState extends State<ResetPasswordWidget> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  String? errorText; // ⚡ Pour afficher l'erreur sous le champ
  bool isLoading = false;
  Widget offsetWidget(Widget child) {
    return Transform.translate(offset: Offset(0, -50.h), child: child);
  }

  Future<void> resetPassword(String email) async {
    setState(() {
      errorText = null;
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email de réinitialisation envoyé !")),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorText = e.message;
      });
    } catch (e) {
      setState(() {
        errorText = "Erreur inconnue : $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF1F4F8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.black, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF0000FF), width: 2),
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
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 35,right: 35),
              child: Form( // ✅ Ajout du Form
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 50.h),

                    // Logo
                    Image.asset(
                      'assets/images/mali_7.png',
                      width: 220.w,
                      height: 90.h,
                      fit: BoxFit.cover,
                    ),

                    SizedBox(height: 20.h),

                    // Titre
                    Text(
                      'Connexion',
                      style: GoogleFonts.poppins(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                        letterSpacing: 1.sp,
                      ),
                    ),

                    SizedBox(height: 70.h),

                    // Email
                    offsetWidget(
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
                    ),

                    SizedBox(height: 5.h),


                    // Bouton Se connecter
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                          if (_formKey.currentState!.validate()) {
                            resetPassword(emailController.text.trim());
                          }
                        },


                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0000FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                          width: 25.w,
                          height: 25.w,
                          child: CircularProgressIndicator(
                              color: Color(0xFFE85D26),
                              strokeWidth: 2
                          ),
                        )
                            : Text(
                          'Envoyez',
                          style: GoogleFonts.poppins(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.3.sp,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15.h),

                  ],
                ),
              ),
            ),

            // Bouton retour fixe
            Positioned(
              top: 20.h,
              left: 15.w,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 55.w,
                  height: 55.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 30.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
