import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service/backend_service.dart';
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

// CONNEXION
class ConnexionWidget extends StatefulWidget {
  const ConnexionWidget({super.key});

  static const String routeName = '/connexion';

  @override
  State<ConnexionWidget> createState() => _ConnexionWidgetState();
}

class _ConnexionWidgetState extends State<ConnexionWidget> {

  // FORMULAIRE
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ETAT
  bool _showPassword = false;
  bool isLoading = false;

  // COULEURS
  static const Color _accentColor = Color(0xFFE85D26);
  static const Color _backgroundColor = Color(0xFFFFEFE0);
  static const Color _textColor = Color(0xFF8A4E1E);
  static const Color _borderColor = Color(0xFFFDDBC7);
  static const Color _fieldColor = Color(0xB3FFFFFF);

  // DISPOSE
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

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
      case 'invalid_credentials':
        return 'Email ou mot de passe incorrect.';

      case 'user-not-found':
        return 'Utilisateur non trouvé.';

      case 'wrong-password':
        return 'Mot de passe incorrect.';

      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';

      default:
        return 'Erreur de connexion : ${e.message}';
    }
  }

  String _getGenericErrorMessage(dynamic e) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('invalid credentials') ||
        errorString.contains('wrong password') ||
        errorString.contains('password')) {
      return 'Email ou mot de passe incorrect.';
    }

    if (errorString.contains('user not found') ||
        errorString.contains('user-not-found')) {
      return 'Utilisateur non trouvé.';
    }

    if (errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection')) {
      return 'Problème de connexion réseau.';
    }

    if (errorString.contains('too many requests')) {
      return 'Trop de tentatives. Réessayez plus tard.';
    }

    return 'Échec de connexion. Veuillez réessayer.';
  }

  // LOGIN
  Future<void> login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // AUTH SUPABASE
      final response = await Supabase.instance.client.auth
          .signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Connexion échouée.');
      }

      logger.i(
        'Authentification Supabase réussie : '
            '${response.user!.id}',
      );

      // SESSION
      final backend = BackendService();

      if (!backend.hasSession) {
        throw Exception(
          'Session utilisateur introuvable.',
        );
      }

      // PROFIL
      final profile = await backend.getCurrentProfile();

      if (profile == null) {
        await backend.signOut();

        throw Exception(
          'Profil utilisateur introuvable.',
        );
      }

      final bool estCertifie =
          profile['est_certifie'] == true;

      logger.i(
        'Compte certifié : $estCertifie',
      );

      // ROLE
      final role = profile['role']
          ?.toString()
          .trim()
          .toLowerCase();

      logger.i(
        'Rôle utilisateur : $role',
      );

      if (role != 'locataire') {
        await backend.signOut();

        throw Exception(
          'Ce compte n\'est pas autorisé à accéder '
              'à l\'espace locataire.',
        );
      }

      // SUCCES
      logger.i(
        'Connexion locataire réussie : $email',
      );

      if (!mounted) return;

      _showAppSnackBar(
        message: '🎉 Connexion réussie !\n👋 Ravi de vous revoir',
        type: SnackBarType.success,
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/main',
      );

      // AVERTISSEMENT CERTIFICATION
      if (!estCertifie) {
        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) return;

        _showAppSnackBar(
          message:
          '⚠️ Votre compte n\'est pas certifié.\n'
              'Veuillez certifier votre compte depuis les paramètres.',
          type: SnackBarType.warning,
          duration: const Duration(seconds: 6),
        );
      }
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
        'Erreur connexion locataire: $e',
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

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),

                    _buildTitleSection(),

                    SizedBox(height: 40.h),

                    _buildForm(),

                    SizedBox(height: 70.h),

                    _buildLoginButton(),

                    SizedBox(height: 16.h),

                    _buildRegisterLink(),

                    SizedBox(height: 30.h),
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
        vertical: 10.h,
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
          '👋 Bonjour !',
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: 8.h),

        Text(
          'Ravi de vous revoir ! Connectez-vous.',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmailField(),

          SizedBox(height: 20.h),

          _buildPasswordField(),

          SizedBox(height: 12.h),

          _buildForgotPasswordLink(),

          SizedBox(height: 24.h),

          _buildDivider(),

          SizedBox(height: 24.h),

          _buildGoogleButton(),
        ],
      ),
    );
  }

  // EMAIL
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('ADRESSE EMAIL'),

        SizedBox(height: 8.h),

        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
          ),
          decoration: _inputDecoration(
            hintText: 'votre@email.com',
            icon: Icons.email_outlined,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer votre email';
            }

            final emailRegex = RegExp(
              r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
            );

            if (!emailRegex.hasMatch(value.trim())) {
              return 'Email invalide';
            }

            return null;
          },
        ),
      ],
    );
  }

  // PASSWORD
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('MOT DE PASSE'),

        SizedBox(height: 8.h),

        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
          ),
          decoration: _inputDecoration(
            hintText: '••••••••',
            icon: Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                size: 18.sp,
                color: _accentColor,
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre mot de passe';
            }

            if (value.length < 8) {
              return 'Minimum 8 caractères';
            }

            return null;
          },
        ),
      ],
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

  // INPUT DECORATION
  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14.sp,
        color: const Color(0xA58A4E1E),
        fontWeight: FontWeight.w500,
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

  // MOT DE PASSE OUBLIE
  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          _showAppSnackBar(
            message: 'Fonctionnalité à venir',
            type: SnackBarType.info,
          );
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Mot de passe oublié ?',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: _accentColor,
          ),
        ),
      ),
    );
  }

  // DIVIDER
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: _borderColor,
            thickness: 0.5,
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
          ),
          child: Text(
            'ou',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: const Color(0xFFEF8E56),
            ),
          ),
        ),

        const Expanded(
          child: Divider(
            color: _borderColor,
            thickness: 0.5,
          ),
        ),
      ],
    );
  }

  // GOOGLE
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: OutlinedButton(
        onPressed: () {
          _showAppSnackBar(
            message: 'Fonctionnalité à venir',
            type: SnackBarType.info,
          );
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: _fieldColor,
          foregroundColor: Colors.black87,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          side: const BorderSide(
            color: _borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.svg.png',
              width: 20.w,
              height: 20.w,
            ),

            SizedBox(width: 12.w),

            Text(
              'Continuer avec Google',
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: _accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BOUTON LOGIN
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40.r),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
          width: 24.w,
          height: 24.w,
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          'Se connecter',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // INSCRIPTION
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas encore de compte ? ',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: _textColor,
            fontWeight: FontWeight.w400,
          ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(
              context,
              '/register',
            );
          },
          child: Text(
            'Inscrivez-vous',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: _accentColor,
            ),
          ),
        ),
      ],
    );
  }
}