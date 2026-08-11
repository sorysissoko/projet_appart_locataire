import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:service/database_service.dart';
import 'package:table_calendar/table_calendar.dart';
import '../parametres/modal_methode_paiement.dart';
import '../providers/tab_provider.dart';
import '../reservation/price_utils.dart';
import '../widgets/main_page.dart';

// Cache pour stocker les données (disponibilité et réservations)
final Map<String, dynamic> _cachedData = {};

// Clés pour le cache
const String _cacheKeyReservations = 'reservations';
const String _cacheKeyDisponibilite = 'disponibilite';

// Set des dates réservées (calculé à partir des réservations)
Set<DateTime> _reservedDatesCache = {};

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

class _ReservationPageState extends State<ReservationPage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  String? _selectedPaymentMethod;
  String? _selectedPaymentPhone;
  String? _selectedPaymentCard;

  double _totalPrice = 0.0;
  bool _isLoading = false;
  late TextEditingController _messageController;
  bool _disposed = false;

  bool _acceptedConditions = false;

  // Variables pour les occupants
  int _nombreAdultes = 1;
  int _nombreEnfants = 0;

  // Variable pour l'option de paiement
  bool _payerMaintenant = true;

  // Liste des périodes déjà réservées
  List<Map<String, DateTime>> unavailableRanges = [];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _selectedStartDate = widget.startDate;
    _selectedEndDate = widget.endDate;
    _nombreAdultes = widget.appartementRole?['nombre_client'] ?? 1;

    // Stocker la disponibilité dans le cache
    _cachedData[_cacheKeyDisponibilite] = widget.disponibilite;

    // Charger les réservations au démarrage
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      final reservations = await widget.databaseService.getReservationsByAppartement(
        widget.appartement['id'].toString(),
      );
      if (!mounted) return;
      setState(() {
        _cachedData[_cacheKeyReservations] = reservations;
        _reservedDatesCache = _getReservedDates();
      });
      if (kDebugMode) {
        print('📊 ${reservations.length} réservations chargées');
      }
      if (kDebugMode) {
        print('📅 ${_reservedDatesCache.length} dates réservées');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement réservations : $e');
      }
    }
  }

  Set<DateTime> _getReservedDates() {
    final reservations = _cachedData[_cacheKeyReservations] as List<dynamic>?;
    if (reservations == null) return {};

    final Set<DateTime> reserved = {};
    for (var res in reservations) {
      try {
        final start = DateTime.parse(res['date_debut']);
        final end = DateTime.parse(res['date_fin']);
        DateTime current = start;
        while (!current.isAfter(end)) {
          reserved.add(DateTime(current.year, current.month, current.day));
          current = current.add(const Duration(days: 1));
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur parsing réservation: $e');
        }
      }
    }
    return reserved;
  }

  @override
  void dispose() {
    _disposed = true;
    _messageController.dispose();
    super.dispose();
  }

  void _safeSetState(void Function() fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  // Méthodes de formatage de dates
  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  String _formatDateFrench(DateTime date) {
    final day = date.day;
    final monthNames = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final month = monthNames[date.month - 1];
    final year = date.year;

    final weekdayNames = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    final weekday = weekdayNames[date.weekday - 1];

    return '$weekday $day $month $year';
  }

  // ==================== WIDGET DE DÉTAIL DU PAIEMENT (RÉUTILISABLE) ====================

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
        _buildBottomSheetLine('Nuitées', '$totalNuits nuit${totalNuits > 1 ? 's' : ''}'),
        SizedBox(height: 12.h),
        _buildBottomSheetLine('Prix par nuit', formatPrice(prixParNuit)),
        SizedBox(height: 12.h),
        _buildBottomSheetLine('Sous-total', formatPrice(prixParNuit * totalNuits)),
        SizedBox(height: 12.h),
        if (economie > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Réduction',
                style: TextStyle(fontSize: 14.sp, color: Colors.green),
              ),
              Text(
                '- ${formatPrice(economie)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        if (economie > 0) SizedBox(height: 12.h),
        _buildBottomSheetLine('Frais du propriétaire', formatPrice(fraisDuProApres)),
        SizedBox(height: 12.h),
        _buildBottomSheetLine('Frais de service', formatPrice(fraisServiceApres)),
        SizedBox(height: 15.h),
        const Divider(color: Colors.grey),
        SizedBox(height: 5.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: TextStyle(
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
                    style: TextStyle(
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
            )
          ],
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final dateDebut = _selectedStartDate ?? DateTime.now().add(const Duration(days: 1));
    final dateFin = _selectedEndDate ?? dateDebut.add(const Duration(days: 2));
    final totalNuits = dateFin.difference(dateDebut).inDays;

    // Sécurité
    final nuits = totalNuits <= 0 ? 1 : totalNuits;

    // Prix propriétaire
    final prixProprietaire = double.tryParse(
      widget.appartement['prix_proprietaire']?.toString() ?? '0',
    ) ?? 0.0;

    // Frais de service fixe
    final fraisService = double.tryParse(
      widget.appartement['frais_service']?.toString() ?? '0',
    ) ?? 0.0;

    // Prix affiché
    final prixParNuit = double.tryParse(
      widget.appartement['prix']?.toString() ?? '0',
    ) ?? 0.0;

    // ✅ UTILISE LA FONCTION DE price_utils.dart
    final reductions = calculerPrixAvecReduction(
      prixProprietaire: prixProprietaire,
      fraisService: fraisService,
      nuits: nuits,
    );

    final reductionProprio = reductions['reductionProprietaire']!;
    final reductionService = reductions['reductionService']!;

    final totalProprioAvant = prixProprietaire * totalNuits;
    final totalServiceAvant = fraisService * totalNuits;

    final fraisDuProApres = totalProprioAvant - reductionProprio;
    final fraisServiceApres = totalServiceAvant - reductionService;
    _totalPrice = reductions['total']!;

    final prixSansReduction = prixParNuit * nuits;
    final economie = prixSansReduction - _totalPrice;

    return Scaffold(
      backgroundColor: Color(0xFFFFEFE0),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildHeader(),
                  _buildDatesContainer(dateDebut, dateFin),
                  _buildOccupantsContainer(),
                  _buildPaiementSections(
                    _totalPrice,
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

  // ==================== WIDGETS EXISTANTS ====================

  Widget _buildHeader() {
    final titre = widget.appartement['titre']?.toString() ?? "";
    final List<String> photos = widget.appartement['images'] != null
        ? (widget.appartement['images'] as List)
        .map((e) => e.toString())
        .toList()
        : (widget.appartement['imageUrl'] != null
        ? [widget.appartement['imageUrl'].toString()]
        : []);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 25.h, horizontal: 15.w),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  color: const Color(0x223B3A3A),
                  offset: const Offset(3, 3),
                  spreadRadius: 5,
                )
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
                child: Stack(
                  children: [
                    photos.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        _openFullScreenGallery(photos);
                      },
                      child: PageView.builder(
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          final img = photos[index];

                          return img.startsWith('http')
                              ? Image.network(
                            img,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/image.jpg',
                                fit: BoxFit.cover,
                              );
                            },
                          )
                              : Image.asset(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          );
                        },
                      ),
                    )
                        : Image.asset(
                      'assets/images/image.jpg',
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: 25.w),

          Expanded(
            child: Text(
              titre.length > 15 ? titre.replaceAll(' ', '\n') : titre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 23.sp,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                            ? Image.network(img, fit: BoxFit.contain)
                            : Image.asset(img, fit: BoxFit.contain),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5CE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_fullscreen_outlined, color: Color(0xFF8A4E1E)),
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

  Widget _buildDatesContainer(DateTime dateDebut, DateTime dateFin) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFFFF5EC),
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
                          color: Color(0xFFE36830),
                          size: 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Dates',
                          style: TextStyle(
                            color: Color(0xFF673A15),
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _openDateRangeModal,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE36830),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Modifier',
                          style: TextStyle(
                            color: const Color(0xFFFFFFFF),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
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
                            style: TextStyle(
                              color: Color(0xA6673A15),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            _formatDate(dateDebut),
                            style: TextStyle(
                              color: Color(0xFF673A15),
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text(
                        'au',
                        style: TextStyle(
                          color: Color(0xA6673A15),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Départ',
                            style: TextStyle(
                              color: Color(0xA6673A15),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            _formatDate(dateFin),
                            style: TextStyle(
                              color: const Color(0xFF673A15),
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
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
                  padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: Color(0xA6673A15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      '${dateFin.difference(dateDebut).inDays} nuits',
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
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

  Widget _buildOccupantsContainer() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 12.w),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFFFF5EC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Color(0xFFFFF5EC),
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
                          color: Color(0xFFE36830),
                          size: 24.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Occupants',
                          style: TextStyle(
                            color: Color(0xFF673A15),
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _modifierOccupants(),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE36830),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Modifier',
                          style: TextStyle(
                            color: const Color(0xFFFFFFFF),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$nombre',
              style: TextStyle(
                color: Color(0xFF673A15),
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(width: 5.w),
            Text(
              type,
              style: TextStyle(
                color: Color(0xA6673A15),
                fontSize: 17.sp,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaiementSections(
      double totalFinal,
      double prixParNuit,
      int totalNuits,
      double economie,
      double fraisDuProApres,
      double fraisServiceApres,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFFFFF5EC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Color(0xFFFFF5EC),
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
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF673A15),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showDetailPaiementBottomSheet(
                        prixParNuit,
                        totalNuits,
                        totalFinal,
                        economie,
                        fraisDuProApres,
                        fraisServiceApres,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Color(0xFFE36830),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text('Détail',
                          style: TextStyle(
                            color: const Color(0xFFFFFFFF),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatPrice(totalFinal),
                            style: TextStyle(
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

  Widget _buildWhenToPaySection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFFFFF5EC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Color(0xFFFFF5EC),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisir quand payer',
                  style: TextStyle(
                    color: Color(0xFF673A15),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () {
                    _safeSetState(() {
                      _payerMaintenant = true;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _payerMaintenant ? Color(0xFFFFEFE6) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: _payerMaintenant ? Color(0xFFE36830) : Color(0xA6D8B191),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Row(
                        children: [
                          Icon(
                            _payerMaintenant ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: _payerMaintenant ? Color(0xFFE36830) : Color(0xA6D8B191),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payer maintenant',
                                  style: TextStyle(
                                    color: Color(0xFF673A15),
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  'Paiement sécurisé immédiat',
                                  style: TextStyle(
                                    color: Color(0xA6673A15),
                                    fontSize: 14.sp,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () {
                    _safeSetState(() {
                      _payerMaintenant = false;
                      _selectedPaymentMethod = null;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_payerMaintenant ? Color(0xFFFFEFE6) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: !_payerMaintenant ? Color(0xFFE36830) : Color(0xA6D8B191),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Row(
                        children: [
                          Icon(
                            !_payerMaintenant ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: !_payerMaintenant ? Color(0xFFE36830) : Color(0xA6D8B191),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payer à l\'arrivée',
                                  style: TextStyle(
                                    color: Color(0xFF673A15),
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  'Paiement sur place à votre arrivée',
                                  style: TextStyle(
                                    color: Color(0xA6673A15),
                                    fontSize: 14.sp,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
          return Image.asset('assets/images/orangemoney.png', width: 30.w, height: 20.h);
        case 'moov':
          return Image.asset('assets/images/Moov_Africa_Malitel_(logo).png', width: 30.w, height: 20.h);
        case 'wave':
          return Image.asset('assets/images/wave-logo.png', width: 30.w, height: 20.h);
        case 'visa':
          return Image.asset('assets/images/visa.png', width: 30.w, height: 20.h);
        default:
          return const Icon(Icons.payment, size: 20);
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      child: GestureDetector(
        onTap: _payerMaintenant ? openPaymentModal : null,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _payerMaintenant ? Color(0xFFFFF5EC) : Color(0x80FFF5EC),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFFFF5EC)),
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
                              style: TextStyle(
                                color: _payerMaintenant ? Color(0xFF673A15) : Color(0xA6673A15),
                                fontSize: 21.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                            if (_payerMaintenant && _selectedPaymentMethod == null)
                              Padding(
                                padding: EdgeInsets.only(left: 8.w),
                                child: Text(
                                  '*',
                                  style: TextStyle(color: Colors.red, fontSize: 18.sp),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        if (_payerMaintenant && _selectedPaymentMethod != null) ...[
                          Row(
                            children: [
                              getMethodIcon(_selectedPaymentMethod!),
                              SizedBox(width: 10.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getMethodDisplayName(_selectedPaymentMethod!),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF673A15),
                                    ),
                                  ),
                                  if (_selectedPaymentPhone != null)
                                    Text(
                                      _selectedPaymentPhone!,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (_selectedPaymentCard != null)
                                    Text(
                                      'Carte: **** ${_selectedPaymentCard!.length > 4 ? _selectedPaymentCard!.substring(_selectedPaymentCard!.length - 4) : _selectedPaymentCard}',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ] else if (_payerMaintenant) ...[
                          Text(
                            'Sélectionnez un moyen de paiement',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Row(
                            children: [
                              Opacity(
                                opacity: _payerMaintenant ? 1.0 : 0.5,
                                child: Image.asset(
                                  'assets/images/visa.png',
                                  width: 45.w,
                                  height: 25.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Opacity(
                                opacity: _payerMaintenant ? 1.0 : 0.5,
                                child: Image.asset(
                                  'assets/images/orangemoney1.png',
                                  width: 85.w,
                                  height: 25.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Opacity(
                                opacity: _payerMaintenant ? 1.0 : 0.5,
                                child: Image.asset(
                                  'assets/images/Moov_Africa_Malitel.png',
                                  width: 55.w,
                                  height: 25.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Opacity(
                                opacity: _payerMaintenant ? 1.0 : 0.5,
                                child: Image.asset(
                                  'assets/images/wave-logo1.png',
                                  width: 65.w,
                                  height: 25.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: _payerMaintenant ? Color(0xE58A4E1E) : Color(0x8C8A4E1E),
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

  Widget _buildMessageToHost() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      child: GestureDetector(
        onTap: _showMessageDialog,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFFFF5EC),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: Color(0xFFFFF5EC),
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
                          style: TextStyle(
                            color: Color(0xFF673A15),
                            fontSize: 21.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          _messageController.text.isEmpty
                              ? 'Ajouter un message...'
                              : _messageController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _messageController.text.isEmpty
                                ? Color(0x80673A15)
                                : Color(0x80673A15),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
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

  Widget _buildNoteInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        children: [
          Text(
            'L\'hôte a 24 heures pour confirmer votre réservation. Vous serez facturé après l\'acceptation de la demande.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xE58A4E1E),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildReservationButton() {
    bool isButtonDisabled =
        _isLoading ||
            (_payerMaintenant && _selectedPaymentMethod == null) ||
            !_acceptedConditions;

    return Center(
      child: GestureDetector(
        onTap: isButtonDisabled ? null : _demanderReservation,
        child: Container(
          width: 323.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: isButtonDisabled
                ? Color(0x8BC5521B)
                : Color(0xFFE85D26),
            borderRadius: BorderRadius.circular(50.r),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFBAB83).withValues(alpha: 0x3A),
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
                color: Color(0xFFE85D26),
                strokeWidth: 2,
              ),
            )
                : Text(
              'Demander la réservation',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 📅 MÉTHODE MODIFIÉE POUR LE CALENDRIER
  Future<void> _openDateRangeModal() async {
    // 1. Charger les réservations FRAÎCHES
    final freshReservations = await widget.databaseService.getReservationsByAppartement(
      widget.appartement['id'].toString(),
    );

    if (!mounted) return;

    // 2. Mettre à jour le cache
    setState(() {
      _cachedData[_cacheKeyReservations] = freshReservations;
      _reservedDatesCache = _getReservedDates();
    });

    if (kDebugMode) {
      print('📊 ${freshReservations.length} réservations chargées');
    }
    if (kDebugMode) {
      print('📅 ${_reservedDatesCache.length} dates réservées');
    }

    DateTime? tempStart = _selectedStartDate;
    DateTime? tempEnd = _selectedEndDate;

    final disponibilite = _cachedData[_cacheKeyDisponibilite];

    final CalendarStyle calendarStyle = CalendarStyle(
      todayDecoration: BoxDecoration(
        color: const Color(0xFFFF1D1D),
        shape: BoxShape.circle,
      ),
      rangeStartDecoration: BoxDecoration(
        color: const Color(0xFFC5521B),
        shape: BoxShape.circle,
      ),
      rangeEndDecoration: BoxDecoration(
        color: const Color(0xFFC5521B),
        shape: BoxShape.circle,
      ),
      withinRangeDecoration: BoxDecoration(
        color: const Color(0xFFC5521B),
        shape: BoxShape.circle,
      ),
    );

    // 🔴 CALENDAR BUILDERS AVEC DATES RÉSERVÉES EN ROUGE
    final CalendarBuilders calendarBuilders = CalendarBuilders(
      defaultBuilder: (context, day, focusedDay) {
        final normalized = DateTime(day.year, day.month, day.day);
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
              style: const TextStyle(
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
      for (final reserved in _reservedDatesCache) {
        if (!reserved.isBefore(start) && !reserved.isAfter(end)) {
          return false;
        }
      }
      return true;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.64,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6EB),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30.r),
                        ),
                      ),
                    ),
                    Text(
                      'Sélectionnez vos dates',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (disponibilite != null && disponibilite['date_debut'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                        child: Column(
                          children: [
                            Text(
                              'Disponible à partir du ${_formatDateFrench(disponibilite['date_debut']!)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xE58A4E1E),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime(DateTime.now().year + 2),
                      focusedDay: tempStart ?? DateTime.now(),
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Mois',
                      },
                      rangeSelectionMode: RangeSelectionMode.toggledOn,
                      rangeStartDay: tempStart,
                      rangeEndDay: tempEnd,
                      calendarStyle: calendarStyle,
                      calendarBuilders: calendarBuilders,
                      onRangeSelected: (start, end, focusedDay) {
                        setModalState(() {
                          if (start != null && end != null) {
                            tempStart = start;
                            tempEnd = end;

                            if (!isRangeAvailable(start, end)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Certaines dates sont déjà réservées ❌"),
                                ),
                              );
                            }
                          } else if (start != null && end == null) {
                            tempStart = start;
                            tempEnd = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                        onPressed: () {
                          if (tempStart != null && tempEnd != null && isRangeAvailable(tempStart!, tempEnd!)) {
                            setState(() {
                              _selectedStartDate = tempStart;
                              _selectedEndDate = tempEnd;
                              _calculateTotal();
                            });
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: const Color(0xFFFF9966),
                                duration: const Duration(seconds: 3),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning, color: Colors.red, size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      "La plage sélectionnée n'est pas disponible.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE36830),
                        ),
                        child: Text(
                          'Confirmer',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFFFFFFFF),
                          ),
                        )
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool isDateSelectable(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return !_reservedDatesCache.contains(normalized);
  }

  void _calculateTotal() {
    if (_selectedStartDate == null || _selectedEndDate == null) return;

    final nuits = _selectedEndDate!.difference(_selectedStartDate!).inDays;
    if (nuits <= 0) return;

    final prixProprietaire = double.tryParse(
      widget.appartement['prix_proprietaire']?.toString() ?? '0',
    ) ?? 0.0;
    final fraisService = double.tryParse(widget.appartement['frais_service']?.toString() ?? '0') ?? 0.0;

    // utilisation de price_utils.dart
    final reductions = calculerPrixAvecReduction(
      prixProprietaire: prixProprietaire,
      fraisService: fraisService,
      nuits: nuits,
    );

    setState(() {
      _totalPrice = reductions['total']!;
    });
  }

  Future<void> _modifierOccupants() async {
    final maxClientsFromRole = widget.appartementRole?['nombre_client'] ?? 10;

    int tempAdultes = _nombreAdultes;
    int tempEnfants = _nombreEnfants;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool canAddAdult() {
              final total = tempAdultes + tempEnfants;
              return total < 10 && tempAdultes < maxClientsFromRole;
            }

            bool canAddChild() {
              final total = tempAdultes + tempEnfants;
              return total < 10;
            }

            final totalOccupants = tempAdultes + tempEnfants;
            final maxReached = totalOccupants >= 10;
            final maxFromRoleReached = tempAdultes >= maxClientsFromRole;

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
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
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
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Modifier les occupants',
                              style: TextStyle(
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
                      if (maxReached || maxFromRoleReached)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          child: Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.orange[200]!),
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
                                        : 'Maximum $maxClientsFromRole adultes pour cet appartement',
                                    style: TextStyle(
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
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Adultes',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xF11F2937),
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                    Text(
                                      'Âge 13+',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                    Text(
                                      'Max: $maxClientsFromRole',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Color(0xB0FF7B32),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (tempAdultes > 1) {
                                          setModalState(() {
                                            tempAdultes--;
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: 40.w,
                                        height: 40.h,
                                        decoration: BoxDecoration(
                                          color: tempAdultes > 1
                                              ? Colors.grey[200]
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(20.r),
                                          border: Border.all(
                                            color: tempAdultes > 1
                                                ? Colors.grey[400]!
                                                : Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.remove,
                                            size: 22.sp,
                                            color: tempAdultes > 1
                                                ? Colors.grey[700]
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 15.w),
                                    Container(
                                      width: 50.w,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$tempAdultes',
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xF11F2937),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 15.w),
                                    GestureDetector(
                                      onTap: () {
                                        if (canAddAdult()) {
                                          setModalState(() {
                                            tempAdultes++;
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                maxFromRoleReached
                                                    ? 'Maximum $maxClientsFromRole adultes autorisés'
                                                    : 'Maximum 10 occupants au total',
                                              ),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: 40.w,
                                        height: 40.h,
                                        decoration: BoxDecoration(
                                          color: canAddAdult()
                                              ? const Color(0xFFFF7B32)
                                              : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(20.r),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.add,
                                            size: 22.sp,
                                            color: canAddAdult()
                                                ? Colors.white
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 30.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Enfants',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xF11F2937),
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                    Text(
                                      'Âge 2-12',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (tempEnfants > 0) {
                                          setModalState(() {
                                            tempEnfants--;
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: 40.w,
                                        height: 40.h,
                                        decoration: BoxDecoration(
                                          color: tempEnfants > 0
                                              ? Colors.grey[200]
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(20.r),
                                          border: Border.all(
                                            color: tempEnfants > 0
                                                ? Colors.grey[400]!
                                                : Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.remove,
                                            size: 22.sp,
                                            color: tempEnfants > 0
                                                ? Colors.grey[700]
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 15.w),
                                    Container(
                                      width: 50.w,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$tempEnfants',
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xF11F2937),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 15.w),
                                    GestureDetector(
                                      onTap: () {
                                        if (canAddChild()) {
                                          setModalState(() {
                                            tempEnfants++;
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Maximum 10 occupants au total'),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: 40.w,
                                        height: 40.h,
                                        decoration: BoxDecoration(
                                          color: canAddChild()
                                              ? const Color(0xFFFF7B32)
                                              : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(20.r),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.add,
                                            size: 22.sp,
                                            color: canAddChild()
                                                ? Colors.white
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total occupants',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '$totalOccupants',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: maxReached
                                              ? Colors.orange[800]
                                              : const Color(0xF11F2937),
                                        ),
                                      ),
                                      Text(
                                        '/10',
                                        style: TextStyle(
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
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 16.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      side: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Annuler',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
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
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF7B32),
                                      padding: EdgeInsets.symmetric(vertical: 16.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                    ),
                                    child: Text(
                                      'Confirmer',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
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
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Détails du paiement',
                        style: TextStyle(
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
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
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

  Widget _buildBottomSheetLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            color: const Color(0xBE1F2937),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xF11F2937),
          ),
        ),
      ],
    );
  }

  Future<void> openPaymentModal() async {
    final _ = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => PaymentBottomSheet(
        amount: _totalPrice,
        onSuccess: (method, phone, card) {
          setState(() {
            _selectedPaymentMethod = method;
            _selectedPaymentPhone = phone;
            _selectedPaymentCard = card;
          });
          debugPrint('Méthode: $method, Téléphone: $phone, Carte: $card');
        },
        appartement: widget.appartement,
        totalNights: _selectedEndDate!.difference(_selectedStartDate!).inDays,
        totalPrice: _totalPrice,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      ),
    );
  }

  Future<void> _showMessageDialog() async {
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController(text: _messageController.text);
        return AlertDialog(
          title: const Text('Message à l\'hôte'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Écrivez un message à l\'hôte (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      _safeSetState(() {
        _messageController.text = result;
      });
    }
  }

  Widget _buildConditionsCheckbox() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
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
              setState(() {
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
                  style: TextStyle(
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

  //VÉRIFICATION DE DISPONIBILITÉ
  Future<bool> _verifierDisponibilitesCompletes(
      DateTime startDate,
      DateTime endDate,
      ) async {

    // 1. Vérifier les réservations existantes
    final freshReservations = await widget.databaseService.getReservationsByAppartement(
      widget.appartement['id'].toString(),
    );

    if (kDebugMode) {
      print('📊 ${freshReservations.length} réservations existantes');
    }

    for (var res in freshReservations) {
      final resStart = DateTime.parse(res['date_debut']);
      final resEnd = DateTime.parse(res['date_fin']);

      // Vérifier si les dates chevauchent une réservation existante
      if (!(endDate.isBefore(resStart) || startDate.isAfter(resEnd))) {
        if (kDebugMode) {
          print('❌ Conflit avec réservation: ${_formatDate(resStart)} -> ${_formatDate(resEnd)}');
        }
        setState(() {
          _cachedData[_cacheKeyReservations] = freshReservations;
          _reservedDatesCache = _getReservedDates();
        });
        return false;
      }
    }

    // 2. Vérifier la disponibilité
    final disponibilite = await widget.databaseService.fetchNextDisponibilite(
      widget.appartement['id'].toString(),
    );


    if (disponibilite == null) {
      if (kDebugMode) {
        print('❌ Aucune disponibilité trouvée');
      }
      return false;
    }

    // Vérifier la date de début
    if (disponibilite['date_debut'] != null) {
      final dispoStart = disponibilite['date_debut']!;
      final dispoStartNormalized = DateTime(
        dispoStart.year,
        dispoStart.month,
        dispoStart.day,
      );
      final startNormalized = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      if (kDebugMode) {
        print('📅 Début disponibilité: ${_formatDate(dispoStartNormalized)}');
      }
      if (kDebugMode) {
        print('📅 Début séjour demandé: ${_formatDate(startNormalized)}');
      }

      if (startNormalized.isBefore(dispoStartNormalized)) {
        if (kDebugMode) {
          print('❌ Date de début avant la disponibilité');
        }
        return false;
      }
    }

    // Vérifier la date de fin
    if (disponibilite['date_fin'] != null) {
      final dispoEnd = disponibilite['date_fin']!;
      final dispoEndNormalized = DateTime(
        dispoEnd.year,
        dispoEnd.month,
        dispoEnd.day,
      );
      final endNormalized = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      );

      if (kDebugMode) {
        print('📅 Fin disponibilité: ${_formatDate(dispoEndNormalized)}');
      }
      if (kDebugMode) {
        print('📅 Fin séjour demandé: ${_formatDate(endNormalized)}');
      }

      if (endNormalized.isAfter(dispoEndNormalized)) {
        if (kDebugMode) {
          print('❌ Date de fin après la disponibilité');
        }
        return false;
      }
    }

    if (kDebugMode) {
      print('✅ Toutes les vérifications sont OK');
    }
    return true;
  }

  Future<void> _demanderReservation() async {
    if (_isLoading || !mounted) return;

    if (_selectedStartDate == null || _selectedEndDate == null) {
      _showSafeSnackBar('Veuillez sélectionner des dates de séjour valides');
      return;
    }

    _safeSetState(() => _isLoading = true);

    try {
      final datesDisponibles = await _verifierDisponibilitesCompletes(
        _selectedStartDate!,
        _selectedEndDate!,
      );

      if (!datesDisponibles) {
        _safeSetState(() => _isLoading = false);
        _showSafeSnackBar(
          '⚠️ Ces dates ne sont plus disponibles. Veuillez en sélectionner d\'autres.',
        );
        return;
      }

      if (_payerMaintenant && _selectedPaymentMethod == null) {
        _safeSetState(() => _isLoading = false);
        _showSafeSnackBar('Veuillez choisir une méthode de paiement');
        return;
      }

      final totalNuits = _selectedEndDate!.difference(_selectedStartDate!).inDays;
      final prixParPro = double.tryParse(widget.appartement['prix_proprietaire']?.toString() ?? '0') ?? 0.0;
      final fraisService = double.tryParse(widget.appartement['frais_service']?.toString() ?? '0') ?? 0.0;

      // calcul de la reduction
      final reductions = calculerPrixAvecReduction(
        prixProprietaire: prixParPro,
        fraisService: fraisService,
        nuits: totalNuits,
      );

      //Récupérer toutes les valeurs
      final prixTotal = reductions['total']!;
      final reductionTotale = reductions['totalReduction']!;
      final prixProTotalBrut = reductions['prixProTotal']!;
      final serviceTotalBrut = reductions['serviceTotal']!;
      final reductionProprio = reductions['reductionProprietaire']!;
      final reductionService = reductions['reductionService']!;

      // Valeurs APRÈS réduction
      final prixProApres = prixProTotalBrut - reductionProprio;
      final fraisServiceApres = serviceTotalBrut - reductionService;

      final dateDebutFormattee = DateFormat('yyyy-MM-dd').format(_selectedStartDate!);
      final dateFinFormattee = DateFormat('yyyy-MM-dd').format(_selectedEndDate!);

      final methodePaiement = _payerMaintenant
          ? '${_selectedPaymentMethod}_${_selectedPaymentPhone ?? _selectedPaymentCard}'
          : 'sur_place';

      await widget.databaseService.createReservation(
        appartementId: widget.appartement['id'].toString(),
        dateDebut: dateDebutFormattee,
        dateFin: dateFinFormattee,
        prixTotal: prixTotal,
        prixProprietaire: prixProApres,
        fraisService: fraisServiceApres,
        reduction: reductionTotale,
        prixProprietaireBrut: prixProTotalBrut,
        fraisServiceBrut: serviceTotalBrut,
        methodePaiement: methodePaiement,
        message: _messageController.text.isNotEmpty ? _messageController.text : null,
        adultes: _nombreAdultes,
        enfants: _nombreEnfants,
        momentPaiement: _payerMaintenant ? 'maintenant' : 'arrivee',
      );

      if (!mounted) return;

      _safeSetState(() => _isLoading = false);
      _showSuccessMessage();

      await Future.delayed(const Duration(seconds: 10));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage(error.toString());
      }
      _safeSetState(() => _isLoading = false);
    }
  }

  void _showSafeSnackBar(String message, {Color backgroundColor = Colors.orange}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 24.h, left: 20.w, right: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  void _showSuccessMessage() {
    if (!mounted) return;

    final tabProvider = context.read<TabProvider>();

    late Timer timer;

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

          tabProvider.goToHome();

          if (Navigator.canPop(modalContext)) {
            Navigator.pop(modalContext);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  modalContext,
                  MaterialPageRoute(
                    builder: (_) => const MainPage(),
                  ),
                      (route) => false,
                );
              }
            });
          }
        }

        timer = Timer(
          const Duration(seconds: 3),
          closeAndGoHome,
        );

        return Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25.r),
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
                "Demande envoyée ! 🎉",
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF7B32),
                ),
              ),

              SizedBox(height: 12.h),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: const Color(0xFF718096),
                    fontSize: 15.sp,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "Votre réservation pour "),
                    TextSpan(
                      text: "${widget.appartement['titre'] ?? 'Appartement'} ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: "${widget.appartement['ville'] ?? ''} ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: "a été confirmée."),
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                "${formatPrice(_totalPrice)} - "
                    "${_selectedEndDate!.difference(_selectedStartDate!).inDays} nuit"
                    "${_selectedEndDate!.difference(_selectedStartDate!).inDays > 1 ? 's' : ''}",
                style: TextStyle(
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
                  child: const Text(
                    "Retour à l'accueil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
      timer.cancel();
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 24.h, left: 20.w, right: 20.w),
        elevation: 4,
        backgroundColor: const Color(0xFFE53E3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 24.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 3,
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