import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class IdentityCaptureModal extends StatefulWidget {
  const IdentityCaptureModal({
    super.key,
    required this.onSubmit,
    this.requireVerso = true,
    this.documentLabel = 'Carte d’identité',
  });

  final Future<void> Function({
  required Uint8List rectoBytes,
  required Uint8List? versoBytes,
  required String numeroDocument,
  required DateTime dateEmission,
  required DateTime dateExpiration,
  required String paysEmission,
  }) onSubmit;

  final bool requireVerso;
  final String documentLabel;

  @override
  State<IdentityCaptureModal> createState() =>
      _IdentityCaptureModalState();
}

class _IdentityCaptureModalState extends State<IdentityCaptureModal> {
  static const Color _orange = Color(0xFFE85D26);
  static const Color _darkOrange = Color(0xFF8A4E1E);
  static const Color _background = Color(0xFFFFF2E5);
  static const Color _success = Color(0xFF16A34A);

  final ImagePicker _picker = ImagePicker();

  Uint8List? _rectoBytes;
  Uint8List? _versoBytes;

  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _paysController = TextEditingController();

  DateTime? _dateEmission;
  DateTime? _dateExpiration;

  bool _isSubmitting = false;
  bool _rectoConfirmed = false;
  bool _versoConfirmed = false;

  bool get _requiresVerso => widget.requireVerso;

  @override
  void dispose() {
    _numeroController.dispose();
    _paysController.dispose();
    super.dispose();
  }

  // PHOTO CAMÉRA

  Future<void> _takePhoto({required bool recto}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      _validateImageBytes(bytes);

      if (!mounted) return;

      setState(() {
        if (recto) {
          _rectoBytes = bytes;
          _rectoConfirmed = false;
        } else {
          _versoBytes = bytes;
          _versoConfirmed = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Impossible de prendre la photo : $e');
    }
  }

  // PHOTO GALERIE

  Future<void> _pickFromGallery({required bool recto}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      _validateImageBytes(bytes);

      if (!mounted) return;

      setState(() {
        if (recto) {
          _rectoBytes = bytes;
          _rectoConfirmed = false;
        } else {
          _versoBytes = bytes;
          _versoConfirmed = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Impossible de sélectionner la photo : $e');
    }
  }

  void _validateImageBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw Exception('Impossible de lire la photo.');
    }

    const maxSize = 50 * 1024 * 1024;

    if (bytes.length > maxSize) {
      throw Exception('La photo ne doit pas dépasser 50 Mo.');
    }
  }


  // CHOIX CAMÉRA GALERIE

  Future<void> _showSourceChoice({required bool recto}) async {
    if (!mounted || _isSubmitting) return;

    final label = recto
        ? (_requiresVerso ? 'Photo du recto' : 'Photo du document')
        : 'Photo du verso';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.r),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: _darkOrange,
                  ),
                ),
                SizedBox(height: 18.h),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  leading: _sourceIcon(
                    Icons.camera_alt_outlined,
                    _orange,
                  ),
                  title: Text(
                    'Prendre une photo',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                  subtitle: Text(
                    'Utiliser la caméra',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.black54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _takePhoto(recto: recto);
                  },
                ),
                SizedBox(height: 6.h),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  leading: _sourceIcon(
                    Icons.photo_library_outlined,
                    Colors.blue,
                  ),
                  title: Text(
                    'Choisir depuis la galerie',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                  subtitle: Text(
                    'Sélectionner une photo existante',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.black54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromGallery(recto: recto);
                  },
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sourceIcon(IconData icon, Color color) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13.r),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 23.sp),
    );
  }

  // SUPPRESSION PHOTO

  void _removePhoto({required bool recto}) {
    if (_isSubmitting) return;

    setState(() {
      if (recto) {
        _rectoBytes = null;
        _rectoConfirmed = false;
      } else {
        _versoBytes = null;
        _versoConfirmed = false;
      }
    });
  }

  // VALIDATION PHOTO RECTO

  void _confirmRecto() {
    if (_rectoBytes == null) {
      _showError(
        _requiresVerso
            ? 'Veuillez d’abord prendre la photo du recto.'
            : 'Veuillez d’abord prendre la photo du document.',
      );
      return;
    }

    setState(() {
      _rectoConfirmed = true;
    });

    _showInfo(
      _requiresVerso
          ? 'Photo du recto validée. Vous pouvez maintenant ajouter le verso.'
          : 'Photo validée. Renseignez maintenant les informations.',
    );
  }

  void _confirmVerso() {
    if (_versoBytes == null) {
      _showError('Veuillez d’abord prendre la photo du verso.');
      return;
    }

    if (!_rectoConfirmed) {
      _showError('Veuillez d’abord valider la photo du recto.');
      return;
    }

    setState(() {
      _versoConfirmed = true;
    });

    _showInfo(
      'Les deux photos sont prêtes. Renseignez maintenant les informations.',
    );
  }

  // DATES

  Future<void> _selectDate({required bool emission}) async {
    final now = DateTime.now();

    final DateTime firstDate =
    emission ? DateTime(1950) : (_dateEmission ?? now);

    final DateTime lastDate = emission
        ? now
        : DateTime(now.year + 20, now.month, now.day);

    final initialDate = emission
        ? (_dateEmission ?? now)
        : (_dateExpiration ?? _dateEmission ?? now);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: _orange),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (emission) {
        _dateEmission = selected;

        if (_dateExpiration != null &&
            !_dateExpiration!.isAfter(selected)) {
          _dateExpiration = null;
        }
      } else {
        _dateExpiration = selected;
      }
    });
  }

  // VALIDATION FORMULAIRE

  bool _validateForm() {
    if (_rectoBytes == null) {
      _showError(
        _requiresVerso
            ? 'Veuillez ajouter la photo du recto.'
            : 'Veuillez ajouter la photo du document.',
      );
      return false;
    }

    if (!_rectoConfirmed) {
      _showError(
        _requiresVerso
            ? 'Veuillez valider la photo du recto.'
            : 'Veuillez valider la photo du document.',
      );
      return false;
    }

    if (_requiresVerso) {
      if (_versoBytes == null) {
        _showError('Veuillez ajouter la photo du verso.');
        return false;
      }

      if (!_versoConfirmed) {
        _showError('Veuillez valider la photo du verso.');
        return false;
      }
    }

    if (_numeroController.text.trim().isEmpty) {
      _showError('Veuillez saisir le numéro du document.');
      return false;
    }

    if (_dateEmission == null) {
      _showError('Veuillez sélectionner la date d’émission.');
      return false;
    }

    if (_dateExpiration == null) {
      _showError('Veuillez sélectionner la date d’expiration.');
      return false;
    }

    if (!_dateExpiration!.isAfter(_dateEmission!)) {
      _showError(
        'La date d’expiration doit être postérieure à la date d’émission.',
      );
      return false;
    }

    if (_paysController.text.trim().isEmpty) {
      _showError('Veuillez saisir le pays d’émission.');
      return false;
    }

    return true;
  }

  // ENVOI FINAL

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        rectoBytes: _rectoBytes!,
        versoBytes: _requiresVerso ? _versoBytes : null,
        numeroDocument: _numeroController.text.trim(),
        dateEmission: _dateEmission!,
        dateExpiration: _dateExpiration!,
        paysEmission: _paysController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Impossible d’envoyer les documents : $e');
    }
  }

  // MESSAGES

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('❌ $message'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
  }

  void _showInfo(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('✓ $message'),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
  }

  // BUILD PRINCIPAL

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 18.h),
          child: Column(
            children: [
              Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Vérification d’identité',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: _darkOrange,
                      ),
                    ),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
              SizedBox(height: 4.h),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderInstruction(),
        SizedBox(height: 20.h),

        //RECTO
        _buildPhotoSection(recto: true),

        //VERSO uniquement si obligatoire
        if (_requiresVerso) ...[
          SizedBox(height: 22.h),
          _buildPhotoSection(recto: false),
        ],

        SizedBox(height: 26.h),
        _buildInformationSection(),
        SizedBox(height: 24.h),
        _buildReadySummary(),
        SizedBox(height: 20.h),
        _buildMainButton(
          text: _isSubmitting
              ? 'Envoi en cours...'
              : 'Envoyer pour vérification',
          icon: Icons.send_outlined,
          loading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
        SizedBox(height: 10.h),
        Center(
          child: Text(
            'Aucun document ne sera envoyé avant votre confirmation finale.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10.5.sp,
              color: Colors.black45,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // HEADER INSTRUCTION

  Widget _buildHeaderInstruction() {
    final icon = _requiresVerso
        ? Icons.credit_card_outlined
        : Icons.public_outlined;

    final instruction = _requiresVerso
        ? 'Ajoutez le recto et le verso de votre carte. '
        'Vérifiez bien la qualité des photos avant de les envoyer.'
        : 'Ajoutez la page principale de votre passeport '
        '(page avec vos informations et votre photo).';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: _orange.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13.r),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: _orange, size: 23.sp),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.documentLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _darkOrange,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  instruction,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION PHOTO

  Widget _buildPhotoSection({required bool recto}) {
    final bytes = recto ? _rectoBytes : _versoBytes;
    final confirmed = recto ? _rectoConfirmed : _versoConfirmed;

    final label = recto
        ? (_requiresVerso ? 'RECTO' : 'DOCUMENT')
        : 'VERSO';

    final titleLabel = recto
        ? (_requiresVerso ? 'Photo RECTO' : 'Photo du document')
        : 'Photo VERSO';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: confirmed
              ? _success.withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: confirmed
                      ? _success.withValues(alpha: 0.10)
                      : _orange.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: confirmed
                    ? Icon(Icons.check, color: _success, size: 19.sp)
                    : Text(
                  recto ? '1' : '2',
                  style: GoogleFonts.inter(
                    color: _orange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      confirmed
                          ? 'Photo validée'
                          : bytes == null
                          ? 'Photo obligatoire'
                          : 'Vérifiez la qualité',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: confirmed ? _success : Colors.black45,
                        fontWeight: confirmed
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _buildPhotoPreview(bytes: bytes, label: label),
          SizedBox(height: 12.h),
          if (bytes == null)
            _buildMainButton(
              text: _requiresVerso
                  ? 'Ajouter le $label'
                  : 'Ajouter la photo',
              icon: Icons.camera_alt_outlined,
              onPressed: () => _showSourceChoice(recto: recto),
            )
          else
            _buildPhotoActions(recto: recto, confirmed: confirmed),
        ],
      ),
    );
  }

  Widget _buildPhotoActions({
    required bool recto,
    required bool confirmed,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSubmitting
                ? null
                : () => _removePhoto(recto: recto),
            icon: const Icon(Icons.delete_outline),
            label: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(
                color: Colors.red.withValues(alpha: 0.30),
              ),
              minimumSize: Size(0, 46.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSubmitting
                ? null
                : () => _showSourceChoice(recto: recto),
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              'Modifier',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: BorderSide(
                color: _orange.withValues(alpha: 0.35),
              ),
              minimumSize: Size(0, 46.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting
                ? null
                : confirmed
                ? null
                : () {
              if (recto) {
                _confirmRecto();
              } else {
                _confirmVerso();
              }
            },
            icon: Icon(
              confirmed ? Icons.check : Icons.check_circle_outline,
            ),
            label: Text(
              confirmed ? 'Validé' : 'Valider',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmed ? _success : _orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: confirmed
                  ? _success
                  : _orange.withValues(alpha: 0.45),
              minimumSize: Size(0, 46.h),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview({
    required Uint8List? bytes,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      height: 250.h,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 45.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8.h),
          Text(
            'Aucune photo $label',
            style: GoogleFonts.inter(
              color: Colors.grey[500],
              fontSize: 12.sp,
            ),
          ),
        ],
      )
          : Stack(
        fit: StackFit.expand,
        children: [

          InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: EdgeInsets.all(50.w),
            clipBehavior: Clip.none,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10.h,
            left: 10.w,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 5.h,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 10.w,
            top: 10.h,
            child: _photoQualityBadge(
              confirmed: label == 'VERSO'
                  ? _versoConfirmed
                  : _rectoConfirmed,
            ),
          ),
          Positioned(
            bottom: 10.h,
            right: 10.w,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 9.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 15.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Pincez pour zoomer',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
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


  Widget _photoQualityBadge({required bool confirmed}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 9.w,
        vertical: 5.h,
      ),
      decoration: BoxDecoration(
        color: confirmed
            ? _success
            : Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            confirmed ? Icons.check : Icons.visibility_outlined,
            color: Colors.white,
            size: 13.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            confirmed ? 'Validée' : 'À vérifier',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // INFORMATIONS

  Widget _buildInformationSection() {
    final photosReady = _requiresVerso
        ? (_rectoConfirmed && _versoConfirmed)
        : _rectoConfirmed;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.assignment_outlined,
                  color: _orange,
                  size: 19.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations du document',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      photosReady
                          ? 'Complétez les informations avant l’envoi.'
                          : 'Validez d’abord les photos.',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: photosReady
                            ? Colors.black45
                            : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          _buildLabel('Numéro du document'),
          SizedBox(height: 7.h),
          TextField(
            controller: _numeroController,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDecoration(
              hint: 'Ex. 123456789',
              icon: Icons.numbers_outlined,
            ),
          ),

          SizedBox(height: 16.h),

          _buildLabel('Date d’émission'),
          SizedBox(height: 7.h),
          _buildDateField(
            date: _dateEmission,
            hint: 'Sélectionner la date',
            icon: Icons.calendar_today_outlined,
            onTap: _isSubmitting
                ? () {}
                : () => _selectDate(emission: true),
          ),

          SizedBox(height: 16.h),

          _buildLabel('Date d’expiration'),
          SizedBox(height: 7.h),
          _buildDateField(
            date: _dateExpiration,
            hint: 'Sélectionner la date',
            icon: Icons.event_available_outlined,
            onTap: _isSubmitting
                ? () {}
                : _dateEmission == null
                ? () => _showError(
              'Sélectionnez d’abord la date d’émission.',
            )
                : () => _selectDate(emission: false),
          ),

          SizedBox(height: 16.h),

          _buildLabel('Pays d’émission'),
          SizedBox(height: 7.h),
          TextField(
            controller: _paysController,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              hint: 'Ex. Mali',
              icon: Icons.public_outlined,
            ),
          ),

          SizedBox(height: 18.h),

          Container(
            padding: EdgeInsets.all(13.w),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: _orange,
                  size: 20.sp,
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: Text(
                    'Valider les photos',
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      height: 1.4,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RÉSUMÉ AVANT ENVOI

  Widget _buildReadySummary() {
    final photosReady = _requiresVerso
        ? (_rectoConfirmed && _versoConfirmed)
        : _rectoConfirmed;

    final numeroReady = _numeroController.text.trim().isNotEmpty;
    final datesReady =
        _dateEmission != null && _dateExpiration != null;
    final paysReady = _paysController.text.trim().isNotEmpty;

    final ready = photosReady && numeroReady && datesReady && paysReady;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ready
            ? _success.withValues(alpha: 0.07)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ready
              ? _success.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                ready
                    ? Icons.verified_outlined
                    : Icons.pending_outlined,
                color: ready ? _success : Colors.grey[600],
                size: 21.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  ready
                      ? 'Dossier prêt à être envoyé'
                      : 'Dossier incomplet',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: ready ? _success : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          if (_requiresVerso) ...[
            _summaryItem(
              label: 'Photo recto',
              completed: _rectoConfirmed,
            ),
            _summaryItem(
              label: 'Photo verso',
              completed: _versoConfirmed,
            ),
          ] else
            _summaryItem(
              label: 'Photo du document',
              completed: _rectoConfirmed,
            ),

          _summaryItem(
            label: 'Numéro du document',
            completed: numeroReady,
          ),
          _summaryItem(
            label: 'Dates',
            completed: datesReady,
          ),
          _summaryItem(
            label: 'Pays d’émission',
            completed: paysReady,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required bool completed,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 7.h),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 17.sp,
            color: completed ? _success : Colors.grey[400],
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              color: completed ? Colors.black87 : Colors.black45,
              fontWeight: completed
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // HELPERS

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: _orange, size: 21.sp),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: _orange, width: 1.5),
      ),
    );
  }

  Widget _buildDateField({
    required DateTime? date,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 15.h,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: _orange, size: 21.sp),
            SizedBox(width: 11.w),
            Expanded(
              child: Text(
                date == null ? hint : _formatDate(date),
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: date == null
                      ? Colors.black45
                      : Colors.black87,
                  fontWeight: date == null
                      ? FontWeight.w400
                      : FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildMainButton({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _orange.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          elevation: 0,
        ),
        icon: loading
            ? SizedBox(
          width: 20.w,
          height: 20.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(icon),
        label: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}