import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:service/backend_service.dart';
import 'package:service/snackbar_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service/logger.dart';

enum SnackBarType { success, error, warning, info }
class ConnexionWidget extends StatefulWidget {
  const ConnexionWidget({super.key});

  static const String routeName = '/connexion';

  @override
  State<ConnexionWidget> createState() => _ConnexionWidgetState();
}

class _ConnexionWidgetState extends State<ConnexionWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool isLoading = false;
  String backendData = "";

  final Color _accentColor = const Color(0xFFE85D26);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showAppSnackBar({
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    switch (type) {
      case SnackBarType.success:
        SnackBarService().showSuccess(message, duration: duration);
        break;
      case SnackBarType.error:
        SnackBarService().showError(message, duration: duration);
        break;
      case SnackBarType.warning:
        SnackBarService().showWarning(message, duration: duration);
        break;
      case SnackBarType.info:
        SnackBarService().showInfo(message, duration: duration);
        break;
    }
  }

  String _getAuthErrorMessage(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return '🔑 Email ou mot de passe incorrect.';
      case 'user-not-found':
        return '👤 Utilisateur non trouvé.';
      case 'wrong-password':
        return '🔑 Mot de passe incorrect.';
      case 'too-many-requests':
        return '⏳ Trop de tentatives. Réessayez plus tard.';
      default:
        return '❌ Erreur de connexion: ${e.message}';
    }
  }

  String _getGenericErrorMessage(dynamic e) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('invalid credentials') ||
        errorString.contains('wrong password') ||
        errorString.contains('password')) {
      return '🔑 Email ou mot de passe incorrect.';
    }
    if (errorString.contains('user not found') ||
        errorString.contains('user-not-found')) {
      return '👤 Utilisateur non trouvé.';
    }
    if (errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection')) {
      return '📶 Problème de connexion réseau.';
    }
    if (errorString.contains('too many requests')) {
      return '⏳ Trop de tentatives. Réessayez plus tard.';
    }

    return '❌ Échec de connexion. Veuillez réessayer.';
  }

  Future<void> login() async {
    // Fermer le clavier
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final navigator = Navigator.of(context);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception("Connexion échouée");

      try {
        final backend = BackendService();
        final data = await backend.getProtectedData();

        if (mounted) {
          setState(() => backendData = data.toString());
        }

        logger.i("Réponse backend : $data");

        if (mounted) {
          _showAppSnackBar(
            message: 'Connexion réussie !\n👋 Ravi de vous revoir',
            type: SnackBarType.success,
          );
        }

      } catch (backendError) {
        if (mounted) {
          setState(() => backendData = "Erreur backend : $backendError");
          _showAppSnackBar(
            message: '⚠️ Connecté mais service indisponible',
            type: SnackBarType.warning,
          );
        }
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        navigator.pushReplacementNamed('/main');
      }

    } on AuthException catch (e) {

      if (mounted) {
        _showAppSnackBar(
          message: _getAuthErrorMessage(e),
          type: SnackBarType.error,
        );
        logger.e("❌ AuthException: ${e.code} - ${e.message}");
      }

    } catch (e) {
      if (mounted) {
        _showAppSnackBar(
          message: _getGenericErrorMessage(e),
          type: SnackBarType.error,
        );
        logger.e("❌ Erreur de connexion: $e");
      }

    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEFE0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Logo
            _buildLogo(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildTitleSection(),
                    const SizedBox(height: 40),
                    _buildForm(),
                    const SizedBox(height: 100),
                    _buildLoginButton(),
                    const SizedBox(height: 16),
                    _buildRegisterLink(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE5CE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        'assets/images/logo_appart3.png',
        fit: BoxFit.contain,
        height: 80,
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👋 Bonjour !',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ravi de vous revoir ! Connectez-vous.',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xE58A4E1E),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email champ
          _buildEmailField(),
          const SizedBox(height: 20),
          // Password champ
          _buildPasswordField(),
          const SizedBox(height: 12),
          // Forgot password
          _buildForgotPasswordLink(),
          const SizedBox(height: 24),
          // Divider
          _buildDivider(),
          const SizedBox(height: 24),
          // Bouton Google
          _buildGoogleButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ADRESSE EMAIL',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
            color: Color(0xFF8A4E1E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'votre@email.com',
            hintStyle: const TextStyle(
              fontSize: 15,
              color: Color(0xA58A4E1E),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              size: 18,
              color: _accentColor,
            ),
            filled: true,
            fillColor: const Color(0xB3FFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xfffddbc7), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _accentColor,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre email';
            }
            final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return 'Email invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOT DE PASSE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
            color: Color(0xFF8A4E1E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xA58A4E1E),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              size: 18,
              color: _accentColor,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                size: 18,
                color: _accentColor,
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
            filled: true,
            fillColor: const Color(0xB3FFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xfffddbc7), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _accentColor,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre mot de passe';
            }
            if (value.length < 6) {
              return 'Mot de passe trop court (minimum 6 caractères)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          _showAppSnackBar(
            message: '🔜 Fonctionnalité à venir',
            type: SnackBarType.info,
          );
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Mot de passe oublié ?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: const Color(0xFFFDDBC7),
            thickness: 0.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFFEF8E56),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: const Color(0xFFFDDBC7),
            thickness: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton(
      onPressed: () {
        _showAppSnackBar(
          message: '🔜 Fonctionnalité à venir',
          type: SnackBarType.info,
        );
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: Color (0xB3FFFFFF),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: const BorderSide(
          color: Color(0xFFFDDBC7),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Image.asset(
              'assets/images/google_logo.svg.png',
              width: 20,
              height: 20,

            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Continuer avec Google',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 0,
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
            : const Text(
          'Se connecter',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Pas encore de compte ? ',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8A4E1E),
            fontWeight: FontWeight.w400,
          ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/register');
          },
          child: Text(
            'Inscrivez-vous',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _accentColor,
            ),
          ),
        ),
      ],
    );
  }
}