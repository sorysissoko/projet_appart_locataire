import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:service/auth_service.dart';
import 'package:service/logger.dart';
import 'package:service/snackbar_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// TYPES SNACKBAR
enum SnackBarType {
  success,
  error,
  warning,
  info,
}

// REGISTER PAGE
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // FORM
  final _formKey = GlobalKey<FormState>();

  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final villeController = TextEditingController();

  // COULEURS
  static const Color _accentColor = Color(0xFFE85D26);
  static const Color _backgroundColor = Color(0xFFFFEFE0);
  static const Color _textColor = Color(0xFF8A4E1E);
  static const Color _borderColor = Color(0xFFFDDBC7);
  static const Color _fieldColor = Color(0xB3FFFFFF);

  // ETAT
  DateTime? selectedDate;

  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool checkboxValue = false;
  bool isLoading = false;

  String? checkboxError;
  String? completePhoneNumber;
  String? countryCode;

  // DISPOSE
  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    villeController.dispose();

    super.dispose();
  }

  // SNACKBAR
  void _showAppSnackBar({
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    switch (type) {
      case SnackBarType.success:
        SnackBarService().showSuccess(
          message,
          duration: duration,
        );
        break;

      case SnackBarType.error:
        SnackBarService().showError(
          message,
          duration: duration,
        );
        break;

      case SnackBarType.warning:
        SnackBarService().showWarning(
          message,
          duration: duration,
        );
        break;

      case SnackBarType.info:
        SnackBarService().showInfo(
          message,
          duration: duration,
        );
        break;
    }
  }

  // ERREURS AUTH
  String _getAuthErrorMessage(AuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet e-mail est déjà utilisé. Connectez-vous !';

      case 'invalid-email':
        return 'Adresse e-mail invalide.';

      case 'weak-password':
        return 'Mot de passe trop faible.';

      case 'user-not-found':
        return 'Utilisateur non trouvé.';

      case 'wrong-password':
        return 'Mot de passe incorrect.';

      default:
        return 'Erreur lors de l\'inscription : ${e.message}';
    }
  }

  String _getGenericErrorMessage(dynamic e) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('already exists') ||
        errorString.contains('user already registered')) {
      return 'Cet e-mail est déjà utilisé.';
    }

    if (errorString.contains('row-level security') ||
        errorString.contains('rls')) {
      return 'Erreur de sécurité. Contactez le support.';
    }

    if (errorString.contains('invalid credentials') ||
        errorString.contains('password')) {
      return 'Email ou mot de passe non valide.';
    }

    if (errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection')) {
      return 'Problème de connexion réseau.';
    }

    if (errorString.contains('telephone') ||
        errorString.contains('phone')) {
      return 'Numéro de téléphone invalide.';
    }

    return 'Erreur lors de l\'inscription. Veuillez réessayer.';
  }

  // AGE
  bool _isAtLeast19YearsOld(DateTime birthDate) {
    final today = DateTime.now();

    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month &&
            today.day < birthDate.day)) {
      age--;
    }

    return age >= 19;
  }

  // DATE
  Future<void> _selectDate(BuildContext context) async {
    final today = DateTime.now();

    final maximumBirthDate = DateTime(
      today.year - 19,
      today.month,
      today.day,
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maximumBirthDate,
      firstDate: DateTime(1900),
      lastDate: maximumBirthDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accentColor,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    if (!_isAtLeast19YearsOld(picked)) {
      _showAppSnackBar(
        message:
        'Vous devez avoir au moins 19 ans pour vous inscrire.',
        type: SnackBarType.warning,
      );

      return;
    }

    setState(() {
      selectedDate = picked;
    });
  }

  // INSCRIPTION
  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // TELEPHONE
    if (completePhoneNumber == null ||
        completePhoneNumber!.isEmpty) {
      _showAppSnackBar(
        message: '📱 Veuillez entrer votre numéro de téléphone.',
        type: SnackBarType.error,
      );

      return;
    }

    // DATE
    if (selectedDate == null) {
      _showAppSnackBar(
        message: '📅 Veuillez sélectionner votre date de naissance.',
        type: SnackBarType.error,
      );

      return;
    }

    if (!_isAtLeast19YearsOld(selectedDate!)) {
      _showAppSnackBar(
        message:
        '⚠️ Vous devez avoir au moins 19 ans pour vous inscrire.',
        type: SnackBarType.warning,
      );

      return;
    }

    // CONDITIONS
    if (!checkboxValue) {
      setState(() {
        checkboxError =
        'Vous devez accepter les conditions';
      });

      _showAppSnackBar(
        message: '📜 Acceptez les conditions pour continuer.',
        type: SnackBarType.warning,
      );

      return;
    }

    // LOADING
    setState(() {
      isLoading = true;
      checkboxError = null;
    });

    try {
      final nom = nomController.text.trim();
      final prenom = prenomController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text;
      final ville = villeController.text.trim();

      final dateNaissance =
          selectedDate!.toIso8601String().split('T').first;

      logger.i('🚀 DÉBUT INSCRIPTION');

      // SUPABASE
      await AuthService().signUpWithEmailPassword(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        telephone: completePhoneNumber!,
        adresse: '',
        ville: ville,
        dateNaissance: dateNaissance,
        role: 'locataire',
      );

      if (!mounted) return;

      _showAppSnackBar(
        message:
        '🎉 Inscription réussie !\nBienvenue $prenom $nom',
        type: SnackBarType.success,
      );

      logger.i(
        'Inscription réussie : $email',
      );

      await Future.delayed(
        const Duration(milliseconds: 600),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/main',
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showAppSnackBar(
        message: _getAuthErrorMessage(e),
        type: SnackBarType.error,
      );

      logger.e(
        'AuthException: ${e.code} - ${e.message}',
      );
    } catch (e) {
      if (!mounted) return;

      _showAppSnackBar(
        message: _getGenericErrorMessage(e),
        type: SnackBarType.error,
      );

      logger.e(
        'Erreur inscription : $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            _buildLogo(),

            SizedBox(height: 10.h),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),

                    SizedBox(height: 24.h),

                    _buildForm(),

                    SizedBox(height: 8.h),

                    _buildTermsCheckbox(),

                    SizedBox(height: 32.h),

                    _buildButtons(),

                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 8.h,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE5CE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                size: 20.sp,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LOGO
  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        'assets/images/logo_appart3.png',
        fit: BoxFit.contain,
        height: 80.h,
      ),
    );
  }

  // TITRE
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎉 Rejoignez-nous !',
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: 8.h),

        Text(
          'Créez votre compte et découvrez le Mali !',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  // FORMULAIRE
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            label: 'NOM',
            hint: 'Votre nom',
            icon: Icons.person_outline,
            controller: nomController,
          ),

          _buildTextField(
            label: 'PRÉNOM',
            hint: 'Votre prénom',
            icon: Icons.person_outline,
            controller: prenomController,
          ),

          _buildTextField(
            label: 'EMAIL',
            hint: 'votre@email.com',
            icon: Icons.email_outlined,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
          ),

          _buildDateField(),

          _buildTextField(
            label: 'VILLE',
            hint: 'Votre ville',
            icon: Icons.location_city_outlined,
            controller: villeController,
          ),

          _buildPhoneField(),

          _buildPasswordField(),

          _buildConfirmPasswordField(),
        ],
      ),
    );
  }

  // CHAMP TEXTE
  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 20.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),

          SizedBox(height: 8.h),

          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
            ),
            decoration: _inputDecoration(
              hint: hint,
              icon: icon,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ce champ est requis';
              }

              if (label == 'EMAIL') {
                final emailRegex = RegExp(
                  r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                );

                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Email invalide';
                }
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // DATE
  Widget _buildDateField() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 20.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('DATE DE NAISSANCE'),

          SizedBox(height: 8.h),

          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              decoration: BoxDecoration(
                color: _fieldColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18.sp,
                    color: _accentColor,
                  ),

                  SizedBox(width: 16.w),

                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? '${selectedDate!.day.toString().padLeft(2, '0')}/'
                          '${selectedDate!.month.toString().padLeft(2, '0')}/'
                          '${selectedDate!.year}'
                          : 'JJ/MM/AAAA',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: selectedDate != null
                            ? Colors.black87
                            : const Color(0xA58A4E1E),
                      ),
                    ),
                  ),

                  Icon(
                    Icons.cake_outlined,
                    size: 18.sp,
                    color: _accentColor.withValues(
                      alpha: 0.48,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TELEPHONE
  Widget _buildPhoneField() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 20.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('TÉLÉPHONE'),

          SizedBox(height: 8.h),

          IntlPhoneField(
            initialCountryCode: 'ML',

            decoration: InputDecoration(
              hintText: '+223 XX XX XX XX',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: const Color(0xA58A4E1E),
              ),
              filled: true,
              fillColor: _fieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(
                  color: _borderColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(
                  color: _accentColor,
                  width: 1.5,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),

            onChanged: (phone) {
              setState(() {
                completePhoneNumber =
                    phone.completeNumber;

                countryCode =
                    phone.countryCode;
              });

              logger.i(
                '📞 Numéro : ${phone.completeNumber}, '
                    'Indicatif : +${phone.countryCode}, '
                    'Pays : ${phone.countryISOCode}',
              );
            },

            validator: (phone) {
              if (phone == null ||
                  phone.number.isEmpty) {
                return 'Entrez votre téléphone';
              }

              if (phone.number.length < 8) {
                return 'Numéro invalide';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // PASSWORD
  Widget _buildPasswordField() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 20.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('MOT DE PASSE'),

          SizedBox(height: 8.h),

          TextFormField(
            controller: passwordController,
            obscureText: !passwordVisible,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
            ),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  passwordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 18.sp,
                  color: _accentColor,
                ),
                onPressed: () {
                  setState(() {
                    passwordVisible =
                    !passwordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le mot de passe est requis';
              }

              if (value.length < 8) {
                return 'Minimum 8 caractères';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // CONFIRMATION
  Widget _buildConfirmPasswordField() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 20.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(
            'CONFIRMATION DU MOT DE PASSE',
          ),

          SizedBox(height: 8.h),

          TextFormField(
            controller: confirmPasswordController,
            obscureText: !confirmPasswordVisible,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
            ),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  confirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 18.sp,
                  color: _accentColor,
                ),
                onPressed: () {
                  setState(() {
                    confirmPasswordVisible =
                    !confirmPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez confirmer votre mot de passe';
              }

              if (value != passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // LABEL
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
        color: _textColor,
      ),
    );
  }

  // INPUT
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14.sp,
        color: const Color(0xA58A4E1E),
      ),
      prefixIcon: Icon(
        icon,
        size: 18.sp,
        color: _accentColor,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(
          color: _borderColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(
          color: _accentColor,
          width: 1.5,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 16.h,
      ),
    );
  }

  // CONDITIONS
  Widget _buildTermsCheckbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  checkboxValue =
                  !checkboxValue;

                  if (checkboxValue) {
                    checkboxError = null;
                  }
                });
              },
              child: Container(
                width: 25.w,
                height: 25.w,
                margin: EdgeInsets.only(
                  top: 2.h,
                ),
                decoration: BoxDecoration(
                  color: checkboxValue
                      ? _accentColor
                      : Colors.transparent,
                  borderRadius:
                  BorderRadius.circular(6.r),
                  border: Border.all(
                    color: checkboxValue
                        ? _accentColor
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: checkboxValue
                    ? Icon(
                  Icons.check,
                  size: 15.sp,
                  color: Colors.white,
                )
                    : null,
              ),
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: Wrap(
                crossAxisAlignment:
                WrapCrossAlignment.center,
                children: [
                  Text(
                    "J'accepte les ",
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: _textColor,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/conditions',
                      );
                    },
                    child: Text(
                      "Conditions d'utilisation",
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: _accentColor,
                        decoration:
                        TextDecoration.underline,
                        decorationColor:
                        _accentColor,
                      ),
                    ),
                  ),

                  Text(
                    " et la ",
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: _textColor,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/conditions',
                      );
                    },
                    child: Text(
                      "Politique de confidentialité",
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: _accentColor,
                        decoration:
                        TextDecoration.underline,
                        decorationColor:
                        _accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (checkboxError != null)
          Padding(
            padding: EdgeInsets.only(
              top: 8.h,
              left: 32.w,
            ),
            child: Text(
              checkboxError!,
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 12.sp,
              ),
            ),
          ),
      ],
    );
  }

  // BOUTONS
  Widget _buildButtons() {
    return Column(
      children: [

        // INSCRIPTION
        SizedBox(
          width: double.infinity,
          height: 54.h,
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(40.r),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE85D26),
                  Color(0xFFF5A623),
                ],
              ),
            ),
            child: ElevatedButton(
              onPressed:
              isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.transparent,
                shadowColor:
                Colors.transparent,
                foregroundColor:
                Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(40.r),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                width: 24.w,
                height: 24.w,
                child:
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                "S'inscrire",
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // GOOGLE
        SizedBox(
          width: double.infinity,
          height: 54.h,
          child: OutlinedButton(
            onPressed: () {
              _showAppSnackBar(
                message:
                'Fonctionnalité à venir',
                type: SnackBarType.info,
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: _fieldColor,
              foregroundColor: Colors.black87,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(16.r),
              ),
              side: const BorderSide(
                color: _borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google_logo.svg.png',
                  width: 20.w,
                  height: 20.w,
                ),

                SizedBox(width: 12.w),

                Text(
                  "S'inscrire avec Google",
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // CONNEXION
        Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Text(
              'Déjà un compte ? ',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: _textColor,
              ),
            ),

            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/connexion',
                );
              },
              child: Text(
                'Connectez-vous',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
