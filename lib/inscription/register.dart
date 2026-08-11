import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:service/auth_service.dart';
import 'package:service/logger.dart';
import 'package:service/snackbar_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FieldConfig {
  final String id;
  final String label;
  final String placeholder;
  final IconData icon;
  final bool isPassword;
  final bool isDate;
  final bool isCity;

  FieldConfig({
    required this.id,
    required this.label,
    required this.placeholder,
    required this.icon,
    this.isPassword = false,
    this.isDate = false,
    this.isCity = false,
  });
}

enum SnackBarType { success, error, warning, info }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final Color _accentColor = const Color(0xFFE85D26);

  // Contrôleurs
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final villeController = TextEditingController();

  DateTime? selectedDate;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool checkboxValue = false;
  bool isLoading = false;
  String? checkboxError;
  String? completePhoneNumber;
  String? countryCode;

  final List<FieldConfig> fields = [
    FieldConfig(
      id: 'nom',
      label: 'NOM',
      placeholder: 'Votre nom',
      icon: Icons.person_outline,
    ),
    FieldConfig(
      id: 'prenom',
      label: 'PRÉNOM',
      placeholder: 'Votre prénom',
      icon: Icons.person_outline,
    ),
    FieldConfig(
      id: 'email',
      label: 'EMAIL',
      placeholder: 'votre@email.com',
      icon: Icons.email_outlined,
    ),
    FieldConfig(
      id: 'date_naissance',
      label: 'DATE DE NAISSANCE',
      placeholder: 'JJ/MM/AAAA',
      icon: Icons.calendar_month_outlined,
      isDate: true,
    ),
    FieldConfig(
      id: 'ville',
      label: 'VILLE',
      placeholder: 'Votre ville',
      icon: Icons.location_city_outlined,
      isCity: true,
    ),
    FieldConfig(
      id: 'password',
      label: 'MOT DE PASSE',
      placeholder: '••••••••',
      icon: Icons.lock_outline,
      isPassword: true,
    ),
    FieldConfig(
      id: 'confirm',
      label: 'CONFIRMATION',
      placeholder: '••••••••',
      icon: Icons.lock_outline,
      isPassword: true,
    ),
  ];

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
      case 'email-already-in-use':
        return '📧 Cet e-mail est déjà utilisé. Connectez-vous !';
      case 'invalid-email':
        return '📧 Adresse e-mail invalide.';
      case 'weak-password':
        return '🔑 Mot de passe trop faible (minimum 6 caractères).';
      case 'user-not-found':
        return '👤 Utilisateur non trouvé.';
      case 'wrong-password':
        return '🔑 Mot de passe incorrect.';
      default:
        return '❌ Erreur lors de l\'inscription: ${e.message}';
    }
  }

  String _getGenericErrorMessage(dynamic e) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('already exists') ||
        errorString.contains('user already registered')) {
      return '📧 Cet e-mail est déjà utilisé.';
    }
    if (errorString.contains('row-level security') ||
        errorString.contains('rls')) {
      return '🔒 Erreur de sécurité. Contactez le support.';
    }
    if (errorString.contains('invalid credentials') ||
        errorString.contains('password')) {
      return '🔑 Email ou mot de passe non valide.';
    }
    if (errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection')) {
      return '📶 Problème de connexion réseau.';
    }
    if (errorString.contains('telephone') ||
        errorString.contains('phone')) {
      return '📱 Numéro de téléphone invalide.';
    }

    return '❌ Erreur lors de l\'inscription. Veuillez réessayer.';
  }

  // ─── VALIDATION DATE DE NAISSANCE ───
  bool _isAtLeast19YearsOld(DateTime birthDate) {
    final now = DateTime.now();
    final diff = now.difference(birthDate);
    final ageInYears = diff.inDays / 365.25;
    return ageInYears >= 19;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 19 * 365)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 19 * 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE85D26),
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

    if (picked != null) {
      if (!_isAtLeast19YearsOld(picked)) {
        _showAppSnackBar(
          message: '⚠️ Vous devez avoir au moins 19 ans pour vous inscrire',
          type: SnackBarType.warning,
        );
        return;
      }
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (completePhoneNumber == null || completePhoneNumber!.isEmpty) {
      _showAppSnackBar(
        message: 'Veuillez entrer votre numéro de téléphone',
        type: SnackBarType.error,
      );
      return;
    }

    if (selectedDate == null) {
      _showAppSnackBar(
        message: 'Veuillez sélectionner votre date de naissance',
        type: SnackBarType.error,
      );
      return;
    }

    if (!_isAtLeast19YearsOld(selectedDate!)) {
      _showAppSnackBar(
        message: '⚠️ Vous devez avoir au moins 19 ans pour vous inscrire',
        type: SnackBarType.warning,
      );
      return;
    }

    if (!checkboxValue) {
      setState(() => checkboxError = 'Vous devez accepter les conditions');
      _showAppSnackBar(
        message: 'Acceptez les conditions pour continuer',
        type: SnackBarType.warning,
      );
      return;
    }

    setState(() {
      isLoading = true;
      checkboxError = null;
    });

    try {
      final nom = nomController.text.trim();
      final prenom = prenomController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final ville = villeController.text.trim();

      final dateNaissance = selectedDate!.toIso8601String().split('T').first;

      await AuthService().signUpWithEmailPassword(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        telephone: completePhoneNumber!,
        adresse: '',
        ville: ville,
        dateNaissance: dateNaissance,
      );

      if (mounted) {
        _showAppSnackBar(
          message: '🎉 Inscription réussie !\nBienvenue $prenom $nom',
          type: SnackBarType.success,
        );

        logger.i("✅ Inscription réussie: $email");

        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
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
        logger.e("❌ Erreur inscription: $e");
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
            _buildHeader(),
            _buildLogo(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 24),
                    _buildForm(),
                    const SizedBox(height: 24),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 32),
                    _buildButtons(),
                    const SizedBox(height: 32),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
          '🎉 Rejoignez-nous !',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Créez votre compte et découvrez le Mali !',
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
        children: [
          _buildFormField(fields[0], nomController),
          _buildFormField(fields[1], prenomController),
          _buildFormField(fields[2], emailController),
          _buildDateField(),
          _buildFormField(fields[4], villeController),
          _buildPhoneField(),
          _buildPasswordField(),
          _buildConfirmPasswordField(),
        ],
      ),
    );
  }

  // ─── CHAMP TEXTE STANDARD ───
  Widget _buildFormField(FieldConfig field, TextEditingController controller) {
    final isPassword = field.isPassword;
    final isConfirm = field.id == 'confirm';
    final isPasswordField = field.id == 'password';

    bool showPassword = false;
    if (isPasswordField) {
      showPassword = passwordVisible;
    } else if (isConfirm) {
      showPassword = confirmPasswordVisible;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
              color: Color(0xFF8A4E1E),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: isPassword && !showPassword,
            keyboardType: field.id == 'email'
                ? TextInputType.emailAddress
                : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(
                field.icon,
                size: 18,
                color: _accentColor,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: _accentColor,
                ),
                onPressed: () {
                  setState(() {
                    if (isPasswordField) {
                      passwordVisible = !passwordVisible;
                    } else if (isConfirm) {
                      confirmPasswordVisible = !confirmPasswordVisible;
                    }
                  });
                },
              )
                  : null,
              hintText: field.placeholder,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xA58A4E1E),
              ),
              filled: true,
              fillColor: const Color(0xB3FFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xfffddbc7), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: _accentColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est requis';
              }
              if (field.id == 'email') {
                final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Email invalide';
                }
              }
              if (isConfirm && value != passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              if (isPasswordField && value.length < 6) {
                return 'Minimum 6 caractères';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─── CHAMP DATE DE NAISSANCE ───
  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DATE DE NAISSANCE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
              color: Color(0xFF8A4E1E),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xB3FFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xfffddbc7),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: _accentColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
                          : 'JJ/MM/AAAA',
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDate != null
                            ? Colors.black87
                            : const Color(0xA58A4E1E),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.cake_outlined,
                    size: 18,
                    color: _accentColor.withValues(alpha: 0x7A),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CHAMP TÉLÉPHONE ───
  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TÉLÉPHONE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
              color: Color(0xFF8A4E1E),
            ),
          ),
          const SizedBox(height: 8),
          IntlPhoneField(
            decoration: InputDecoration(
              hintText: '+223 XX XX XX XX',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xA58A4E1E),
              ),
              filled: true,
              fillColor: const Color(0xB3FFFFFF), // 👈 même fond
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xfffddbc7), width: 1), // 👈 même bordure
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: _accentColor, width: 1.5), // 👈 même focus
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            initialCountryCode: 'ML',
            onChanged: (phone) {
              setState(() {
                completePhoneNumber = phone.completeNumber;
                countryCode = phone.countryCode;
              });
              logger.i(
                  "📞 Numéro: ${phone.completeNumber}, Indicatif: +${phone.countryCode}, Pays: ${phone.countryISOCode}");
            },
            validator: (phone) {
              if (phone == null || phone.number.isEmpty) {
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

  // ─── CHAMP MOT DE PASSE ───
  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
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
            controller: passwordController,
            obscureText: !passwordVisible,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.lock_outline,
                size: 18,
                color: _accentColor.withValues(alpha: 0x7A),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  passwordVisible ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                  color: _accentColor,
                ),
                onPressed: () {
                  setState(() {
                    passwordVisible = !passwordVisible;
                  });
                },
              ),
              hintText: '••••••••',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xA58A4E1E),
              ),
              filled: true,
              fillColor: const Color(0xB3FFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xfffddbc7), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: _accentColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le mot de passe est requis';
              }

              if (value.length < 8) {
                return 'Le mot de passe doit contenir au moins 8 caractères';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─── CHAMP CONFIRMATION ───
  Widget _buildConfirmPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONFIRMATION DU MOT DE PASSE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
              color: Color(0xFF8A4E1E),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: !confirmPasswordVisible,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.lock_outline,
                size: 18,
                color: _accentColor.withValues(alpha: 0x7A),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                  color: _accentColor,
                ),
                onPressed: () {
                  setState(() {
                    confirmPasswordVisible = !confirmPasswordVisible;
                  });
                },
              ),
              hintText: '••••••••',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xA58A4E1E),
              ),
              filled: true,
              fillColor: const Color(0xB3FFFFFF), // 👈 même fond
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xfffddbc7), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: _accentColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
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
                  checkboxValue = !checkboxValue;
                  if (checkboxValue) {
                    checkboxError = null;
                  }
                });
              },
              child: Container(
                width: 25,
                height: 25,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: checkboxValue ? _accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: checkboxValue ? _accentColor : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: checkboxValue
                    ? const Icon(
                  Icons.check,
                  size: 15,
                  color: Colors.white,
                )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "J'accepte les ",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF8A4E1E),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/conditions');
                    },
                    child: Text(
                      "Conditions d'utilisation",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: _accentColor,
                        decoration: TextDecoration.underline,
                        decorationColor: _accentColor,
                      ),
                    ),
                  ),
                  Text(
                    " et la ",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF8A4E1E),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/conditions');
                    },
                    child: Text(
                      "Politique de confidentialité",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: _accentColor,
                        decoration: TextDecoration.underline,
                        decorationColor: _accentColor,
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
            padding: const EdgeInsets.only(top: 8, left: 32),
            child: Text(
              checkboxError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE85D26),
                  Color(0xFFF5A623),
                ],
              ),
            ),
            child: ElevatedButton(
            onPressed: isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Color(0xFFE85D26),
                  strokeWidth: 2
              ),
            )
                : const Text(
              "S'inscrire",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
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
                "S'inscrire avec Google",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _accentColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Déjà un compte ? ',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF8A4E1E),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/connexion'),
              child: Text(
                'Connectez-vous',
                style: TextStyle(
                  fontSize: 14,
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