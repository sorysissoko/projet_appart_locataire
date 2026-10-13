import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:service/database_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:service/auth_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
class SharedReservationPage extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final DatabaseService databaseService;
  final Future<List<String>> Function(String id) fetchPhotosUrls;

  const SharedReservationPage({
    super.key,
    required this.reservation,
    required this.databaseService,
    required this.fetchPhotosUrls,
  });

  @override
  State<SharedReservationPage> createState() => _SharedReservationPageState();
}

class _SharedReservationPageState extends State<SharedReservationPage> {
  List<String> images = [];
  late PageController _pageController;
  int _currentIndex = 0;
  String? _imageError;
  late final AuthService _authService;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _authService = AuthService();

    _loadImages();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _authService.getProfile();
    if (!mounted) return;

    setState(() {
      _profile = data;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    final appartementId = widget.reservation['appartement_id']?.toString();
    if (appartementId != null) {
      try {
        final urls = await widget.fetchPhotosUrls(appartementId);
        if (mounted) {
          setState(() {
            images = urls;
            _imageError = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _imageError = 'Impossible de charger les images';
          });
        }
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Non spécifiée';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  int _calculateNights(String? start, String? end) {
    if (start == null || end == null) return 0;

    try {
      final startDate = DateTime.parse(start);
      final endDate = DateTime.parse(end);
      return endDate
          .difference(startDate)
          .inDays;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _shareAppartement() async {
    final appartement =
        widget.reservation['appartement'] as Map<String, dynamic>? ?? {};

    final titre = appartement['titre'] ?? 'Appartement';
    final adresse = appartement['adresse'] ?? '';
    final ville = appartement['ville'] ?? '';
    final prix = appartement['prix'] ?? '';
    final codeReservation = widget.reservation['id'] ?? '';
    final imageUrl = images.isNotEmpty ? images.first : null;

    final lienApp = "https://tonapp.com";
    final lienAppartement =
        "https://tonapp.com/appartement/${appartement['id']}";

    final message = '''
🏠 $titre

📍 $adresse ${ville.isNotEmpty ? ', $ville' : ''}

💰 $prix FCFA / nuit

🧾 Code réservation : $codeReservation

📲 Télécharger l'application :
$lienApp

🔗 Voir l'appartement :
$lienAppartement
''';

    if (imageUrl != null) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/appartement.jpg');
        await file.writeAsBytes(response.bodyBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: message,
          ),
        );
      } catch (e) {
        await SharePlus.instance.share(
          ShareParams(
            text: message,
          ),
        );
      }
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: message,
        ),
      );
    }
  }


  Future<void> _printReservation() async {
    final appartement =
        widget.reservation['appartement'] as Map<String, dynamic>? ?? {};

    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final logo = await imageFromAssetBundle('assets/images/mali2.png');

    /// DATE DE RÉSERVATION
    DateTime reservationDate = DateTime.parse(
      widget.reservation['created_at'] ??
          widget.reservation['date_debut'],
    );

    String formattedDate =
        "${reservationDate.day.toString().padLeft(2, '0')}/"
        "${reservationDate.month.toString().padLeft(2, '0')}/"
        "${reservationDate.year}";

    /// QR DATA
    final qrData =
        "Reservation:${widget.reservation['id']} - ${appartement['titre']}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [

          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logo, height: 60),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "FACTURE",
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 22,
                      ),
                    ),
                    pw.Text(
                      "ADS Immobilier",
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      "Date : $formattedDate",
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 15),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Client", style: pw.TextStyle(font: boldFont)),
                pw.Text(
                  "${_profile?['prenom'] ?? ''} ${_profile?['nom'] ?? ''}",
                  style: pw.TextStyle(font: font),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 15),

          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(5),
            },
            children: [

              _rowStyled("Appartement", appartement['titre'] ?? "", font),
              _rowStyled("Arrivée", _formatDate(widget.reservation['date_debut']?.toString()), font),
              _rowStyled("Départ", _formatDate(widget.reservation['date_fin']?.toString()), font),
              _rowStyled(
                "Voyageurs",
                '${widget.reservation['adulte']} adulte(s), ${widget.reservation['enfant']} enfant(s)',
                font,
              ),
              _rowStyled(
                "Nuits",
                "${_calculateNights(
                  widget.reservation['date_debut']?.toString(),
                  widget.reservation['date_fin']?.toString(),
                )}",
                font,
              ),
              _rowStyled("Prix / nuit", "${formatPrice(appartement['prix'])} FCFA", font),
              _rowStyled("Frais ADS", "${formatPrice(widget.reservation['frais_service'])} FCFA", font),

              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text(
                      "TOTAL",
                      style: pw.TextStyle(font: boldFont, fontSize: 16),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text(
                      "${formatPrice(widget.reservation['prix_total'] ?? widget.reservation['total'])} FCFA",
                      style: pw.TextStyle(font: boldFont, fontSize: 16),
                    ),
                  ),
                ],
              ),

              _rowStyled("Paiement", widget.reservation['methode_paiement'] ?? '', font),
              _rowStyled("Statut", widget.reservation['statut'] ?? '', font),
            ],
          ),

          pw.SizedBox(height: 20),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [

              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qrData,
                width: 80,
                height: 80,
              ),

              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "ADS Immobilier",
                    style: pw.TextStyle(font: boldFont),
                  ),
                  pw.Text(
                    "Service professionnel",
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          pw.Center(
            child: pw.Text(
              "Merci pour votre confiance",
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.TableRow _rowStyled(String title, String value, pw.Font font) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(title, style: pw.TextStyle(font: font)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: pw.TextStyle(font: font)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appartement = widget.reservation['appartement'] as Map<String,
        dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la réservation'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'appartement
            if (images.isNotEmpty)
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 240.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          _FullScreenGallery(
                                            images: images,
                                            initialIndex: index,
                                          ),
                                    ),
                                  );
                                },
                                child: Image.network(
                                  images[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                            Icons.broken_image, size: 50),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // compteur 1 / X
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${images.length}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Indicateurs points
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                          (index) =>
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            width: _currentIndex == index ? 10.w : 6.w,
                            height: _currentIndex == index ? 10.w : 6.w,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? Colors.black
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                    ),
                  ),
                ],
              )
            else
              if (_imageError != null)
                Container(
                  height: 240.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                          Icons.error_outline, size: 50, color: Colors.red),
                      SizedBox(height: 8.h),
                      Text(
                        _imageError!,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  height: 240.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50),
                  ),
                ),

            SizedBox(height: 20.h),

            // Titre
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    appartement['titre'] ?? 'Appartement',
                    style: GoogleFonts.poppins(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 26),
                  onPressed: _showActionSheet,
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Adresse
            if (appartement['adresse'] != null || appartement['ville'] != null)
              Row(
                children: [
                  Image.asset(
                    'assets/images/cartem.png',
                    width: 30.w,
                    height: 30.h,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${appartement['adresse'] ?? ''}${appartement['ville'] !=
                          null ? ', ${appartement['ville']}' : ''}',
                      style: GoogleFonts.poppins(fontSize: 16.sp),
                    ),
                  ),
                ],
              ),

            SizedBox(height: 20.h),

            // informations de réservation
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Image.asset(
                        'assets/images/date-limite.png',
                        width: 30.w,
                        height: 30.h,
                      ),
                      label: "Date d'arrivée",
                      value: _formatDate(
                          widget.reservation['date_debut']?.toString()),
                    ),
                    _buildInfoRow(
                      icon: Image.asset(
                        'assets/images/date-limite.png',
                        width: 30.w,
                        height: 30.h,
                      ),
                      label: "Date de départ",
                      value: _formatDate(
                          widget.reservation['date_fin']?.toString()),
                    ),
                    _buildInfoRow(
                      icon: Image.asset(
                        'assets/images/nuitclaire.png',
                        width: 30.w,
                        height: 30.h,
                      ),
                      label: 'Nombre de nuits',
                      value: '${_calculateNights(
                        widget.reservation['date_debut']?.toString(),
                        widget.reservation['date_fin']?.toString(),
                      )} nuits',
                    ),
                    _buildInfoRow(
                      icon: Image.asset(
                        'assets/images/Money.png',
                        width: 30.w,
                        height: 30.h,
                      ),
                      label: 'Prix total',
                      value: "${formatPrice(
                          safeParsePrice(
                              widget.reservation['prix_total'] ?? widget.reservation['total']
                          )
                      )} ",

                    ),

                    _buildInfoRow(
                      icon: Image.asset(
                        'assets/images/Money.png',
                        width: 30.w,
                        height: 30.h,
                      ),
                      label: 'Prix par nuit',
                      value: '${formatPrice(appartement['prix'])} ',
                    ),

                    _buildInfoRow(
                      icon: Image.asset(
                        'assets/images/Money.png',
                        width: 30.w,
                        height: 30.h,
                      ),
                      label: 'Frais de service',
                      value: '${formatPrice(widget.reservation['frais_service'])} ',
                    ),

                    _buildInfoRow(
                      icon: Image.asset(
                        'assets/images/when.png',
                        width: 30.w,
                        height: 30.h,
                      ),
                      label: 'Quand vous allez payer',
                      value: '${widget.reservation['moment_paiement'] ??
                          widget.reservation['methode_paiement'] ?? '0'}',

                    ),

                    _buildInfoRow(
                      icon: Image.asset(
                        'assets/images/mode_paie.png',
                        width: 30.w,
                        height: 30.h,
                      ),
                      label: 'Méthode de paiement',
                      value: '${widget.reservation['methode_paiement'] ?? ''}',

                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/adulte_enf.png',
                            width: 30.w,
                            height: 30.h,
                          ),
                          SizedBox(width: 12.w),

                          Expanded(
                            flex: 2,
                            child: Text(
                              'Adulte | Enfant',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 3,
                            child: Text(
                              '${widget.reservation['adulte'] ?? 0} | ${widget.reservation['enfant'] ?? 0}',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Prix de l'appartement
            if (appartement['prix'] != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Autres informations",
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      _buildInfoRow(
                        icon: Image.asset(
                          'assets/images/utilisateur.png',
                          width: 30.w,
                          height: 30.h,
                        ),
                        label: 'Utilisateur',
                        value: _profile != null
                            ? "${_profile!['prenom']} ${_profile!['nom']}"
                            : "Nom Prénom",
                      ),

                      _buildInfoRow(
                        icon: Image.asset(
                          'assets/images/calendrier.png',
                          width: 30.w,
                          height: 30.h,
                        ),
                        label: 'Réservé le',
                        value: _formatDate(
                            widget.reservation['created_at']?.toString()),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required Widget icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          icon,
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }


  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // PARTAGER
                ListTile(
                  leading: const Icon(Icons.share, size: 26),
                  title: Text(
                    "Partager la réservation",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _shareAppartement();
                  },
                ),

                // IMPRIMER
                ListTile(
                  leading: const Icon(Icons.print, size: 26),
                  title: Text(
                    "Imprimer la réservation",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _printReservation();
                  },
                ),

                const SizedBox(height: 10),

                // ANNULER
                ListTile(
                  leading: const Icon(Icons.close, size: 26),
                  title: const Text("Annuler"),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

}