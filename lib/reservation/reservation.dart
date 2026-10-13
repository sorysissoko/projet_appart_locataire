import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:service/database_service.dart';
import 'package:table_calendar/table_calendar.dart';

import '../locataire/parametres/modal_methode_paiement.dart';
import '../providers/tab_provider.dart';
import '../reservation/price_utils.dart';
import '../widgets/main_page.dart';


// CACHE GLOBAL

final Map<String, dynamic> _cachedData = {};

const String _cacheKeyReservations = 'reservations';
const String _cacheKeyDisponibilite = 'disponibilite';

Set<DateTime> _reservedDatesCache = {};

//Cache header (photo + résidence) par appartement
final Map<String, Map<String, dynamic>> _headerCache = {};


// STATUTS QUI BLOQUENT UNE PÉRIODE

const Set<String> _activeReservationStatuses = {
  'en_attente',
  'en_attente_paiement',
  'confirmee',
};


// PAGE RÉSERVATION
class ReservationPage extends StatefulWidget {
  final Map<String, dynamic> appartement;
  final Map<String, dynamic>? disponibilite;
  final Map<String, dynamic>? appartementRole;

  final DateTime? startDate;
  final DateTime? endDate;

  final double totalPrice;
  final int totalNights;

  final DatabaseService databaseService;

  const ReservationPage({
    super.key,
    required this.appartement,
    this.disponibilite,
    this.appartementRole,
    this.startDate,
    this.endDate,
    this.totalPrice = 0.0,
    this.totalNights = 0,
    required this.databaseService,
  });

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}


// STATE
class _ReservationPageState extends State<ReservationPage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;


  // PAIEMENT
  String? _selectedPaymentMethod;
  String? _selectedPaymentPhone;

  String? _headerPhotoUrl;
  bool _headerPhotoLoading = true;

  String? _residenceNom;

  String? _selectedPaymentProviderPaymentMethodId;
  String? _selectedPaymentProvider;
  String? _selectedPaymentCardBrand;
  String? _selectedPaymentCardLast4;
  String? _selectedPaymentIndicatif;

  double _totalPrice = 0.0;

  bool _isLoading = false;
  bool _disposed = false;

  late TextEditingController _messageController;

  bool _acceptedConditions = false;


  // OCCUPANTS
  int _nombreAdultes = 1;
  int _nombreEnfants = 0;

  // MODE DE PAIEMENT
  bool _payerTotalite = true;

  // PÉRIODES RÉSERVÉES
  List<Map<String, DateTime>> unavailableRanges = [];

  // INIT
  @override
  void initState() {
    super.initState();

    _messageController = TextEditingController();

    _selectedStartDate = widget.startDate;
    _selectedEndDate = widget.endDate;

    final nombreClient = int.tryParse(
      widget.appartementRole?['nombre_client']?.toString() ?? '',
    ) ??
        1;

    _nombreAdultes = nombreClient < 1 ? 1 : nombreClient;

    _cachedData[_cacheKeyDisponibilite] = widget.disponibilite;

    if (_selectedStartDate != null &&
        _selectedEndDate != null &&
        _selectedEndDate!.isAfter(_selectedStartDate!)) {
      _totalPrice = _calculateTotalValue(
        _selectedStartDate!,
        _selectedEndDate!,
      );
    } else {
      _totalPrice = 0.0;
    }


    //RÉUTILISER LES DONNÉES DÉJÀ CHARGÉES
    final appId = widget.appartement['id']?.toString();

    // Résidence déjà chargée ?
    final residenceData = widget.appartement['residence'];
    if (residenceData is Map) {
      _residenceNom = residenceData['nom']?.toString();
    }

    // Photos déjà chargées ?
    final photoUrls = widget.appartement['photo_urls'];
    if (photoUrls is List && photoUrls.isNotEmpty) {
      if (photoUrls.length > 2) {
        _headerPhotoUrl = photoUrls[2].toString();
      } else {
        _headerPhotoUrl = photoUrls.first.toString();
      }
    }

    // Cache statique ?
    if (appId != null && _headerCache.containsKey(appId)) {
      final cached = _headerCache[appId]!;
      _headerPhotoUrl ??= cached['photo'] as String?;
      _residenceNom ??= cached['residence'] as String?;
    }

    // Si on a déjà tout, pas de chargement réseau
    final needNetworkLoad =
        _headerPhotoUrl == null || _residenceNom == null;

    if (!needNetworkLoad) {
      _headerPhotoLoading = false;
    }


    //LANCER LES REQUÊTES EN PARALLÈLE
    Future.wait([
      if (needNetworkLoad) _loadHeaderPhoto(),
      _loadReservations(),
    ]);
  }


  // CHARGER PHOTO RÉSIDENCE EN PARALLÈLE
  Future<void> _loadHeaderPhoto() async {
    try {
      final appartementId = widget.appartement['id']?.toString();

      if (appartementId == null || appartementId.isEmpty) {
        if (mounted) {
          setState(() => _headerPhotoLoading = false);
        }
        return;
      }

      final residenceId =
      widget.appartement['residence_id']?.toString();

      //les 2 requêtes en parallèle avec typage explicite
      final results = await Future.wait<Map<String, dynamic>?>([
        // Requête photo ordre 2
        widget.databaseService.supabase
            .from('photo_appartements')
            .select('fichiername')
            .eq('appartement_id', appartementId)
            .eq('ordre_affichage', 2)
            .maybeSingle(),

        // Requête nom résidence
        if (residenceId != null && residenceId.isNotEmpty)
          widget.databaseService.supabase
              .from('residences')
              .select('nom')
              .eq('id', residenceId)
              .maybeSingle()
        else
          Future<Map<String, dynamic>?>.value(null),
      ]);
      if (!mounted) return;

      // Photo
      final photoResponse = results[0];
      String? url;
      final fileName = photoResponse?['fichiername']?.toString();

      if (fileName != null && fileName.isNotEmpty) {
        url = widget.databaseService.supabase.storage
            .from('appartements')
            .getPublicUrl('$appartementId/$fileName');
      }

      // Résidence
      final residenceResponse = results[1];
      final residenceNom =
      residenceResponse?['nom']?.toString();

      //Mettre en cache
      _headerCache[appartementId] = {
        'photo': url,
        'residence': residenceNom,
      };

      setState(() {
        _headerPhotoUrl = url ?? _headerPhotoUrl;
        _residenceNom = residenceNom ?? _residenceNom;
        _headerPhotoLoading = false;
      });

      debugPrint(
        'Header : photo=$_headerPhotoUrl | résidence=$_residenceNom',
      );
    } catch (e) {
      debugPrint('Erreur chargement header : $e');
      if (mounted) {
        setState(() => _headerPhotoLoading = false);
      }
    }
  }


  // CHARGER LES RÉSERVATIONS
  Future<void> _loadReservations() async {
    try {
      final reservations =
      await widget.databaseService.getReservationsByAppartement(
        widget.appartement['id'].toString(),
      );

      if (!mounted) return;

      final filteredReservations =
      _filterActiveReservations(reservations);

      _safeSetState(() {
        _cachedData[_cacheKeyReservations] =
            filteredReservations;

        _reservedDatesCache = _getReservedDates();
      });

      if (kDebugMode) {
        print(
          '${filteredReservations.length} réservations actives chargées',
        );
        print('${_reservedDatesCache.length} dates occupées');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur chargement réservations : $e');
      }
    }
  }


  // FILTRER LES RÉSERVATIONS BLOQUANTES
  List<Map<String, dynamic>> _filterActiveReservations(
      List<Map<String, dynamic>> reservations,
      ) {
    return reservations.where((reservation) {
      final status = reservation['statut']
          ?.toString()
          .toLowerCase()
          .trim();

      return status != null &&
          _activeReservationStatuses.contains(status);
    }).toList();
  }


  // NORMALISER UNE DATE
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }


  // PARSER UNE DATE
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return _normalizeDate(value);
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return null;

    return _normalizeDate(parsed);
  }


  // DATES RÉSERVÉES
  Set<DateTime> _getReservedDates() {
    final reservations =
    _cachedData[_cacheKeyReservations] as List<dynamic>?;

    if (reservations == null || reservations.isEmpty) {
      return {};
    }

    final Set<DateTime> reserved = {};

    for (final reservation in reservations) {
      try {
        final status = reservation['statut']
            ?.toString()
            .toLowerCase()
            .trim();

        if (status == null ||
            !_activeReservationStatuses.contains(status)) {
          continue;
        }

        final start = _parseDate(reservation['date_debut']);
        final end = _parseDate(reservation['date_fin']);

        if (start == null || end == null) continue;

        DateTime current = start;

        while (current.isBefore(end)) {
          reserved.add(_normalizeDate(current));
          current = current.add(const Duration(days: 1));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Erreur parsing réservation : $e');
        }
      }
    }

    return reserved;
  }


  // DISPOSE
  @override
  void dispose() {
    _disposed = true;
    _messageController.dispose();
    super.dispose();
  }


  // SAFE SET STATE
  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }


  // FORMAT DATE
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }


  // FORMAT DATE FRANÇAIS
  String _formatDateFrench(DateTime date) {
    final day = date.day;

    const monthNames = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    const weekdayNames = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    final month = monthNames[date.month - 1];
    final year = date.year;
    final weekday = weekdayNames[date.weekday - 1];

    return '$weekday $day $month $year';
  }


  // PRIX PROPRIÉTAIRE
  double _getPrixProprietaire() {
    return double.tryParse(
      widget.appartement['prix_proprietaire']?.toString() ??
          '0',
    ) ??
        0.0;
  }


  // FRAIS SERVICE
  double _getFraisService() {
    return double.tryParse(
      widget.appartement['frais_service']?.toString() ?? '0',
    ) ??
        0.0;
  }


  // PRIX PAR NUIT
  double _getPrixParNuit() {
    return _getPrixProprietaire() + _getFraisService();
  }


  // CALCUL TOTAL
  double _calculateTotalValue(DateTime start, DateTime end) {
    final nuits = end.difference(start).inDays;

    if (nuits <= 0) return 0.0;

    final reductions = calculerPrixAvecReduction(
      prixProprietaire: _getPrixProprietaire(),
      fraisService: _getFraisService(),
      nuits: nuits,
    );

    return (reductions['total'] ?? 0).toDouble();
  }


  // CONVERSION MÉTHODE DE PAIEMENT
  String _convertirMethodePaiement(String methodId) {
    switch (methodId) {
      case 'orange':
      case 'orange_money':
        return 'orange_money';

      case 'moov':
      case 'moov_money':
        return 'moov_money';

      case 'wave':
        return 'wave';

      case 'visa':
      case 'carte_bancaire':
        return 'carte_bancaire';

      default:
        throw Exception(
          'Méthode de paiement invalide : $methodId',
        );
    }
  }


  // DÉTAIL DU PAIEMENT
  Widget _buildDetailPaiementContent({
    required double prixParNuit,
    required int totalNuits,
    required double prixTotal,
    required double economie,
    required double fraisDuProApres,
    required double fraisServiceApres,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBottomSheetLine(
          'Nuitées',
          '$totalNuits nuit${totalNuits > 1 ? 's' : ''}',
        ),
        SizedBox(height: 12.h),
        _buildBottomSheetLine(
          'Prix par nuit',
          formatPrice(prixParNuit),
        ),
        SizedBox(height: 12.h),
        _buildBottomSheetLine(
          'Sous-total',
          formatPrice(prixParNuit * totalNuits),
        ),
        SizedBox(height: 12.h),
        if (economie > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Réduction',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.green,
                ),
              ),
              Text(
                '- ${formatPrice(economie)}',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        if (economie > 0) SizedBox(height: 12.h),
        _buildBottomSheetLine(
          'Frais du propriétaire',
          formatPrice(fraisDuProApres),
        ),
        SizedBox(height: 12.h),
        _buildBottomSheetLine(
          'Frais de service',
          formatPrice(fraisServiceApres),
        ),
        SizedBox(height: 15.h),
        const Divider(color: Colors.grey),
        SizedBox(height: 5.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatPrice(prixTotal),
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF7B32),
                    ),
                  ),
                  Container(
                    height: 3,
                    color: const Color(0xFFFF7B32),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
      ],
    );
  }


  // BUILD
  @override
  Widget build(BuildContext context) {
    final dateDebut = _selectedStartDate ??
        DateTime.now().add(const Duration(days: 1));

    final dateFin = _selectedEndDate ??
        dateDebut.add(const Duration(days: 2));

    final totalNuits = dateFin.difference(dateDebut).inDays;
    final nuits = totalNuits > 0 ? totalNuits : 0;

    final prixParNuit = _getPrixParNuit();

    final reductions = nuits > 0
        ? calculerPrixAvecReduction(
      prixProprietaire: _getPrixProprietaire(),
      fraisService: _getFraisService(),
      nuits: nuits,
    )
        : <String, dynamic>{
      'reductionProprietaire': 0.0,
      'reductionService': 0.0,
      'total': 0.0,
    };

    final reductionProprio =
    (reductions['reductionProprietaire'] ?? 0).toDouble();
    final reductionService =
    (reductions['reductionService'] ?? 0).toDouble();
    final prixTotalCalcule =
    (reductions['total'] ?? 0).toDouble();

    final totalProprioAvant =
        _getPrixProprietaire() * nuits;
    final totalServiceAvant = _getFraisService() * nuits;

    final fraisDuProApres =
        totalProprioAvant - reductionProprio;
    final fraisServiceApres =
        totalServiceAvant - reductionService;

    final prixSansReduction = prixParNuit * nuits;
    final economie =
    (prixSansReduction - prixTotalCalcule).clamp(
      0.0,
      double.infinity,
    );

    if (_totalPrice <= 0 && prixTotalCalcule > 0) {
      _totalPrice = prixTotalCalcule;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFEFE0),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildDatesContainer(dateDebut, dateFin),
                  _buildOccupantsContainer(),
                  _buildPaiementSections(
                    prixTotalCalcule,
                    prixParNuit,
                    nuits,
                    economie,
                    fraisDuProApres,
                    fraisServiceApres,
                  ),
                  _buildWhenToPaySection(),
                  _buildPaymentMethodSection(),
                  _buildMessageToHost(),
                  _buildNoteInfo(),
                  _buildConditionsCheckbox(),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: _buildTopNavigation(),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _buildReservationButton(),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE36830),
                    ),
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
    final titre = widget.appartement['titre']?.toString() ?? '';

    final List<String> photos = [];

    if (_headerPhotoUrl != null && _headerPhotoUrl!.isNotEmpty) {
      photos.add(_headerPhotoUrl!);
    } else {
      final imagesRaw = widget.appartement['images'];

      if (imagesRaw is List) {
        photos.addAll(
          imagesRaw
              .map((e) => e?.toString() ?? '')
              .where((url) => url.isNotEmpty),
        );
      }

      if (photos.isEmpty && widget.appartement['imageUrl'] != null) {
        photos.add(widget.appartement['imageUrl'].toString());
      }
    }

    final hasResidence =
        _residenceNom != null && _residenceNom!.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 25.h,
        horizontal: 15.w,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // PHOTO
          Container(
            decoration: BoxDecoration(
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Color(0x223B3A3A),
                  offset: Offset(3, 3),
                  spreadRadius: 5,
                ),
              ],
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: const Color(0x7C000000),
                width: 0.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.r),
              child: SizedBox(
                width: 160.w,
                height: 130.h,
                child: _headerPhotoLoading
                    ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFE36830),
                    ),
                  ),
                )
                    : (photos.isNotEmpty
                    ? GestureDetector(
                  onTap: () =>
                      _openFullScreenGallery(photos),
                  child: PageView.builder(
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final img = photos[index];

                      if (img.startsWith('http')) {
                        return Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Image.asset(
                                'assets/images/image.jpg',
                                fit: BoxFit.cover,
                              ),
                        );
                      }

                      return Image.asset(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                              ),
                            ),
                      );
                    },
                  ),
                )
                    : Image.asset(
                  'assets/images/image.jpg',
                  fit: BoxFit.cover,
                )),
              ),
            ),
          ),

          SizedBox(width: 20.w),

          // NOM RÉSIDENCE + TITRE
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasResidence) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE85D26)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFFE85D26)
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 13.sp,
                          color: const Color(0xFFE85D26),
                        ),
                        SizedBox(width: 5.w),
                        Flexible(
                          child: Text(
                            _residenceNom!,
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE85D26),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],

                Text(
                  titre.length > 15
                      ? titre.replaceAll(' ', '\n')
                      : titre,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // GALERIE
  void _openFullScreenGallery(List<String> photos) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final img = photos[index];

                    return InteractiveViewer(
                      panEnabled: true,
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: img.startsWith('http')
                            ? Image.network(
                          img,
                          fit: BoxFit.contain,
                        )
                            : Image.asset(
                          img,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE5CE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_fullscreen_outlined,
                        color: Color(0xFF8A4E1E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // DATES
  Widget _buildDatesContainer(
      DateTime dateDebut,
      DateTime dateFin,
      ) {
    final nuits = dateFin.difference(dateDebut).inDays;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 10.h,
        horizontal: 12.w,
      ),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5EC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: const Color(0xFFFFF5EC),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: const Color(0xFFE36830),
                          size: 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Dates',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF673A15),
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _openDateRangeModal,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE36830),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Modifier',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arrivée',
                            style: GoogleFonts.poppins(
                              color: const Color(0xA6673A15),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatDate(dateDebut),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF673A15),
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text(
                        'au',
                        style: GoogleFonts.poppins(
                          color: const Color(0xA6673A15),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Départ',
                            style: GoogleFonts.poppins(
                              color: const Color(0xA6673A15),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatDate(dateFin),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF673A15),
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 5.h,
                    horizontal: 12.w,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xA6673A15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      '$nuits nuit${nuits > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // OCCUPANTS
  Widget _buildOccupantsContainer() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 5.h,
        horizontal: 12.w,
      ),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5EC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: const Color(0xFFFFF5EC),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: const Color(0xFFE36830),
                          size: 24.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Occupants',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF673A15),
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _modifierOccupants,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE36830),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Modifier',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOccupantType('Adultes', _nombreAdultes),
                    _buildOccupantType('Enfants', _nombreEnfants),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOccupantType(String type, int nombre) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '$nombre',
              style: GoogleFonts.poppins(
                color: const Color(0xFF673A15),
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 5.w),
            Text(
              type,
              style: GoogleFonts.poppins(
                color: const Color(0xA6673A15),
                fontSize: 17.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }


  // DÉTAIL DU PRIX
  Widget _buildPaiementSections(
      double totalFinal,
      double prixParNuit,
      int totalNuits,
      double economie,
      double fraisDuProApres,
      double fraisServiceApres,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 5.h,
      ),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5EC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: const Color(0xFFFFF5EC),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Détail du prix',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF673A15),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _showDetailPaiementBottomSheet(
                            prixParNuit,
                            totalNuits,
                            totalFinal,
                            economie,
                            fraisDuProApres,
                            fraisServiceApres,
                          ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE36830),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Détail',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatPrice(totalFinal),
                            style: GoogleFonts.poppins(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF7B32),
                            ),
                          ),
                          Container(
                            height: 3,
                            color: const Color(0xFFFF7B32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // MODE DE PAIEMENT
  Widget _buildWhenToPaySection() {
    final double prixTotal = _totalPrice;
    final double acompte = (prixTotal * 0.30).roundToDouble();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 5.h,
      ),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5EC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: const Color(0xFFFFF5EC),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisir le mode de paiement',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF673A15),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () {
                    _safeSetState(() {
                      _payerTotalite = true;
                      _clearPaymentSelection();
                    });
                  },
                  child: _buildPaymentModeCard(
                    selected: _payerTotalite,
                    title: 'Payer la totalité',
                    subtitle:
                    'Paiement sécurisé de la totalité du séjour',
                    amount: prixTotal,
                  ),
                ),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () {
                    _safeSetState(() {
                      _payerTotalite = false;
                      _clearPaymentSelection();
                    });
                  },
                  child: _buildPaymentModeCard(
                    selected: !_payerTotalite,
                    title: 'Payer un acompte',
                    subtitle: 'Payer 30 % du prix maintenant',
                    amount: acompte,
                    amountLabel: 'Acompte',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentModeCard({
    required bool selected,
    required String title,
    required String subtitle,
    required double amount,
    String amountLabel = 'Montant',
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFFFEFE6)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: selected
              ? const Color(0xFFE36830)
              : const Color(0xA6D8B191),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? const Color(0xFFE36830)
                  : const Color(0xA6D8B191),
              size: 24.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF673A15),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xA6673A15),
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$amountLabel : ${formatPrice(amount)}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFE36830),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // EFFACER PAIEMENT
  void _clearPaymentSelection() {
    _selectedPaymentMethod = null;
    _selectedPaymentPhone = null;
    _selectedPaymentProviderPaymentMethodId = null;
    _selectedPaymentProvider = null;
    _selectedPaymentCardBrand = null;
    _selectedPaymentCardLast4 = null;
    _selectedPaymentIndicatif = null;
  }


  // MÉTHODE DE PAIEMENT
  Widget _buildPaymentMethodSection() {
    String getMethodDisplayName(String methodId) {
      switch (methodId) {
        case 'orange':
          return 'Orange Money';
        case 'moov':
          return 'Moov Money';
        case 'wave':
          return 'Wave';
        case 'visa':
          return 'Carte bancaire';
        default:
          return methodId;
      }
    }

    Widget getMethodIcon(String methodId) {
      switch (methodId) {
        case 'orange':
          return Image.asset(
            'assets/images/orangemoney.png',
            width: 30.w,
            height: 20.h,
          );
        case 'moov':
          return Image.asset(
            'assets/images/Moov_Africa_Malitel_(logo).png',
            width: 30.w,
            height: 20.h,
          );
        case 'wave':
          return Image.asset(
            'assets/images/wave-logo.png',
            width: 30.w,
            height: 20.h,
          );
        case 'visa':
          return Image.asset(
            'assets/images/visa.png',
            width: 30.w,
            height: 20.h,
          );
        default:
          return const Icon(Icons.payment, size: 20);
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 5.h,
      ),
      child: GestureDetector(
        onTap: openPaymentModal,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EC),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: const Color(0xFFFFF5EC),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Méthode de paiement',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF673A15),
                                fontSize: 21.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedPaymentMethod == null)
                              Padding(
                                padding: EdgeInsets.only(left: 8.w),
                                child: Text(
                                  '*',
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontSize: 18.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        if (_selectedPaymentMethod != null) ...[
                          Row(
                            children: [
                              getMethodIcon(_selectedPaymentMethod!),
                              SizedBox(width: 10.w),
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getMethodDisplayName(
                                      _selectedPaymentMethod!,
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF673A15),
                                    ),
                                  ),
                                  if (_selectedPaymentPhone != null)
                                    Text(
                                      _selectedPaymentPhone!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (_selectedPaymentCardLast4 !=
                                      null)
                                    Text(
                                      'Carte : **** ${_selectedPaymentCardLast4!}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'Sélectionnez un moyen de paiement',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/visa.png',
                                width: 45.w,
                                height: 25.h,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(width: 10.w),
                              Image.asset(
                                'assets/images/orangemoney1.png',
                                width: 85.w,
                                height: 25.h,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(width: 10.w),
                              Image.asset(
                                'assets/images/Moov_Africa_Malitel.png',
                                width: 55.w,
                                height: 25.h,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(width: 10.w),
                              Image.asset(
                                'assets/images/wave-logo1.png',
                                width: 65.w,
                                height: 25.h,
                                fit: BoxFit.cover,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xE58A4E1E),
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // MESSAGE
  Widget _buildMessageToHost() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 5.h,
      ),
      child: GestureDetector(
        onTap: _showMessageDialog,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EC),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: const Color(0xFFFFF5EC),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Écrire un message',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF673A15),
                            fontSize: 21.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          _messageController.text.isEmpty
                              ? 'Ajouter un message...'
                              : _messageController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: const Color(0x80673A15),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xE58A4E1E),
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // NOTE
  Widget _buildNoteInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 10.h,
      ),
      child: Text(
        "L'hôte a 24 heures pour confirmer votre demande. "
            "Vous serez invité à effectuer le paiement après la confirmation.",
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: const Color(0xE58A4E1E),
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }


  // NAVIGATION
    Widget _buildTopNavigation() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.close_outlined,
              color: Color(0xFF8A4E1E),
              size: 35,
            ),
          ),
        ],
      ),
    );
  }


  // BOUTON RÉSERVATION
    Widget _buildReservationButton() {
    final bool isButtonDisabled = _isLoading ||
        _selectedPaymentMethod == null ||
        !_acceptedConditions;

    return Center(
      child: GestureDetector(
        onTap: isButtonDisabled ? null : _demanderReservation,
        child: Container(
          width: 323.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: isButtonDisabled
                ? const Color(0x8BC5521B)
                : const Color(0xFFE85D26),
            borderRadius: BorderRadius.circular(50.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBAB83)
                    .withValues(alpha: 0x3A),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? SizedBox(
              width: 24.w,
              height: 24.h,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              'Demander la réservation',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 23.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }


  // CALENDRIER
  Future<void> _openDateRangeModal() async {
    try {
      final freshReservations =
      await widget.databaseService.getReservationsByAppartement(
        widget.appartement['id'].toString(),
      );

      if (!mounted) return;

      final activeReservations =
      _filterActiveReservations(freshReservations);

      _safeSetState(() {
        _cachedData[_cacheKeyReservations] = activeReservations;
        _reservedDatesCache = _getReservedDates();
      });

      DateTime? tempStart = _selectedStartDate;
      DateTime? tempEnd = _selectedEndDate;

      final disponibilite = _cachedData[_cacheKeyDisponibilite];

      final CalendarStyle calendarStyle = CalendarStyle(
        todayDecoration: const BoxDecoration(
          color: Color(0xFFFF1D1D),
          shape: BoxShape.circle,
        ),
        rangeStartDecoration: const BoxDecoration(
          color: Color(0xFFC5521B),
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: const BoxDecoration(
          color: Color(0xFFC5521B),
          shape: BoxShape.circle,
        ),
        withinRangeDecoration: const BoxDecoration(
          color: Color(0xFFC5521B),
          shape: BoxShape.circle,
        ),
      );

      final CalendarBuilders calendarBuilders = CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final normalized = _normalizeDate(day);

          if (_reservedDatesCache.contains(normalized)) {
            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          return null;
        },
      );

      bool isRangeAvailable(DateTime start, DateTime end) {
        final normalizedStart = _normalizeDate(start);
        final normalizedEnd = _normalizeDate(end);

        if (!normalizedEnd.isAfter(normalizedStart)) {
          return false;
        }

        for (final reserved in _reservedDatesCache) {
          if (reserved.isBefore(normalizedEnd) &&
              reserved.isAfter(normalizedStart
                  .subtract(const Duration(days: 1)))) {
            return false;
          }
        }

        final dispoStart = _parseDate(disponibilite?['date_debut']);
        final dispoEnd = _parseDate(disponibilite?['date_fin']);

        if (dispoStart != null &&
            normalizedStart.isBefore(dispoStart)) {
          return false;
        }

        if (dispoEnd != null &&
            normalizedEnd.isAfter(dispoEnd)) {
          return false;
        }

        return true;
      }

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              DateTime focusedDay = tempStart ?? DateTime.now();

              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                  MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height:
                  MediaQuery.of(context).size.height * 0.64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin:
                        const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE6EB),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      Text(
                        'Sélectionnez vos dates',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (disponibilite != null &&
                          disponibilite['date_debut'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 5,
                          ),
                          child: Text(
                            'Disponible à partir du '
                                '${_formatDateFrench(
                              _parseDate(disponibilite['date_debut']) ??
                                  DateTime.now(),
                            )}',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: const Color(0xE58A4E1E),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      TableCalendar(
                        firstDay: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                        lastDay: DateTime(
                          DateTime.now().year + 2,
                          12,
                          31,
                        ),
                        focusedDay: focusedDay,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Mois',
                        },
                        rangeSelectionMode:
                        RangeSelectionMode.toggledOn,
                        rangeStartDay: tempStart,
                        rangeEndDay: tempEnd,
                        calendarStyle: calendarStyle,
                        calendarBuilders: calendarBuilders,
                        onPageChanged: (newFocusedDay) {
                          focusedDay = newFocusedDay;
                        },
                        onRangeSelected:
                            (start, end, focusedDay) {
                          setModalState(() {
                            if (start != null && end != null) {
                              final normalizedStart =
                              _normalizeDate(start);
                              final normalizedEnd =
                              _normalizeDate(end);

                              if (!isRangeAvailable(
                                normalizedStart,
                                normalizedEnd,
                              )) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Certaines dates ne sont pas disponibles ❌',
                                    ),
                                  ),
                                );
                                return;
                              }

                              tempStart = normalizedStart;
                              tempEnd = normalizedEnd;
                            } else if (start != null) {
                              tempStart = _normalizeDate(start);
                              tempEnd = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          if (tempStart == null || tempEnd == null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Veuillez sélectionner une date d’arrivée et une date de départ.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!tempEnd!.isAfter(tempStart!)) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La date de départ doit être après la date d’arrivée.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!isRangeAvailable(tempStart!, tempEnd!)) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "La plage sélectionnée n'est pas disponible.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final newTotal = _calculateTotalValue(
                            tempStart!,
                            tempEnd!,
                          );

                          _safeSetState(() {
                            _selectedStartDate = tempStart;
                            _selectedEndDate = tempEnd;
                            _totalPrice = newTotal;
                            _clearPaymentSelection();
                          });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFFE36830),
                        ),
                        child: Text(
                          'Confirmer',
                          style: GoogleFonts.poppins(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        _showErrorMessage(
          'Impossible de charger les disponibilités : $e',
        );
      }
    }
  }


  // DATE SÉLECTIONNABLE
  bool isDateSelectable(DateTime day) {
    final normalized = _normalizeDate(day);
    return !_reservedDatesCache.contains(normalized);
  }


  // OCCUPANTS
  Future<void> _modifierOccupants() async {
    final maxClientsFromRole = int.tryParse(
      widget.appartementRole?['nombre_client']?.toString() ?? '',
    ) ??
        10;

    final maxAdultes =
    maxClientsFromRole < 1 ? 1 : maxClientsFromRole;

    int tempAdultes = _nombreAdultes;
    int tempEnfants = _nombreEnfants;

    if (tempAdultes > maxAdultes) {
      tempAdultes = maxAdultes;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool canAddAdult() {
              final total = tempAdultes + tempEnfants;
              return total < 10 && tempAdultes < maxAdultes;
            }

            bool canAddChild() {
              final total = tempAdultes + tempEnfants;
              return total < 10;
            }

            final totalOccupants = tempAdultes + tempEnfants;
            final maxReached = totalOccupants >= 10;
            final maxFromRoleReached = tempAdultes >= maxAdultes;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom:
                    MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60.w,
                        height: 5.h,
                        margin:
                        EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius:
                          BorderRadius.circular(3.r),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Modifier les occupants',
                              style: GoogleFonts.poppins(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF7B32),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.pop(context),
                              icon: Icon(
                                Icons.close,
                                size: 24.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      if (maxReached || maxFromRoleReached)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius:
                              BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.orange[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange[800],
                                  size: 20.sp,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    maxReached
                                        ? 'Maximum 10 occupants au total'
                                        : 'Maximum $maxAdultes adultes pour cet appartement',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 20.h,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildOccupantEditorRow(
                              context: context,
                              label: 'Adultes',
                              subtitle: 'Âge 13+',
                              count: tempAdultes,
                              min: 1,
                              canAdd: canAddAdult(),
                              onRemove: () {
                                if (tempAdultes > 1) {
                                  setModalState(() {
                                    tempAdultes--;
                                  });
                                }
                              },
                              onAdd: () {
                                if (canAddAdult()) {
                                  setModalState(() {
                                    tempAdultes++;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        maxFromRoleReached
                                            ? 'Maximum $maxAdultes adultes autorisés'
                                            : 'Maximum 10 occupants au total',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            SizedBox(height: 30.h),
                            _buildOccupantEditorRow(
                              context: context,
                              label: 'Enfants',
                              subtitle: 'Âge 2-12',
                              count: tempEnfants,
                              min: 0,
                              canAdd: canAddChild(),
                              onRemove: () {
                                if (tempEnfants > 0) {
                                  setModalState(() {
                                    tempEnfants--;
                                  });
                                }
                              },
                              onAdd: () {
                                if (canAddChild()) {
                                  setModalState(() {
                                    tempEnfants++;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Maximum 10 occupants au total',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            SizedBox(height: 20.h),
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius:
                                BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total occupants',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '$totalOccupants',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16.sp,
                                          fontWeight:
                                          FontWeight.bold,
                                          color: maxReached
                                              ? Colors.orange[800]
                                              : const Color(
                                            0xF11F2937,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '/10',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 30.h),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: Text(
                                      'Annuler',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.sp,
                                        fontWeight:
                                        FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15.w),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _safeSetState(() {
                                        _nombreAdultes = tempAdultes;
                                        _nombreEnfants = tempEnfants;
                                      });
                                      Navigator.pop(context);
                                    },
                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      const Color(0xFFFF7B32),
                                    ),
                                    child: Text(
                                      'Confirmer',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.sp,
                                        fontWeight:
                                        FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // LIGNE MODIFICATION OCCUPANTS
  Widget _buildOccupantEditorRow({
    required BuildContext context,
    required String label,
    required String subtitle,
    required int count,
    required int min,
    required bool canAdd,
    required VoidCallback onRemove,
    required VoidCallback onAdd,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xF11F2937),
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: count > min ? onRemove : null,
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: count > min
                      ? Colors.grey[200]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: count > min
                        ? Colors.grey[400]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.remove,
                    size: 22.sp,
                    color: count > min
                        ? Colors.grey[700]
                        : Colors.grey[400],
                  ),
                ),
              ),
            ),
            SizedBox(width: 15.w),
            SizedBox(
              width: 50.w,
              child: Center(
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xF11F2937),
                  ),
                ),
              ),
            ),
            SizedBox(width: 15.w),
            GestureDetector(
              onTap: canAdd ? onAdd : null,
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: canAdd
                      ? const Color(0xFFFF7B32)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 22.sp,
                    color: canAdd
                        ? Colors.white
                        : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  // BOTTOM SHEET DÉTAIL PAIEMENT
  Future<void> _showDetailPaiementBottomSheet(
      double prixParNuit,
      int totalNuits,
      double prixTotal,
      double economie,
      double fraisDuProApres,
      double fraisServiceApres,
      ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60.w,
                  height: 5.h,
                  margin: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Détails du paiement',
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF7B32),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          size: 24.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.grey),
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 15.h,
                  ),
                  child: _buildDetailPaiementContent(
                    prixParNuit: prixParNuit,
                    totalNuits: totalNuits,
                    prixTotal: prixTotal,
                    economie: economie,
                    fraisDuProApres: fraisDuProApres,
                    fraisServiceApres: fraisServiceApres,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // LIGNE BOTTOM SHEET
  Widget _buildBottomSheetLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            color: const Color(0xBE1F2937),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xF11F2937),
          ),
        ),
      ],
    );
  }


  // MODAL PAIEMENT
  Future<void> openPaymentModal() async {
    if (_selectedStartDate == null || _selectedEndDate == null) {
      _showSafeSnackBar(
        'Veuillez d’abord sélectionner vos dates.',
      );
      return;
    }

    final totalNights = _selectedEndDate!
        .difference(_selectedStartDate!)
        .inDays;

    if (totalNights <= 0) {
      _showSafeSnackBar(
        'Les dates sélectionnées sont invalides.',
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) => PaymentBottomSheet(
        amount: _totalPrice,
        onSuccess: (
            method,
            phone,
            indicatifPaiement,
            providerPaymentMethodId,
            provider,
            cardBrand,
            cardLast4,
            ) {
          if (!mounted) return;

          _safeSetState(() {
            _selectedPaymentMethod = method;
            _selectedPaymentPhone = phone;
            _selectedPaymentIndicatif = indicatifPaiement;
            _selectedPaymentProviderPaymentMethodId =
                providerPaymentMethodId;
            _selectedPaymentProvider = provider;
            _selectedPaymentCardBrand = cardBrand;
            _selectedPaymentCardLast4 = cardLast4;
          });

          debugPrint('💳 Méthode : $method');
        },
        appartement: widget.appartement,
        totalNights: totalNights,
        totalPrice: _totalPrice,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      ),
    );
  }


  // MESSAGE HÔTE
  Future<void> _showMessageDialog() async {
    if (!mounted) return;

    final controller = TextEditingController(
      text: _messageController.text,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Message à l\'hôte'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
              'Écrivez un message à l\'hôte (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null && mounted) {
      _safeSetState(() {
        _messageController.text = result;
      });
    }
  }


  // CONDITIONS
  Widget _buildConditionsCheckbox() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 10.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _acceptedConditions,
            activeColor: const Color(0xFFE85D26),
            side: const BorderSide(
              color: Color(0xFFE85D26),
              width: 2,
            ),
            onChanged: (value) {
              _safeSetState(() {
                _acceptedConditions = value ?? false;
              });
            },
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/conditions');
                },
                child: Text(
                  "J'accepte les conditions d'utilisation",
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    color: const Color(0xFFE85D26),
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFFE85D26),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // VÉRIFICATION DISPONIBILITÉ
  Future<bool> _verifierDisponibilitesCompletes(
      DateTime startDate,
      DateTime endDate,
      ) async {
    final start = _normalizeDate(startDate);
    final end = _normalizeDate(endDate);

    if (!end.isAfter(start)) return false;

    final freshReservations =
    await widget.databaseService.getReservationsByAppartement(
      widget.appartement['id'].toString(),
    );

    final activeReservations =
    _filterActiveReservations(freshReservations);

    _safeSetState(() {
      _cachedData[_cacheKeyReservations] = activeReservations;
      _reservedDatesCache = _getReservedDates();
    });

    for (final res in activeReservations) {
      final resStart = _parseDate(res['date_debut']);
      final resEnd = _parseDate(res['date_fin']);

      if (resStart == null || resEnd == null) continue;

      final conflit =
          start.isBefore(resEnd) && end.isAfter(resStart);

      if (conflit) {
        if (kDebugMode) {
          print(
            '❌ Conflit : ${_formatDate(resStart)} → ${_formatDate(resEnd)}',
          );
        }
        return false;
      }
    }

    final disponibilite =
    await widget.databaseService.fetchNextDisponibilite(
      widget.appartement['id'].toString(),
    );

    if (disponibilite == null) return false;

    final dispoStart = _parseDate(disponibilite['date_debut']);
    final dispoEnd = _parseDate(disponibilite['date_fin']);

    if (dispoStart != null && start.isBefore(dispoStart)) {
      return false;
    }
    if (dispoEnd != null && end.isAfter(dispoEnd)) {
      return false;
    }

    return true;
  }


  // CRÉER DEMANDE RÉSERVATION
  Future<void> _demanderReservation() async {
    if (_isLoading || !mounted) return;

    if (_selectedStartDate == null || _selectedEndDate == null) {
      _showSafeSnackBar(
        'Veuillez sélectionner des dates de séjour valides.',
      );
      return;
    }

    final totalNuits = _selectedEndDate!
        .difference(_selectedStartDate!)
        .inDays;

    if (totalNuits <= 0) {
      _showSafeSnackBar(
        'La date de départ doit être après la date d’arrivée.',
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      _showSafeSnackBar(
        'Veuillez choisir une méthode de paiement.',
      );
      return;
    }

    if (!_acceptedConditions) {
      _showSafeSnackBar(
        "Veuillez accepter les conditions d'utilisation.",
      );
      return;
    }

    if (_nombreAdultes < 1) {
      _showSafeSnackBar(
        'Le nombre d’adultes doit être supérieur ou égal à 1.',
      );
      return;
    }

    if (_nombreEnfants < 0) {
      _showSafeSnackBar(
        'Le nombre d’enfants est invalide.',
      );
      return;
    }

    if (_nombreAdultes + _nombreEnfants > 10) {
      _showSafeSnackBar(
        'Le nombre maximum est de 10 occupants.',
      );
      return;
    }

    final totalCalcule = _calculateTotalValue(
      _selectedStartDate!,
      _selectedEndDate!,
    );

    if (totalCalcule <= 0) {
      _showSafeSnackBar(
        'Impossible de calculer le montant de la réservation.',
      );
      return;
    }

    _safeSetState(() {
      _isLoading = true;
    });

    try {
      final datesDisponibles =
      await _verifierDisponibilitesCompletes(
        _selectedStartDate!,
        _selectedEndDate!,
      );

      if (!datesDisponibles) {
        _showSafeSnackBar(
          '⚠️ Ces dates ne sont plus disponibles. '
              'Veuillez en sélectionner d’autres.',
          backgroundColor: Colors.red,
        );

        _safeSetState(() {
          _isLoading = false;
        });
        return;
      }

      final dateDebutFormattee = DateFormat('yyyy-MM-dd')
          .format(_selectedStartDate!);
      final dateFinFormattee = DateFormat('yyyy-MM-dd')
          .format(_selectedEndDate!);

      final howToPay = _payerTotalite ? 'totalite' : 'acompte';
      final methodePaiement =
      _convertirMethodePaiement(_selectedPaymentMethod!);

      final bool isMobileMoney =
          _selectedPaymentMethod == 'orange_money' ||
              _selectedPaymentMethod == 'moov_money' ||
              _selectedPaymentMethod == 'wave';

      final telephonePaiement =
      isMobileMoney ? _selectedPaymentPhone : null;
      final indicatifPaiement =
      isMobileMoney ? _selectedPaymentIndicatif : null;

      final reservationId =
      await widget.databaseService.createReservation(
        appartementId: widget.appartement['id'].toString(),
        dateDebut: dateDebutFormattee,
        dateFin: dateFinFormattee,
        momentPaiement: howToPay,
        methodePaiement: methodePaiement,
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        adultes: _nombreAdultes,
        enfants: _nombreEnfants,
        telephonePaiement: telephonePaiement,
        indicatifPaiement: indicatifPaiement,
        providerPaymentMethodId:
        _selectedPaymentProviderPaymentMethodId,
        provider: _selectedPaymentProvider,
        cardBrand: _selectedPaymentCardBrand,
        cardLast4: _selectedPaymentCardLast4,
      );

      if (kDebugMode) {
        print('✅ Réservation créée : $reservationId');
      }

      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      _showSuccessMessage();
    } catch (error) {
      if (kDebugMode) {
        print('❌ Erreur création réservation : $error');
      }

      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
      });

      _showErrorMessage(_cleanErrorMessage(error));
    }
  }


  // NETTOYER MESSAGE ERREUR
  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }


  // SNACKBAR
  void _showSafeSnackBar(
      String message, {
        Color backgroundColor = Colors.orange,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: 24.h,
          left: 20.w,
          right: 20.w,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }


  // MESSAGE SUCCÈS
  void _showSuccessMessage() {
    if (!mounted) return;

    final tabProvider = context.read<TabProvider>();

    Timer? timer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      enableDrag: false,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (BuildContext modalContext) {
        void closeAndGoHome() {
          if (!mounted) return;

          timer?.cancel();
          tabProvider.goToHome();

          if (Navigator.canPop(modalContext)) {
            Navigator.pop(modalContext);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const MainPage(),
                ),
                    (route) => false,
              );
            });
          }
        }

        timer = Timer(
          const Duration(seconds: 5),
          closeAndGoHome,
        );

        final nuits = (_selectedStartDate != null &&
            _selectedEndDate != null)
            ? _selectedEndDate!
            .difference(_selectedStartDate!)
            .inDays
            : 0;

        return Container(
          padding: EdgeInsets.all(24.r),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80.w,
                height: 80.h,
                decoration: const BoxDecoration(
                  color: Color(0xFF00C853),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Demande envoyée ! 🎉',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF7B32),
                ),
              ),
              SizedBox(height: 12.h),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF718096),
                    fontSize: 15.sp,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Votre demande de réservation pour ',
                    ),
                    TextSpan(
                      text:
                      '${widget.appartement['titre'] ?? 'Appartement'} ',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '${widget.appartement['ville'] ?? ''} ',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: 'a été envoyée à l’hôte. '
                          'Vous serez invité à effectuer le paiement '
                          'après la confirmation de la réservation.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              if (nuits > 0)
                Text(
                  '${formatPrice(_totalPrice)} - '
                      '$nuits nuit${nuits > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF7B32),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: closeAndGoHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7B32),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    "Retour à l'accueil",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      timer?.cancel();
    });
  }


  // MESSAGE ERREUR
  void _showErrorMessage(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: 24.h,
          left: 20.w,
          right: 20.w,
        ),
        elevation: 4,
        backgroundColor: const Color(0xFFE53E3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 5),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 24.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white70,
          onPressed: () => messenger.hideCurrentSnackBar(),
        ),
      ),
    );
  }
}