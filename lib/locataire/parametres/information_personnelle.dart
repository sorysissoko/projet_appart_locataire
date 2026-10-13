import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:service/auth_service.dart';
import 'package:service/database_service.dart';
import 'package:service/service_locator.dart';
import '../../widgets/parametre_header.dart';

class InformationPersonnellePage extends StatefulWidget {
  const InformationPersonnellePage({super.key});

  @override
  State<InformationPersonnellePage> createState() =>
      _InformationPersonnellePageState();
}

class _InformationPersonnellePageState
    extends State<InformationPersonnellePage> {
  final AuthService _auth = ServiceLocator.auth;
  final DatabaseService _db = ServiceLocator.database;

  Map<String, dynamic>? _userData;

  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  String? _errorMessage;

  String? _avatarUrl;

  static const Color _orange = Color(0xFFE85D26);
  static const Color _darkOrange = Color(0xFF8A4E1E);
  static const Color _background = Color(0xFFFFF2E5);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // CHARGEMENT UTILISATEUR

  Future<void> _loadUserData({
    bool showSkeleton = true,
  }) async {
    if (!mounted) return;

    if (showSkeleton) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = _auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'Utilisateur non connecté';
          _isLoading = false;
        });

        return;
      }

      final response = await _db.getCurrentUserProfile();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _errorMessage = 'Données utilisateur non trouvées';
          _isLoading = false;
        });

        return;
      }

      _userData = response;


      await _loadAvatarUrl();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erreur lors du chargement : $e';
        _isLoading = false;
      });
    }
  }


  // CHARGEMENT URL AVATAR

  Future<void> _loadAvatarUrl() async {
    final path = _userData?['photo_profil']?.toString();

    if (path == null || path.trim().isEmpty) {
      _avatarUrl = null;
      return;
    }

    try {

      _avatarUrl = await _db.getSignedUrl(
        bucketName: 'avatars',
        filePath: path,
      );
    } catch (_) {
      _avatarUrl = null;
    }
  }

  // PHOTO DE PROFIL

  Future<void> _changeProfilePhoto() async {
    if (_isUploadingPhoto) return;

    try {
      final picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La photo ne doit pas dépasser 5 Mo.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      setState(() {
        _isUploadingPhoto = true;
      });


      // Déterminer le format de l'image

      String extension = 'jpg';
      String mimeType = 'image/jpeg';

      final String fileName = image.name.toLowerCase();

      if (fileName.endsWith('.png')) {
        extension = 'png';
        mimeType = 'image/png';
      } else if (fileName.endsWith('.webp')) {
        extension = 'webp';
        mimeType = 'image/webp';
      } else if (fileName.endsWith('.jpeg')) {
        extension = 'jpeg';
        mimeType = 'image/jpeg';
      }


      // Upload centralisé dans DatabaseService

      final String? storagePath =
      await _db.uploadCurrentUserAvatar(
        bytes: bytes,
        extension: extension,
        mimeType: mimeType,
      );

      if (storagePath == null || storagePath.trim().isEmpty) {
        throw Exception(
          'Le chemin de la photo n’a pas été retourné.',
        );
      }

      _userData?['photo_profil'] = storagePath;

      // Générer une nouvelle URL signée

      await _loadAvatarUrl();

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil mise à jour'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de modifier la photo : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // MODIFICATION D'UN CHAMP

  Future<void> _updateUserField(
      String field,
      dynamic value, {
        String? successMessage,
      }) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }


      // Mise à jour centralisée via DatabaseService

      switch (field) {
        case 'nom':
          await _db.updateCurrentUserProfile(
            nom: value?.toString(),
          );
          break;

        case 'prenom':
          await _db.updateCurrentUserProfile(
            prenom: value?.toString(),
          );
          break;

        case 'telephone':
          await _db.updateCurrentUserProfile(
            telephone: value?.toString(),
          );
          break;

        case 'indicatif_telephone':
          await _db.updateCurrentUserProfile(
            indicatifTelephone: value?.toString(),
          );
          break;

        case 'pays':
          await _db.updateCurrentUserProfile(
            pays: value?.toString(),
          );
          break;

        case 'adresse':
          await _db.updateCurrentUserProfile(
            adresse: value?.toString(),
          );
          break;

        case 'urgencephone':
          await _db.updateCurrentUserProfile(
            urgencephone: value?.toString(),
          );
          break;

        case 'ville':
          await _db.updateCurrentUserProfile(
            ville: value?.toString(),
          );
          break;

        case 'description':
          await _db.updateCurrentUserProfile(
            description: value?.toString(),
          );
          break;

        case 'date_naissance':
          DateTime? dateNaissance;

          if (value is DateTime) {
            dateNaissance = value;
          } else if (value != null) {
            dateNaissance = DateTime.tryParse(
              value.toString(),
            );
          }

          if (dateNaissance == null) {
            throw Exception(
              'Date de naissance invalide.',
            );
          }

          await _db.updateCurrentUserProfile(
            dateNaissance: dateNaissance,
          );
          break;

        default:
          throw Exception(
            'Champ utilisateur non autorisé : $field',
          );
      }


      //Recharger le profil après modification

      await _loadUserData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successMessage ??
                'Informations mises à jour',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // DIALOGUE TEXTE

  Future<void> _showEditDialog({
    required String title,
    required String field,
    required String currentValue,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(
      text: currentValue == 'Non renseigné' ? '' : currentValue,
    );

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'Modifier $title',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: _darkOrange,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: _background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null) return;

    if (result.trim() == currentValue.trim()) return;

    await _updateUserField(
      field,
      result.trim().isEmpty ? null : result.trim(),
    );
  }


  // DATE DE NAISSANCE

  Future<void> _selectBirthDate() async {
    DateTime initialDate = DateTime(1995, 1, 1);

    final current = _userData?['date_naissance'];

    if (current != null) {
      try {
        initialDate = DateTime.parse(current.toString());
      } catch (_) {}
    }

    final DateTime today = DateTime.now();

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(today) ? today : initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _orange,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    final String date =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';

    await _updateUserField(
      'date_naissance',
      date,
      successMessage: 'Date de naissance mise à jour',
    );
  }


  // BUILD

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              const ParametreHeader(
                title: 'Informations personnelles',
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: 150.h,
                  left: 16.w,
                  right: 16.w,
                ),
                child: _buildContent(),
              ),
            ],
          ),
        );
      },
    );
  }


  // CONTENU

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _orange,
          strokeWidth: 2,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60.sp,
              color: Colors.red[300],
            ),
            SizedBox(height: 16.h),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
              ),
              onPressed: _loadUserData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_userData == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 40.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),

          SizedBox(height: 24.h),

          _buildSectionTitle('PROFIL'),

          _buildEditableItem(
            title: 'Prénom',
            value: _displayValue(_userData!['prenom']),
            icon: Icons.person_outline,
            onTap: () {
              _showEditDialog(
                title: 'le prénom',
                field: 'prenom',
                currentValue: _userData!['prenom'] ?? '',
                hintText: 'Votre prénom',
              );
            },
          ),

          _buildEditableItem(
            title: 'Nom',
            value: _displayValue(_userData!['nom']),
            icon: Icons.badge_outlined,
            onTap: () {
              _showEditDialog(
                title: 'le nom',
                field: 'nom',
                currentValue: _userData!['nom'] ?? '',
                hintText: 'Votre nom',
              );
            },
          ),

          _buildEditableItem(
            title: 'À propos de moi',
            value: _displayValue(
              _userData!['description'],
              fallback: 'Ajouter une description',
            ),
            icon: Icons.description_outlined,
            multiline: true,
            onTap: () {
              _showEditDialog(
                title: 'votre description',
                field: 'description',
                currentValue: _userData!['description'] ?? '',
                hintText: 'Parlez un peu de vous...',
                maxLines: 5,
              );
            },
          ),

          SizedBox(height: 20.h),

          _buildSectionTitle('COORDONNÉES'),

          _buildReadOnlyItem(
            title: 'Email',
            value: _displayValue(_userData!['email']),
            icon: Icons.email_outlined,
            trailing: Icons.lock_outline,
          ),

          _buildEditableItem(
            title: 'Téléphone',
            value: _displayValue(_userData!['telephone']),
            icon: Icons.phone_outlined,
            onTap: () {
              _showEditDialog(
                title: 'le téléphone',
                field: 'telephone',
                currentValue: _userData!['telephone'] ?? '',
                hintText: 'XX XX XX XX',
                keyboardType: TextInputType.phone,
              );
            },
          ),

          _buildEditableItem(
            title: 'Indicatif téléphonique',
            value: _displayValue(
              _userData!['indicatif_telephone'],
              fallback: '+223',
            ),
            icon: Icons.language_outlined,
            onTap: () {
              _showEditDialog(
                title: "l'indicatif téléphonique",
                field: 'indicatif_telephone',
                currentValue:
                _userData!['indicatif_telephone'] ?? '+223',
                hintText: '+223',
                keyboardType: TextInputType.phone,
              );
            },
          ),

          _buildEditableItem(
            title: "Téléphone d'urgence",
            value: _displayValue(_userData!['urgencephone']),
            icon: Icons.emergency_outlined,
            onTap: () {
              _showEditDialog(
                title: "le téléphone d'urgence",
                field: 'urgencephone',
                currentValue: _userData!['urgencephone'] ?? '',
                hintText: '+223 XX XX XX XX',
                keyboardType: TextInputType.phone,
              );
            },
          ),

          SizedBox(height: 20.h),

          _buildSectionTitle('INFORMATIONS PERSONNELLES'),

          _buildEditableItem(
            title: 'Date de naissance',
            value: _userData!['date_naissance'] != null
                ? _formatDate(_userData!['date_naissance'])
                : 'Non renseignée',
            icon: Icons.cake_outlined,
            onTap: _selectBirthDate,
          ),

          _buildEditableItem(
            title: 'Pays',
            value: _displayValue(
              _userData!['pays'],
              fallback: 'Mali',
            ),
            icon: Icons.public_outlined,
            onTap: () {
              _showEditDialog(
                title: 'le pays',
                field: 'pays',
                currentValue: _userData!['pays'] ?? 'Mali',
                hintText: 'Votre pays',
              );
            },
          ),

          _buildEditableItem(
            title: 'Ville',
            value: _displayValue(_userData!['ville']),
            icon: Icons.location_city_outlined,
            onTap: () {
              _showEditDialog(
                title: 'la ville',
                field: 'ville',
                currentValue: _userData!['ville'] ?? '',
                hintText: 'Votre ville',
              );
            },
          ),

          _buildEditableItem(
            title: 'Adresse',
            value: _displayValue(_userData!['adresse']),
            icon: Icons.home_outlined,
            multiline: true,
            onTap: () {
              _showEditDialog(
                title: "l'adresse",
                field: 'adresse',
                currentValue: _userData!['adresse'] ?? '',
                hintText: 'Votre adresse',
                maxLines: 3,
              );
            },
          ),

          SizedBox(height: 20.h),

          _buildSectionTitle('VÉRIFICATION DU COMPTE'),

          _buildVerificationItem(
            title: 'Identité',
            value: _userData!['identite_verifiee'] == true
                ? 'Vérifiée'
                : 'Non vérifiée',
            verified: _userData!['identite_verifiee'] == true,
            icon: Icons.verified_user_outlined,
          ),

          _buildVerificationItem(
            title: 'Compte',
            value: _userData!['est_certifie'] == true
                ? 'Certifié'
                : 'Non certifié',
            verified: _userData!['est_certifie'] == true,
            icon: Icons.verified_outlined,
          ),

          if (_userData!['date_verification_identite'] != null)
            _buildReadOnlyItem(
              title: 'Date de vérification',
              value: _formatDateTime(
                _userData!['date_verification_identite'],
              ),
              icon: Icons.event_available_outlined,
            ),

          if (_userData!['date_certification'] != null)
            _buildReadOnlyItem(
              title: 'Date de certification',
              value: _formatDateTime(
                _userData!['date_certification'],
              ),
              icon: Icons.workspace_premium_outlined,
            ),

          _buildDocumentsItem(),

          SizedBox(height: 20.h),

          _buildSectionTitle('COMPTE'),

          _buildReadOnlyItem(
            title: 'Statut',
            value: _getStatusText(
              _userData!['statut']?.toString() ?? '',
            ),
            icon: Icons.toggle_on_outlined,
          ),

          _buildReadOnlyItem(
            title: 'Membre depuis',
            value: _formatDate(
              _userData!['created_at'],
            ),
            icon: Icons.calendar_month_outlined,
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }


  // HEADER PROFIL

  Widget _buildProfileHeader() {
    final prenom = _userData!['prenom']?.toString() ?? '';
    final nom = _userData!['nom']?.toString() ?? '';

    final fullName = '$prenom $nom'.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: _orange.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 105.w,
                height: 105.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _orange,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _isUploadingPhoto
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: _orange,
                      strokeWidth: 2,
                    ),
                  )
                      : _avatarUrl != null
                      ? Image.network(
                    _avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return _buildDefaultAvatar(
                        fullName,
                      );
                    },
                  )
                      : _buildDefaultAvatar(
                    fullName,
                  ),
                ),
              ),
              Material(
                color: _orange,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _changeProfilePhoto,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(9.w),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 19.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          Text(
            fullName.isEmpty ? 'Utilisateur' : fullName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: _darkOrange,
            ),
          ),

          SizedBox(height: 12.h),

          if (_userData!['est_certifie'] == true)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: 17.sp,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'Compte certifié',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pending_outlined,
                    color: Colors.orange[700],
                    size: 17.sp,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'Compte non certifié',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    String letter = '?';

    if (name.trim().isNotEmpty) {
      letter = name.trim()[0].toUpperCase();
    }

    return Container(
      color: _orange.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.poppins(
          fontSize: 40.sp,
          fontWeight: FontWeight.w700,
          color: _orange,
        ),
      ),
    );
  }

  // TITRE SECTION

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: 5.w,
        bottom: 8.h,
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: _orange,
        ),
      ),
    );
  }


  // ITEM MODIFIABLE

  Widget _buildEditableItem({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool multiline = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 7.h),
        padding: EdgeInsets.symmetric(
          horizontal: 13.w,
          vertical: 13.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: multiline
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            _buildIconBox(icon),

            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    value,
                    maxLines: multiline ? 4 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: value == 'Non renseigné' ||
                          value == 'Non renseignée' ||
                          value == 'Ajouter une description'
                          ? Colors.grey[400]
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            Icon(
              Icons.edit_outlined,
              size: 19.sp,
              color: _orange,
            ),
          ],
        ),
      ),
    );
  }


  // ITEM LECTURE SEULE

  Widget _buildReadOnlyItem({
    required String title,
    required String value,
    required IconData icon,
    IconData? trailing,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 7.h),
      padding: EdgeInsets.symmetric(
        horizontal: 13.w,
        vertical: 13.h,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          _buildIconBox(icon),

          SizedBox(width: 12.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            trailing ?? Icons.lock_outline,
            size: 18.sp,
            color: Colors.grey[500],
          ),
        ],
      ),
    );
  }


  // VERIFICATION

  Widget _buildVerificationItem({
    required String title,
    required String value,
    required bool verified,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 7.h),
      padding: EdgeInsets.symmetric(
        horizontal: 13.w,
        vertical: 13.h,
      ),
      decoration: BoxDecoration(
        color: verified
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: verified
              ? Colors.green.withValues(alpha: 0.20)
              : Colors.orange.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          _buildIconBox(
            icon,
            iconColor: verified
                ? Colors.green
                : Colors.orange[700],
          ),

          SizedBox(width: 12.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: verified
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),

          Icon(
            verified
                ? Icons.check_circle
                : Icons.pending_outlined,
            size: 22.sp,
            color: verified
                ? Colors.green
                : Colors.orange[700],
          ),
        ],
      ),
    );
  }


  // DOCUMENTS

  Widget _buildDocumentsItem() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/documents_verification',
        );
      },
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 7.h),
        padding: EdgeInsets.symmetric(
          horizontal: 13.w,
          vertical: 15.h,
        ),
        decoration: BoxDecoration(
          color: _orange.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: _orange.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            _buildIconBox(
              Icons.folder_outlined,
              iconColor: _orange,
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documents et vérification',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Gérer vos pièces d’identité et suivre leur vérification',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: _orange,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }


  // ICON BOX

  Widget _buildIconBox(
      IconData icon, {
        Color? iconColor,
      }) {
    final color = iconColor ?? _orange;

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 21.sp,
        color: color,
      ),
    );
  }


  // HELPERS

  String _displayValue(
      dynamic value, {
        String fallback = 'Non renseigné',
      }) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Non renseignée';

    try {
      final parsed = DateTime.parse(date.toString());

      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}';
    } catch (_) {
      return date.toString();
    }
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'Non renseignée';

    try {
      final parsed = DateTime.parse(date.toString()).toLocal();

      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year} à '
          '${parsed.hour.toString().padLeft(2, '0')}:'
          '${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }


  String _getStatusText(String status) {
    switch (status) {
      case 'actif':
        return 'Actif';
      case 'inactif':
        return 'Inactif';
      case 'suspendu':
        return 'Suspendu';
      case 'bloque':
        return 'Bloqué';
      default:
        return status.isEmpty ? 'Inconnu' : status;
    }
  }


}