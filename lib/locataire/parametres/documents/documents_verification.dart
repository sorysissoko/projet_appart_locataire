import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service/auth_service.dart';
import 'package:service/database_service.dart';
import 'package:service/service_locator.dart';
import '../../../widgets/parametre_header.dart';
import 'identity_capture_modal.dart';

class DocumentsVerificationPage extends StatefulWidget {
  const DocumentsVerificationPage({super.key});

  @override
  State<DocumentsVerificationPage> createState() =>
      _DocumentsVerificationPageState();
}

class _DocumentsVerificationPageState
    extends State<DocumentsVerificationPage> {
  final AuthService _auth = ServiceLocator.auth;
  final DatabaseService _db = ServiceLocator.database;

  List<Map<String, dynamic>> _documents = [];

  bool _isLoading = true;
  String? _errorMessage;

  static const Color _orange = Color(0xFFE85D26);
  static const Color _darkOrange = Color(0xFF8A4E1E);
  static const Color _background = Color(0xFFFFF2E5);

  static const String _cniType = 'carte_identite';
  static const String _passportType = 'passeport';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }


  // CHARGEMENT DES DOCUMENTS
    Future<void> _loadDocuments({
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
      if (_auth.currentUser == null) {
        throw Exception('Utilisateur non connecté.');
      }

      final documents =
      await _db.getCurrentUserIdentityDocuments();

      if (!mounted) return;

      setState(() {
        _documents = documents;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Impossible de charger vos documents : $e';
      });
    }
  }


  // OUVERTURE DU FLUX ADAPTÉ AU TYPE DE DOCUMENT
  void _openDocumentFlow(String typeDocument) {
    if (typeDocument == _cniType || typeDocument == _passportType) {
      _showIdentityCaptureModal(typeDocument: typeDocument);
    } else {
      _showDocumentSourceSheet(typeDocument: typeDocument);
    }
  }


  // MODAL CARTE D'IDENTITÉ PASSEPORT
    Future<void> _showIdentityCaptureModal({
    String typeDocument = 'carte_identite',
  }) async {
    if (!mounted) return;

    final isPassport = typeDocument == _passportType;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26.r),
        ),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.94,
          child: IdentityCaptureModal(
            requireVerso: !isPassport,
            documentLabel: isPassport
                ? 'Passeport'
                : 'Carte d’identité',

            onSubmit: ({
              required Uint8List rectoBytes,
              required Uint8List? versoBytes,
              required String numeroDocument,
              required DateTime dateEmission,
              required DateTime dateExpiration,
              required String paysEmission,
            }) async {
              await _db.uploadIdentityCardDocuments(
                rectoBytes: rectoBytes,
                versoBytes: versoBytes,
                numeroDocument: numeroDocument,
                dateEmission: dateEmission,
                dateExpiration: dateExpiration,
                paysEmission: paysEmission,
                typeDocument: typeDocument,
              );
            },
          ),
        );
      },
    );

    if (result == true && mounted) {
      await _loadDocuments(showSkeleton: false);

      if (!mounted) return;

      final label = isPassport ? 'passeport' : 'carte d’identité';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Votre $label a été envoyé. '
                'Il est maintenant en attente de vérification.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
                title: 'Documents et vérification',
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
      return _buildSkeleton();
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    return RefreshIndicator(
      color: _orange,
      onRefresh: () => _loadDocuments(
        showSkeleton: false,
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(),

            SizedBox(height: 22.h),

            _buildSectionTitle('PIÈCES D’IDENTITÉ'),

            _buildDocumentTypeCard(
              title: 'Carte d’identité',
              subtitle:
              'Document d’identité national en cours de validité',
              typeDocument: 'carte_identite',
              icon: Icons.badge_outlined,
            ),

            _buildDocumentTypeCard(
              title: 'Passeport',
              subtitle:
              'Passeport valide délivré par votre pays',
              typeDocument: 'passeport',
              icon: Icons.public_outlined,
            ),
          ],
        ),
      ),
    );
  }


  // INTRODUCTION
    Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _orange.withValues(alpha: 0.18),
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
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.security_outlined,
              color: _orange,
              size: 23.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vérifiez votre identité',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: _darkOrange,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  'Ajoutez une pièce d’identité valide. '
                      'Elle sera vérifiée par notre équipe avant '
                      'la certification de votre compte.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    height: 1.45,
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


  // CHOIX DE LA SOURCE PERMIS UNIQUEMENT
  Future<void> _showDocumentSourceSheet({
    required String typeDocument,
  }) async {
    if (!mounted) return;

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
            padding: EdgeInsets.fromLTRB(
              20.w,
              18.h,
              20.w,
              20.h,
            ),
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
                  'Ajouter une pièce',
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
                  leading: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: _orange,
                      size: 23.sp,
                    ),
                  ),
                  title: Text(
                    'Prendre une photo',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Utiliser la caméra pour photographier votre document',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.black54,
                    ),
                  ),
                ),

                SizedBox(height: 6.h),

                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  leading: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.blue[700],
                      size: 23.sp,
                    ),
                  ),
                  title: Text(
                    'Choisir depuis la galerie',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Sélectionner une photo ou un PDF existant',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.black54,
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
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


  // DOCUMENT IDENTITÉ ACTIF
    Map<String, dynamic>? _getActiveIdentityDocument() {
    final activeDocuments = _documents.where((document) {
      final statut = document['statut']?.toString();

      return statut != 'refuse' &&
          statut != 'expire';
    }).toList();

    if (activeDocuments.isEmpty) {
      return null;
    }

    activeDocuments.sort(
          (a, b) {
        final dateA = DateTime.tryParse(
          a['created_at']?.toString() ?? '',
        ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final dateB = DateTime.tryParse(
          b['created_at']?.toString() ?? '',
        ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return dateB.compareTo(dateA);
      },
    );

    return activeDocuments.first;
  }


  // TYPE DE DOCUMENT VERROUILLÉ

  bool _isDocumentTypeLocked(
      String typeDocument,
      ) {
    final activeDocument =
    _getActiveIdentityDocument();

    if (activeDocument == null) {
      return false;
    }

    final activeType =
    activeDocument['type_document']?.toString();

    return activeType != typeDocument;
  }


  // DOCUMENT REFUSÉ
    bool _hasRefusedDocument(
      String typeDocument,
      ) {
    return _documents.any(
          (document) =>
      document['type_document']?.toString() ==
          typeDocument &&
          document['statut']?.toString() ==
              'refuse',
    );
  }


  // CARTE D'IDENTITÉ — DOSSIER RECTO + VERSO

  Map<String, dynamic>? _getLatestIdentityCardDocument() {
    final cniDocuments = _documents
        .where(
          (document) =>
      document['type_document']?.toString() ==
          _cniType,
    )
        .toList();

    if (cniDocuments.isEmpty) {
      return null;
    }

    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final document in cniDocuments) {
      final numero =
      document['numero_document']?.toString().trim();

      final key = numero != null && numero.isNotEmpty
          ? numero
          : 'legacy_${document['id']}';

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(document);
    }

    List<Map<String, dynamic>>? latestGroup;
    DateTime latestDate =
    DateTime.fromMillisecondsSinceEpoch(0);

    for (final group in groups.values) {
      DateTime groupDate =
      DateTime.fromMillisecondsSinceEpoch(0);

      for (final document in group) {
        final createdAt = DateTime.tryParse(
          document['created_at']?.toString() ?? '',
        );

        if (createdAt != null &&
            createdAt.isAfter(groupDate)) {
          groupDate = createdAt;
        }
      }

      if (latestGroup == null ||
          groupDate.isAfter(latestDate)) {
        latestGroup = group;
        latestDate = groupDate;
      }
    }

    if (latestGroup == null ||
        latestGroup.isEmpty) {
      return null;
    }

    Map<String, dynamic>? recto;
    Map<String, dynamic>? verso;

    for (final document in latestGroup) {
      final cote =
      document['cote_document']?.toString();

      if (cote == 'recto') {
        recto = document;
      } else if (cote == 'verso') {
        verso = document;
      }
    }

    String statutGlobal;

    final rectoStatus = recto?['statut']?.toString();
    final versoStatus = verso?['statut']?.toString();

    final hasRecto = recto != null;
    final hasVerso = verso != null;

    if (!hasRecto || !hasVerso) {
      statutGlobal = 'en_attente';
    } else if (rectoStatus == 'refuse' ||
        versoStatus == 'refuse') {
      statutGlobal = 'refuse';
    } else if (rectoStatus == 'expire' ||
        versoStatus == 'expire') {
      statutGlobal = 'expire';
    } else if (rectoStatus == 'valide' &&
        versoStatus == 'valide') {
      statutGlobal = 'valide';
    } else if (rectoStatus == 'en_verification' ||
        versoStatus == 'en_verification') {
      statutGlobal = 'en_verification';
    } else {
      statutGlobal = 'en_attente';
    }

    final representative =
    Map<String, dynamic>.from(
      recto ?? verso!,
    );

    representative['_is_cni_dossier'] = true;
    representative['_cni_recto'] = recto;
    representative['_cni_verso'] = verso;
    representative['_cni_has_recto'] = hasRecto;
    representative['_cni_has_verso'] = hasVerso;
    representative['statut'] = statutGlobal;

    return representative;
  }


  // TYPE DE DOCUMENT

  Widget _buildDocumentTypeCard({
    required String title,
    required String subtitle,
    required String typeDocument,
    required IconData icon,
  }) {
    final Map<String, dynamic>? document =
    typeDocument == _cniType
        ? _getLatestIdentityCardDocument()
        : _findDocument(typeDocument);

    final isLocked =
    _isDocumentTypeLocked(typeDocument);

    final hasRefused =
    _hasRefusedDocument(typeDocument);

    final isDisabled =
        isLocked && document == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.48 : 1.0,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.withValues(alpha: 0.035)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDisabled
                ? Colors.grey.withValues(alpha: 0.10)
                : Colors.grey.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.withValues(alpha: 0.08)
                    : _orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: isDisabled
                    ? Colors.grey[500]
                    : _orange,
                size: 23.sp,
              ),
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isDisabled
                          ? Colors.grey[600]
                          : Colors.black87,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Text(
                    isDisabled
                        ? 'Indisponible tant que votre pièce actuelle est en cours de traitement'
                        : document == null
                        ? subtitle
                        : _getDocumentStatusText(
                      document,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: isDisabled
                          ? Colors.grey[500]
                          : document == null
                          ? Colors.black54
                          : _getStatusColor(
                        document['statut'],
                      ),
                      fontWeight: document == null
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),

                  if (hasRefused && !isDisabled)
                    Padding(
                      padding: EdgeInsets.only(
                        top: 5.h,
                      ),
                      child: Text(
                        'Vous pouvez soumettre cette pièce à nouveau.',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            _buildDocumentAction(
              document: document,
              typeDocument: typeDocument,
              disabled: isDisabled,
            ),
          ],
        ),
      ),
    );
  }


  // ACTION DOCUMENT

  Widget _buildDocumentAction({
    required Map<String, dynamic>? document,
    required String typeDocument,
    required bool disabled,
  }) {
    if (disabled) {
      return Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.lock_outline,
          color: Colors.grey[500],
          size: 21.sp,
        ),
      );
    }

    // AUCUN DOCUMENT

    if (document == null) {
      return Container(
        decoration: BoxDecoration(
          color: _orange,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: IconButton(
          onPressed: () => _openDocumentFlow(typeDocument),
          icon: Icon(
            Icons.camera_alt_outlined,
            color: Colors.white,
            size: 21.sp,
          ),
          tooltip: 'Ajouter une pièce',
        ),
      );
    }

    final statut =
    document['statut']?.toString();

    // VALIDÉ

    if (statut == 'valide') {
      return Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.green.withValues(
            alpha: 0.10,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.check_circle_outline,
          color: Colors.green[700],
          size: 23.sp,
        ),
      );
    }

    // REFUSÉ

    if (statut == 'refuse') {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(
            alpha: 0.10,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: IconButton(
          onPressed: () => _openDocumentFlow(typeDocument),
          icon: Icon(
            Icons.refresh,
            color: Colors.red[700],
            size: 21.sp,
          ),
          tooltip: 'Soumettre à nouveau',
        ),
      );
    }

    // EXPIRÉ

    if (statut == 'expire') {
      return Container(
        decoration: BoxDecoration(
          color: Colors.orange.withValues(
            alpha: 0.10,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: IconButton(
          onPressed: () => _openDocumentFlow(typeDocument),
          icon: Icon(
            Icons.refresh,
            color: Colors.orange[700],
            size: 21.sp,
          ),
          tooltip: 'Renouveler',
        ),
      );
    }

    // EN ATTENTE / EN VÉRIFICATION

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: statut == 'en_verification'
            ? Colors.blue.withValues(alpha: 0.10)
            : Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: Icon(
        statut == 'en_verification'
            ? Icons.manage_search_outlined
            : Icons.hourglass_empty,
        color: statut == 'en_verification'
            ? Colors.blue[700]
            : Colors.orange[700],
        size: 23.sp,
      ),
    );
  }

  // DOCUMENT LE PLUS RÉCENT D'UN TYPE

  Map<String, dynamic>? _findDocument(
      String typeDocument,
      ) {
    final matchingDocuments = _documents
        .where(
          (document) =>
      document['type_document']?.toString() ==
          typeDocument,
    )
        .toList();

    if (matchingDocuments.isEmpty) {
      return null;
    }

    matchingDocuments.sort(
          (a, b) {
        final dateA = DateTime.tryParse(
          a['created_at']?.toString() ?? '',
        ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final dateB = DateTime.tryParse(
          b['created_at']?.toString() ?? '',
        ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return dateB.compareTo(dateA);
      },
    );

    return matchingDocuments.first;
  }

  // STATUT DU DOCUMENT

  String _getDocumentStatusText(
      Map<String, dynamic> document,
      ) {
    final statut =
    document['statut']?.toString();

    final isCni =
        document['_is_cni_dossier'] == true;

    if (isCni) {
      final hasRecto =
          document['_cni_has_recto'] == true;

      final hasVerso =
          document['_cni_has_verso'] == true;

      if (!hasRecto || !hasVerso) {
        return 'Carte d’identité incomplète — recto et verso requis';
      }
    }

    switch (statut) {
      case 'en_attente':
        return isCni
            ? 'Carte d’identité envoyée — en attente de vérification'
            : 'Document envoyé — en attente de vérification';

      case 'en_verification':
        return isCni
            ? 'Carte d’identité en cours de vérification'
            : 'Document en cours de vérification';

      case 'valide':
        return isCni
            ? 'Carte d’identité vérifiée'
            : 'Document validé';

      case 'refuse':
        String? motif;

        if (isCni) {
          final recto =
          document['_cni_recto']
          as Map<String, dynamic>?;

          final verso =
          document['_cni_verso']
          as Map<String, dynamic>?;

          final rectoMotif =
          recto?['motif_refus']?.toString();

          final versoMotif =
          verso?['motif_refus']?.toString();

          if (rectoMotif != null &&
              rectoMotif.trim().isNotEmpty) {
            motif = rectoMotif;
          } else if (versoMotif != null &&
              versoMotif.trim().isNotEmpty) {
            motif = versoMotif;
          }
        } else {
          motif =
              document['motif_refus']?.toString();
        }

        if (motif != null &&
            motif.trim().isNotEmpty) {
          return isCni
              ? 'Carte d’identité refusée : $motif'
              : 'Document refusé : $motif';
        }

        return isCni
            ? 'Carte d’identité refusée'
            : 'Document refusé';

      case 'expire':
        return isCni
            ? 'Carte d’identité expirée'
            : 'Document expiré';

      default:
        return 'Statut inconnu';
    }
  }

  // COULEUR DU STATUT

  Color _getStatusColor(dynamic statut) {
    switch (statut?.toString()) {
      case 'valide':
        return Colors.green[700]!;

      case 'refuse':
      case 'expire':
        return Colors.red[700]!;

      case 'en_verification':
        return Colors.blue[700]!;

      case 'en_attente':
      default:
        return Colors.orange[700]!;
    }
  }

  // TITRE SECTION

  Widget _buildSectionTitle(
      String title,
      ) {
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

  // ERROR

  Widget _buildError() {
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
            _errorMessage ??
                'Une erreur est survenue.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
            onPressed: _loadDocuments,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }


  // SKELETON

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 40.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(
            height: 126.h,
            borderRadius: 20.r,
          ),

          SizedBox(height: 22.h),

          _SkeletonBox(
            width: 130.w,
            height: 13.h,
            borderRadius: 6.r,
          ),

          SizedBox(height: 8.h),

          _buildDocumentSkeleton(),
          _buildDocumentSkeleton(),
          _buildDocumentSkeleton(),
        ],
      ),
    );
  }

  Widget _buildDocumentSkeleton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: _SkeletonBox(
        height: 78.h,
        borderRadius: 16.r,
      ),
    );
  }
}

// SKELETON BOX

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    this.width,
    this.height,
    required this.borderRadius,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<_SkeletonBox> createState() =>
      _SkeletonBoxState();
}

class _SkeletonBoxState
    extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1000,
      ),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.45,
      end: 0.90,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(
            alpha: 0.12,
          ),
          borderRadius: BorderRadius.circular(
            widget.borderRadius,
          ),
        ),
      ),
    );
  }
}