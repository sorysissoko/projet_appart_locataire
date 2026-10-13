import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/reservation/reservation_detail/reservation_detail_screen.dart';
import 'package:service/rating/rating_widget.dart';
import 'package:service/database_service.dart';
import 'package:service/snackbar_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/confirmation_modal.dart';

String formatPrice(num price) {
  final formatter = NumberFormat("#,###", "fr_FR");
  return "${formatter.format(price)} FCFA";
}

num safeParsePrice(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

enum ReservationStatus {
  enAttente,
  confirmee,
  active,
  terminee,
  annulee,
  refuse,
}

class ListeReservationsPage extends StatefulWidget {
  final DatabaseService? databaseService;
  final VoidCallback? onBack;
  const ListeReservationsPage({
    super.key,
    this.databaseService,
    this.onBack,
  });

  @override
  State<ListeReservationsPage> createState() => _ListeReservationsPageState();
}

class _ListeReservationsPageState extends State<ListeReservationsPage> {
  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _filteredReservations = [];
  bool _isLoading = true;
  String _activeTab = "toutes";

  final Map<String, List<String>> _imagesCache = {};
  late DatabaseService _databaseService;

  final List<Map<String, dynamic>> tabs = [
    {"key": "toutes", "label": "Toutes", "count": 0},
    {"key": "en_attente", "label": "En attente", "count": 0},
    {"key": "confirmée", "label": "Confirmées", "count": 0},
    {"key": "terminée", "label": "Terminées", "count": 0},
    {"key": "annulée", "label": "Annulées", "count": 0},
  ];

  @override
  void initState() {
    super.initState();
    _databaseService = widget.databaseService ?? DatabaseService();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final reservations = await _databaseService.getReservationsForClient();

      final List<String> uniqueAppartementIds = reservations
          .map((r) => r['appartement']['id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();

      for (final String id in uniqueAppartementIds) {
        if (!_imagesCache.containsKey(id)) {
          final images = await _fetchPhotosUrls(id);
          _imagesCache[id] = images;
        }
      }

      final avgRatings = await _loadRatingsForAppartements(uniqueAppartementIds);

      for (var reservation in reservations) {
        final appId = reservation['appartement']['id'].toString();
        reservation['appartement']['avg_rating'] = avgRatings[appId] ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _reservations = reservations;
          _updateTabCounts();
          _applyFilter(_activeTab);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement réservations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchPhotosUrls(String appartementId) async {
    try {
      final data = await Supabase.instance.client
          .from('photo_appartements')
          .select('fichiername')
          .eq('appartement_id', appartementId)
          .order('est_principale', ascending: false)
          .order('ordre_affichage');

      final List<String> images = [];
      for (final item in data) {
        final String? fileName = item['fichiername'] as String?;
        if (fileName != null && fileName.isNotEmpty) {
          images.add('https://rcaujtlhfyumkuwdfpcm.supabase.co/storage/v1/object/public/appartements/$appartementId/$fileName');
        }
      }
      return images;
    } catch (e) {
      debugPrint('Erreur fetchPhotosUrls: $e');
      return [];
    }
  }

  void _updateTabCounts() {
    tabs[0]["count"] = _reservations.length;
    tabs[1]["count"] = _reservations.where((r) => _getReservationStatus(r) == ReservationStatus.enAttente).length;
    tabs[2]["count"] = _reservations.where((r) =>
    _getReservationStatus(r) == ReservationStatus.confirmee ||
        _getReservationStatus(r) == ReservationStatus.active).length;
    tabs[3]["count"] = _reservations.where((r) => _getReservationStatus(r) == ReservationStatus.terminee).length;
    tabs[4]["count"] = _reservations.where((r) => _getReservationStatus(r) == ReservationStatus.annulee).length;
  }

  ReservationStatus _getReservationStatus(Map<String, dynamic> reservation) {
    final now = DateTime.now();
    final dateFin = reservation['date_fin'] != null
        ? DateTime.parse(reservation['date_fin'].toString())
        : null;
    final statut = reservation['statut']?.toString().toLowerCase() ?? 'en_attente';

    if (statut == 'annulee' || statut == 'refuse') {
      return ReservationStatus.annulee;
    }

    if (dateFin != null && dateFin.isBefore(now)) {
      return ReservationStatus.terminee;
    }

    switch (statut) {
      case 'confirmee': return ReservationStatus.confirmee;
      case 'active': return ReservationStatus.active;
      case 'en_attente': return ReservationStatus.enAttente;
      default: return ReservationStatus.enAttente;
    }
  }

  ReservationStatus? _getStatusFromKey(String key) {
    if (key == "en_attente") return ReservationStatus.enAttente;
    if (key == "confirmée") return ReservationStatus.confirmee;
    if (key == "terminée") return ReservationStatus.terminee;
    if (key == "annulée") return ReservationStatus.annulee;
    return null;
  }

  Future<Map<String, double>> _loadRatingsForAppartements(List<String> ids) async {
    try {
      final ratings = await Supabase.instance.client
          .from('ratings')
          .select('appartement_id, rating')
          .inFilter('appartement_id', ids);

      final Map<String, List<int>> ratingsList = {};

      for (final r in ratings) {
        final id = r['appartement_id'].toString();
        final ratingValue = r['rating'] as int;
        ratingsList.putIfAbsent(id, () => []);
        ratingsList[id]!.add(ratingValue);
      }

      final Map<String, double> avgRatings = {};
      for (final id in ids) {
        final list = ratingsList[id] ?? [];
        final avg = list.isNotEmpty ? list.reduce((a, b) => a + b) / list.length : 0.0;
        avgRatings[id] = avg;
      }

      return avgRatings;
    } catch (e) {
      debugPrint('Erreur chargement ratings: $e');
      return {};
    }
  }

  void _applyFilter(String key) {
    setState(() {
      _activeTab = key;

      if (key == "toutes") {
        _filteredReservations = List.from(_reservations);
      } else if (key == "confirmée") {
        _filteredReservations = _reservations.where((r) =>
        _getReservationStatus(r) == ReservationStatus.confirmee ||
            _getReservationStatus(r) == ReservationStatus.active).toList();
      } else {
        final status = _getStatusFromKey(key);
        _filteredReservations = _reservations.where((r) => _getReservationStatus(r) == status).toList();
      }
    });
  }

  // ==================== GESTION DES RÉSERVATIONS ====================

  Future<void> _cancelReservation(Map<String, dynamic> reservation) async {
    final status = _getReservationStatus(reservation);

    if (status == ReservationStatus.annulee) {
      _showDeleteReservationModal(reservation);
      return;
    }

    if (status == ReservationStatus.terminee) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Cette réservation est déjà terminée'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showConfirmationModal(
      context: context,
      title: 'Annuler la réservation',
      message: 'Êtes-vous sûr de vouloir annuler cette réservation ? Cette action est irréversible.',
      confirmText: 'Oui, annuler',
      type: ConfirmationType.delete,
      onConfirm: () => _handleCancelReservation(reservation),
    );
  }

  Future<void> _handleCancelReservation(
      Map<String, dynamic> reservation,
      ) async {
    setState(() => _isLoading = true);

    try {
      final reservationId =
      reservation['id'].toString();

      // =====================================================
      // ANNULATION SÉCURISÉE VIA RPC
      // =====================================================

      await _databaseService.cancelReservation(
        reservationId,
      );

      // =====================================================
      // RECHARGER LES RÉSERVATIONS
      // =====================================================

      await _loadReservations();

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Réservation annulée avec succès !',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Erreur annulation réservation : $e',
      );

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur : ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  void _showDeleteReservationModal(Map<String, dynamic> reservation) {
    showConfirmationModal(
      context: context,
      title: 'Supprimer la réservation',
      message: 'Cette réservation est déjà annulée. Voulez-vous la supprimer définitivement de votre historique ?',
      confirmText: 'Supprimer',
      type: ConfirmationType.delete,
      customIcon: Icons.delete_forever,
      customIconColor: Colors.red,
      confirmColor: Colors.red.shade700,
      onConfirm: () => _handleDeleteReservation(reservation),
    );
  }

  Future<void> _handleDeleteReservation(
      Map<String, dynamic> reservation,
      ) async {
    setState(() => _isLoading = true);

    try {
      final reservationId =
      reservation['id'].toString();

      // =====================================================
      // SUPPRESSION SÉCURISÉE VIA RPC
      // =====================================================

      await _databaseService.supprimerReservation(
        reservationId,
      );

      // =====================================================
      // RECHARGER LES RÉSERVATIONS
      // =====================================================

      await _loadReservations();

      if (mounted) {
        setState(() => _isLoading = false);

        SnackBarService().showError(
          'Réservation supprimée définitivement !',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Erreur suppression réservation : $e',
      );

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur : ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  Future<void> _showRatingBottomSheet(Map<String, dynamic> reservation) async {
    final appartementId = reservation['appartement']['id'].toString();
    final appartementTitre = reservation['appartement']['titre'] ?? 'Appartement';

    int? existingRating;
    try {
      existingRating = await _databaseService.getUserRating(appartementId);
    } catch (e) {
      debugPrint('Erreur récupération note: $e');
    }

    int selectedStars = existingRating ?? 5;
    final commentController = TextEditingController();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (modalContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderContext).viewInsets.bottom + 24.h,
                left: 24.w,
                right: 24.w,
                top: 24.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    existingRating != null ? "Modifier votre note" : "Noter votre séjour",
                    style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "Partagez votre expérience à l'appartement : $appartementTitre",
                    style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20.h),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: isSubmitting ? null : () {
                            setModalState(() {
                              selectedStars = index + 1;
                            });
                          },
                          icon: Icon(
                            index < selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 40.sp,
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Votre commentaire (optionnel)...",
                      hintStyle: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(color: Color(0xFFFF6B00)),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        elevation: 0,
                      ),
                      onPressed: isSubmitting ? null : () async {
                        setModalState(() => isSubmitting = true);

                        final rootMessenger = ScaffoldMessenger.of(context);

                        try {
                          await _databaseService.rateAppartement(
                            appartementId: appartementId,
                            rating: selectedStars,
                            comment: commentController.text.isNotEmpty ? commentController.text : null,
                          );

                          if (modalContext.mounted) {
                            Navigator.pop(modalContext);
                          }

                          if (context.mounted) {
                            rootMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Merci pour votre avis !'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            await _loadReservations();
                          }
                        } catch (e) {
                          setModalState(() => isSubmitting = false);

                          if (modalContext.mounted) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: isSubmitting
                          ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          color: Color(0xFFE85D26),
                          strokeWidth: 2
                        ),
                      )
                          : Text(
                        existingRating != null ? "Modifier l'avis" : "Soumettre l'avis",
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalSpent = _reservations.fold<int>(0, (sum, r) => sum + safeParsePrice(r['prix_total']).toInt());
    final int pendingCount = _reservations.where((r) => _getReservationStatus(r) == ReservationStatus.enAttente).length;

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFEFE0),
          appBar: AppBar(
            backgroundColor: const Color(0xFFE85D26),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            leading: Padding(
              padding: EdgeInsets.only(left: 16.w),
              child: InkWell(
                onTap: widget.onBack ??
                        () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5CE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF8A4E1E),
                  ),
                ),
              ),
            ),
            title: Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: Text(
                "Mes Séjours",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE85D26))))
              : RefreshIndicator(
            color: const Color(0xFFE85D26),
            onRefresh: _loadReservations,
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFE85D26),
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          "Retrouvez vos réservations passées et à venir.",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFABE94),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          children: [
                            _buildSummaryItem(_reservations.length.toString(), "Total", const Color(0xFFFF6B00)),
                            SizedBox(width: 10.w),
                            _buildSummaryItem(pendingCount.toString(), "En attente", const Color(0xFFF59E0B)),
                            SizedBox(width: 10.w),
                            _buildSummaryItem("${(totalSpent / 1000000).toStringAsFixed(1)}M", "FCFA payés", const Color(0xFF10B981)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tabs.map((t) {
                        final bool isActive = _activeTab == t["key"];
                        return GestureDetector(
                          onTap: () => _applyFilter(t["key"]),
                          child: Container(
                            margin: EdgeInsets.only(right: 8.w),
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFE85D26) : const Color(0xFFE85D26).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30.r),
                              border: Border.all(color: isActive ? const Color(0xFFE85D26) : const Color(0xFFF6D0C1).withValues(alpha: 0.1)),
                              boxShadow: isActive
                                  ? [BoxShadow(color: const Color(0xFFFF6B00).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  t["label"],
                                  style: GoogleFonts.poppins(
                                    color: isActive ? Colors.white : const Color(0xFFE85D26),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: isActive ? const Color(0xFFF6AF92).withValues(alpha: 0.2) : const Color(0xFFF6AF92),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Text(
                                    t["count"].toString(),
                                    style: GoogleFonts.poppins(
                                      color: isActive ? Colors.white : const Color(0xFFE85D26),
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredReservations.isEmpty
                      ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 80.h),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 64.sp, color: Colors.grey[300]),
                            SizedBox(height: 16.h),
                            Text('Aucun séjour dans cette catégorie', style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  )
                      : ListView.builder(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                    itemCount: _filteredReservations.length,
                    itemBuilder: (context, index) {
                      final r = _filteredReservations[index];
                      final String? appId = r['appartement']['id']?.toString();
                      final List<String> images = (appId != null && _imagesCache.containsKey(appId))
                          ? _imagesCache[appId]!
                          : [];

                      return ReservationCard(
                        reservation: r,
                        images: images,
                        status: _getReservationStatus(r),
                        onCancel: () => _cancelReservation(r),
                        onRate: () => _showRatingBottomSheet(r),
                        databaseService: _databaseService,
                        fetchPhotosUrls: _fetchPhotosUrls,
                        onDelete: () => _handleDeleteReservation(r),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String value, String label, Color accentColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5EC),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFFFF5EC)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
                SizedBox(width: 6.w),
                Text(
                  value,
                  style: GoogleFonts.poppins(color: const Color(0xFF111827), fontSize: 15.sp, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.poppins(color: const Color(0xFF9CA3AF), fontSize: 11.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== RESERVATION CARD ====================

class ReservationCard extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final List<String> images;
  final ReservationStatus status;
  final VoidCallback onCancel;
  final VoidCallback onRate;
  final DatabaseService databaseService;
  final Future<List<String>> Function(String) fetchPhotosUrls;
  final VoidCallback? onDelete;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.images,
    required this.status,
    required this.onCancel,
    required this.onRate,
    required this.databaseService,
    required this.fetchPhotosUrls,
    this.onDelete,
  });

  @override
  State<ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<ReservationCard> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  double _dragOffset = 0;
  bool _isSwiped = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  int _calculateNights(String? start, String? end) {
    if (start == null || end == null) return 0;
    try {
      final startDate = DateTime.parse(start);
      final endDate = DateTime.parse(end);
      return endDate.difference(startDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  Map<String, dynamic> getStatusConfig(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.enAttente:
        return {
          'label': 'En attente',
          'bg': const Color(0xFFFFF7E6),
          'border': const Color(0xFFFFD966),
          'dot': const Color(0xFFFFA500),
          'text': const Color(0xFFB45309),
        };
      case ReservationStatus.confirmee:
        return {
          'label': 'Confirmée',
          'bg': const Color(0xFFE6F7FF),
          'border': const Color(0xFF66C4FF),
          'dot': const Color(0xFF2E8B57),
          'text': const Color(0xFF0A5E2E),
        };
      case ReservationStatus.active:
        return {
          'label': 'En cours',
          'bg': const Color(0xFFECFDF5),
          'border': const Color(0xFFA7F3D0),
          'dot': const Color(0xFF10B981),
          'text': const Color(0xFF065F46),
        };
      case ReservationStatus.terminee:
        return {
          'label': 'Terminée',
          'bg': const Color(0xFFF3F4F6),
          'border': const Color(0xFFD1D5DB),
          'dot': const Color(0xFF6B7280),
          'text': const Color(0xFF374151),
        };
      case ReservationStatus.annulee:
      case ReservationStatus.refuse:
        return {
          'label': 'Annulée',
          'bg': const Color(0xFFFEF2F2),
          'border': const Color(0xFFFCA5A5),
          'dot': const Color(0xFFDC2626),
          'text': const Color(0xFF991B1B),
        };
    }
  }

  Future<void> _navigateToDetails() async {
    // Fermer le swipe avant de naviguer
    if (_isSwiped) {
      setState(() {
        _dragOffset = 0;
        _isSwiped = false;
      });
      return;
    }

    final appartement = widget.reservation['appartement'] as Map<String, dynamic>;

    List<String> photos = widget.images;
    if (photos.isEmpty) {
      try {
        photos = await widget.fetchPhotosUrls(appartement['id'].toString());
      } catch (e) {
        debugPrint('Erreur chargement photos: $e');
      }
    }

    List<Map<String, dynamic>> reservations = [];
    try {
      reservations = await widget.databaseService.getReservationsByAppartement(
        appartement['id'].toString(),
      );
    } catch (e) {
      debugPrint('Erreur chargement réservations: $e');
    }

    final cachedData = {
      'photos': photos,
      'reservations': reservations,
    };

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationDetailScreen(
          appartement: appartement,
          appartementService: widget.databaseService,
          cachedData: cachedData,
          reservation: widget.reservation,
        ),
        settings: const RouteSettings(name: '/detail_reservation'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appartement = widget.reservation['appartement'] as Map<String, dynamic>? ?? {};
    final cfg = getStatusConfig(widget.status);
    final nights = _calculateNights(
      widget.reservation['date_debut']?.toString(),
      widget.reservation['date_fin']?.toString(),
    );

    final totalPrice = safeParsePrice(widget.reservation['prix_total']).toInt();
    final pricePerNight = nights > 0 ? (totalPrice / nights).round() : 0;
    final rating = (appartement['avg_rating'] ?? appartement['note_moyenne'] ?? 0.0).toDouble();

    final bool isCancelled = widget.status == ReservationStatus.annulee;

    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            // Bouton de suppression (visible en arrière-plan)
            if (isCancelled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 80.w,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(24.r),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _dragOffset = 0;
                                _isSwiped = false;
                              });
                              if (widget.onDelete != null) {
                                widget.onDelete!();
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_forever,
                                  color: Colors.white,
                                  size: 28.sp,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Supprimer',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
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

            // Carte principale avec effet de swipe
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5EC),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Color(0xFFFFDDCF), width: 1.sp),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFE85D26).withValues(alpha: 0.04),
                    blurRadius: 1,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (!isCancelled) return;
                  setState(() {
                    _dragOffset += details.delta.dx;
                    if (_dragOffset < -80.w) {
                      _dragOffset = -80.w;
                    }
                    if (_dragOffset > 0) {
                      _dragOffset = 0;
                    }
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (!isCancelled) return;
                  setState(() {
                    if (_dragOffset < -40.w) {
                      _dragOffset = -80.w;
                      _isSwiped = true;
                    } else {
                      _dragOffset = 0;
                      _isSwiped = false;
                    }
                  });
                },
                onTap: () {
                  if (_isSwiped) {
                    setState(() {
                      _dragOffset = 0;
                      _isSwiped = false;
                    });
                    return;
                  }
                  _navigateToDetails();
                },
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Stack
                      Stack(
                        children: [
                          SizedBox(
                            height: 180.h,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              child: widget.images.isNotEmpty
                                  ? PageView.builder(
                                controller: _pageController,
                                itemCount: widget.images.length,
                                onPageChanged: (index) {
                                  setState(() => _currentImageIndex = index);
                                },
                                itemBuilder: (ctx, imgIndex) => Image.network(
                                  widget.images[imgIndex],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  ),
                                ),
                              )
                                  : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.home_work_rounded, size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFFF5EC).withValues(alpha: 0.7), Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  stops: const [0.0, 0.3],
                                ),
                              ),
                            ),
                          ),
                          if (widget.images.length > 1)
                            Positioned(
                              bottom: 12.h,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(widget.images.length, (dotIndex) {
                                  final bool isCurrent = _currentImageIndex == dotIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                                    width: isCurrent ? 14.w : 6.w,
                                    height: 6.h,
                                    decoration: BoxDecoration(
                                      color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(3.r),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          Positioned(
                            top: 12.h,
                            left: 12.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: cfg['bg'],
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: cfg['border'], width: 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6.w,
                                    height: 6.h,
                                    decoration: BoxDecoration(color: cfg['dot'], shape: BoxShape.circle),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    cfg['label'],
                                    style: GoogleFonts.poppins(color: cfg['text'], fontSize: 11.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12.h,
                            right: 12.w,
                            child: RatingChip(
                              rating: rating,
                              count: rating > 0 ? 1 : 0,
                            ),
                          ),
                          Positioned(
                            bottom: 12.h,
                            left: 16.w,
                            right: 16.w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appartement['titre'] ?? 'Appartement',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white.withValues(alpha: 0.8),
                                      size: 12.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: Text(
                                        "${appartement['quartier'] ?? appartement['ville'] ?? 'Bamako'}",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 12.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Footer
                      Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF4ED),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today_rounded,
                                        color: Color(0xFFFF6B00),
                                        size: 13,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      _formatDate(widget.reservation['date_debut']?.toString()),
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFF4B5563),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(width: 16.w, height: 1, color: const Color(0xFFE5E7EB)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                                      child: Text(
                                        "$nights nuits",
                                        style: GoogleFonts.poppins(
                                          color: Color(0xFF6B7280),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(width: 16.w, height: 1, color: const Color(0xFFE5E7EB)),
                                  ],
                                ),
                                Text(
                                  _formatDate(widget.reservation['date_fin']?.toString()),
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF4B5563),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          formatPrice(totalPrice).split(' ')[0],
                                          style: GoogleFonts.poppins(
                                            color: Color(0xFF111827),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          "FCFA",
                                          style: GoogleFonts.poppins(
                                            color: Color(0xFFFF6B00),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "${formatPrice(pricePerNight)} / nuit",
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (widget.status == ReservationStatus.enAttente)
                                      OutlinedButton(
                                        onPressed: widget.onCancel,
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFEF4444)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                        ),
                                        child: Text(
                                          "Annuler",
                                          style: GoogleFonts.poppins(
                                            color: Color(0xFFEF4444),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (widget.status == ReservationStatus.terminee)
                                      ElevatedButton.icon(
                                        onPressed: widget.onRate,
                                        icon: const Icon(Icons.star_rate_rounded, size: 14, color: Color(0xFFF59E0B)),
                                        label: Text(
                                          "Noter",
                                          style: GoogleFonts.poppins(
                                            color: Color(0xFFF59E0B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFFF7E6),
                                          side: const BorderSide(color: Color(0xFFFFD966)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                          elevation: 0,
                                        ),
                                      ),
                                    SizedBox(width: 8.w),
                                    ElevatedButton(
                                      onPressed: _navigateToDetails,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6B00),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        "Détails",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
    );
  }
}