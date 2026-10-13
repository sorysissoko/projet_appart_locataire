import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String desc;
  final Color bg;
  final String icon;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.desc,
    required this.bg,
    required this.icon,
  });
}

class PaymentBottomSheet extends StatefulWidget {
  final double amount;

  final Function(
    String method,
    String? phone,
    String? indicatifPaiement,
    String? providerPaymentMethodId,
    String? provider,
    String? cardBrand,
    String? cardLast4,
  ) onSuccess;

  final Map<String, dynamic> appartement;

  final int totalNights;
  final double totalPrice;

  final DateTime? startDate;
  final DateTime? endDate;

  /// Numéro enregistré dans le compte du locataire.
  ///
  /// Exemple :
  /// 70000000
  final String? initialPhone;

  /// Indicatif enregistré dans le compte du locataire.
  ///
  /// Exemple :
  /// +223
  final String? initialIndicatif;

  const PaymentBottomSheet({
    super.key,
    required this.amount,
    required this.onSuccess,
    required this.appartement,
    required this.totalNights,
    required this.totalPrice,
    this.startDate,
    this.endDate,
    this.initialPhone,
    this.initialIndicatif,
  });

  @override
  State<PaymentBottomSheet> createState() =>
      _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  // ============================================================
  // ÉTAT
  // ============================================================

  int step = 0;

  String? selectedMethod;

  // ============================================================
  // CONTRÔLEURS
  // ============================================================

  final TextEditingController phoneController =
  TextEditingController();

  // Conservés pour une future intégration carte/tokenisation.
  final TextEditingController cardController =
  TextEditingController();

  final TextEditingController expiryController =
  TextEditingController();

  final TextEditingController cvvController =
  TextEditingController();

  final PageController pageController =
  PageController();

  // ============================================================
  // COULEURS
  // ============================================================

  final Color _accentColor =
  const Color(0xFFE85D26);

  final Color lightOrange =
  const Color(0xFFFFF6F1);

  final Color textDark =
  const Color(0xFF2D3748);

  final Color textGrey =
  const Color(0xFF718096);

  final Color borderGrey =
  const Color(0xFFE2E8F0);

  final Color successGreen =
  const Color(0xFF00C853);

  // ============================================================
  // PAYS
  // ============================================================

  String selectedCountryCode = '+223';

  String selectedCountryName = 'Mali';

  final List<Map<String, String>> orangeMoneyCountries = [
    {
      'code': '+223',
      'name': 'Mali',
      'flag': '🇲🇱',
      'length': '8',
      'example': '70 00 00 00',
    },
    {
      'code': '+221',
      'name': 'Sénégal',
      'flag': '🇸🇳',
      'length': '9',
      'example': '77 000 00 00',
    },
    {
      'code': '+225',
      'name': 'Côte d\'Ivoire',
      'flag': '🇨🇮',
      'length': '8',
      'example': '01 02 03 04',
    },
    {
      'code': '+226',
      'name': 'Burkina Faso',
      'flag': '🇧🇫',
      'length': '8',
      'example': '70 00 00 00',
    },
    {
      'code': '+227',
      'name': 'Niger',
      'flag': '🇳🇪',
      'length': '8',
      'example': '90 00 00 00',
    },
    {
      'code': '+229',
      'name': 'Bénin',
      'flag': '🇧🇯',
      'length': '8',
      'example': '97 00 00 00',
    },
    {
      'code': '+228',
      'name': 'Togo',
      'flag': '🇹🇬',
      'length': '8',
      'example': '90 00 00 00',
    },
    {
      'code': '+224',
      'name': 'Guinée',
      'flag': '🇬🇳',
      'length': '9',
      'example': '60 00 00 00',
    },
    {
      'code': '+237',
      'name': 'Cameroun',
      'flag': '🇨🇲',
      'length': '9',
      'example': '69 00 00 00',
    },
    {
      'code': '+242',
      'name': 'Congo',
      'flag': '🇨🇬',
      'length': '9',
      'example': '06 000 000',
    },
    {
      'code': '+243',
      'name': 'RDC',
      'flag': '🇨🇩',
      'length': '9',
      'example': '81 00 00 00',
    },
    {
      'code': '+261',
      'name': 'Madagascar',
      'flag': '🇲🇬',
      'length': '9',
      'example': '32 00 00 00',
    },
    {
      'code': '+212',
      'name': 'Maroc',
      'flag': '🇲🇦',
      'length': '9',
      'example': '06 00 00 00',
    },
    {
      'code': '+222',
      'name': 'Mauritanie',
      'flag': '🇲🇷',
      'length': '8',
      'example': '30 00 00 00',
    },
    {
      'code': '+245',
      'name': 'Guinée-Bissau',
      'flag': '🇬🇼',
      'length': '7',
      'example': '95 00 00',
    },
    {
      'code': '+231',
      'name': 'Liberia',
      'flag': '🇱🇷',
      'length': '8',
      'example': '77 00 00 00',
    },
    {
      'code': '+232',
      'name': 'Sierra Leone',
      'flag': '🇸🇱',
      'length': '8',
      'example': '76 00 00 00',
    },
    {
      'code': '+267',
      'name': 'Botswana',
      'flag': '🇧🇼',
      'length': '8',
      'example': '71 00 00 00',
    },
    {
      'code': '+20',
      'name': 'Égypte',
      'flag': '🇪🇬',
      'length': '10',
      'example': '0100 000 0000',
    },
  ];

  String? _validatePaymentPhone() {
    final phone = phoneController.text
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .trim();

    if (phone.isEmpty) {
      return 'Le numéro utilisé pour le paiement est obligatoire.';
    }

    if (!validatePhone(phone)) {
      return 'Numéro invalide (${_getPhoneLength()} chiffres requis).';
    }

    return null;
  }

  // ============================================================
  // MÉTHODES DE PAIEMENT
  // ============================================================

  final List<PaymentMethod> methods = [
    PaymentMethod(
      id: 'orange_money',
      name: 'Orange Money',
      desc: 'Paiement mobile Orange',
      bg: Color(0xFFFFF3E8),
      icon: 'assets/images/orangemoney.png',
    ),
    PaymentMethod(
      id: 'moov_money',
      name: 'Moov Money',
      desc: 'Paiement mobile Moov Africa',
      bg: Color(0xFFE8F0FF),
      icon: 'assets/images/Moov_Africa_Malitel_(logo).png',
    ),
    PaymentMethod(
      id: 'wave',
      name: 'Wave',
      desc: 'Transfert d\'argent rapide',
      bg: Color(0xFFE8F6FF),
      icon: 'assets/images/wave-logo.png',
    ),
    PaymentMethod(
      id: 'carte_bancaire',
      name: 'Carte bancaire',
      desc: 'Visa / Mastercard',
      bg: Color(0xFFECEEFF),
      icon: 'assets/images/visa.png',
    ),
  ];

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializePaymentPhone();
  }

  /// Initialise le téléphone enregistré dans le compte.
  ///
  /// Le locataire pourra ensuite le modifier librement
  /// dans le champ de paiement.
  void _initializePaymentPhone() {
    final phone =
    widget.initialPhone?.trim();

    final indicatif =
    widget.initialIndicatif?.trim();

    // ----------------------------------------------------------
    // INDICATIF
    // ----------------------------------------------------------

    if (indicatif != null &&
        indicatif.isNotEmpty) {
      final country =
      orangeMoneyCountries.firstWhere(
            (c) => c['code'] == indicatif,
        orElse: () =>
        orangeMoneyCountries.first,
      );

      selectedCountryCode =
      country['code']!;

      selectedCountryName =
      country['name']!;
    }

    // ----------------------------------------------------------
    // NUMÉRO
    // ----------------------------------------------------------

    if (phone != null &&
        phone.isNotEmpty) {
      _formatPhone(phone);
    }
  }

  // ============================================================
  // FORMAT PRIX
  // ============================================================

  String formatPrice(num price) {
    final formatter =
    NumberFormat('#,###', 'fr_FR');

    return formatter.format(
      price.round(),
    );
  }

  // ============================================================
  // PRIX
  // ============================================================

  double get pricePerNight {
    final prixProprietaire =
        double.tryParse(
          widget.appartement[
          'prix_proprietaire']
              ?.toString() ??
              '0',
        ) ??
            0.0;

    final fraisService =
        double.tryParse(
          widget.appartement[
          'frais_service']
              ?.toString() ??
              '0',
        ) ??
            0.0;

    return prixProprietaire +
        fraisService;
  }

  int get actualTotalNights {
    if (widget.startDate != null &&
        widget.endDate != null) {
      final nights = widget.endDate!
          .difference(widget.startDate!)
          .inDays;

      return nights > 0 ? nights : 0;
    }

    return widget.totalNights > 0
        ? widget.totalNights
        : 0;
  }

  int get totalNights {
    return actualTotalNights;
  }

  /// Total déjà calculé par AppartementDetailPage.
  ///
  /// Nous ne recalculons pas les réductions ici.
  double get totalFinal {
    return widget.totalPrice;
  }

  /// Sous-total avant réduction.
  double get subtotal {
    return pricePerNight *
        totalNights;
  }

  /// Réduction affichée.
  double get totalReduction {
    final reduction =
        subtotal - totalFinal;

    return reduction > 0
        ? reduction
        : 0.0;
  }

  // ============================================================
  // VALIDATION TÉLÉPHONE
  // ============================================================

  bool validatePhone(
      String phone,
      ) {
    final cleaned = phone
        .replaceAll(' ', '')
        .replaceAll('-', '');

    final country =
    orangeMoneyCountries.firstWhere(
          (c) =>
      c['code'] ==
          selectedCountryCode,
      orElse: () => {
        'length': '8',
      },
    );

    final expectedLength =
        int.tryParse(
          country['length'] ?? '8',
        ) ??
            8;

    return RegExp(
      r'^[0-9]{' +
          expectedLength.toString() +
          r'}$',
    ).hasMatch(cleaned);
  }

  // ============================================================
  // FORMATAGE TÉLÉPHONE
  // ============================================================

  void _formatPhone(
      String value,
      ) {
    final digits = value.replaceAll(
      RegExp(r'\D'),
      '',
    );

    final country =
    orangeMoneyCountries.firstWhere(
          (c) =>
      c['code'] ==
          selectedCountryCode,
      orElse: () => {
        'length': '8',
      },
    );

    final length =
        int.tryParse(
          country['length'] ?? '8',
        ) ??
            8;

    final limitedDigits =
    digits.length > length
        ? digits.substring(
      0,
      length,
    )
        : digits;

    String formatted = '';

    if (length == 8) {
      for (
      int i = 0;
      i < limitedDigits.length;
      i++
      ) {
        if (i == 2 ||
            i == 4 ||
            i == 6) {
          formatted += ' ';
        }

        formatted +=
        limitedDigits[i];
      }
    } else if (length == 9) {
      for (
      int i = 0;
      i < limitedDigits.length;
      i++
      ) {
        if (i == 2 ||
            i == 5) {
          formatted += ' ';
        }

        formatted +=
        limitedDigits[i];
      }
    } else if (length == 10) {
      for (
      int i = 0;
      i < limitedDigits.length;
      i++
      ) {
        if (i == 3 ||
            i == 6) {
          formatted += ' ';
        }

        formatted +=
        limitedDigits[i];
      }
    } else {
      formatted = limitedDigits;
    }

    if (phoneController.text !=
        formatted) {
      phoneController.value =
          TextEditingValue(
            text: formatted,
            selection:
            TextSelection.collapsed(
              offset: formatted.length,
            ),
          );
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void nextStep() {
    if (step >= 1) {
      return;
    }

    setState(() {
      step++;
    });

    pageController.nextPage(
      duration:
      const Duration(
        milliseconds: 300,
      ),
      curve: Curves.easeInOut,
    );
  }

  void prevStep() {
    if (step <= 0) {
      return;
    }

    setState(() {
      step--;
    });

    pageController.previousPage(
      duration:
      const Duration(
        milliseconds: 300,
      ),
      curve: Curves.easeInOut,
    );
  }

  // ============================================================
  // DATES
  // ============================================================

  String getFormattedDates() {
    if (widget.startDate != null &&
        widget.endDate != null) {
      final start =
      widget.startDate!;

      final end =
      widget.endDate!;

      final nuits = end
          .difference(start)
          .inDays;

      if (nuits <= 0) {
        return 'Dates invalides';
      }

      return '$nuits nuit${nuits > 1 ? 's' : ''} • '
          'Du ${_formatDateMonth(start)} '
          'au ${_formatDateFull(end)}';
    }

    return 'Dates non sélectionnées';
  }

  String _formatDateMonth(
      DateTime date,
      ) {
    final d =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final m =
    date.month.toString().padLeft(
      2,
      '0',
    );

    return '$d/$m';
  }

  String _formatDateFull(
      DateTime date,
      ) {
    final d =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final m =
    date.month.toString().padLeft(
      2,
      '0',
    );

    final y =
    date.year.toString();

    return '$d/$m/$y';
  }

  // ============================================================
  // COUNTRY PICKER
  // ============================================================

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          height: 450,
          padding:
          const EdgeInsets.symmetric(
            vertical: 16,
          ),
          child: Column(
            children: [
              Padding(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Sélectionnez votre pays',
                  style:
                  GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child:
                ListView.builder(
                  itemCount:
                  orangeMoneyCountries
                      .length,
                  itemBuilder:
                      (context, index) {
                    final country =
                    orangeMoneyCountries[
                    index];

                    final isSelected =
                        selectedCountryCode ==
                            country[
                            'code'];

                    return ListTile(
                      leading: Text(
                        country['flag']!,
                        style:
                        GoogleFonts
                            .poppins(
                          fontSize: 28,
                        ),
                      ),
                      title: Text(
                        country['name']!,
                      ),
                      subtitle:
                      Text(
                        '${country['code']} • '
                            '${country['length']} chiffres',
                      ),
                      trailing:
                      isSelected
                          ? Icon(
                        Icons
                            .check_circle,
                        color:
                        _accentColor,
                      )
                          : null,
                      onTap: () {
                        setState(() {
                          selectedCountryCode =
                          country[
                          'code']!;

                          selectedCountryName =
                          country[
                          'name']!;

                          // Le changement de pays
                          // invalide l'ancien numéro.
                          phoneController
                              .clear();
                        });

                        Navigator.pop(
                          context,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getExamplePhone() {
    final country =
    orangeMoneyCountries.firstWhere(
          (c) =>
      c['code'] ==
          selectedCountryCode,
      orElse: () => {
        'example':
        '70 00 00 00',
      },
    );

    return country['example']!;
  }

  String _getPhoneLength() {
    final country =
    orangeMoneyCountries.firstWhere(
          (c) =>
      c['code'] ==
          selectedCountryCode,
      orElse: () => {
        'length': '8',
      },
    );

    return country['length']!;
  }

  // ============================================================
  // MESSAGE CARTE
  // ============================================================

  void _showCardNotAvailableMessage() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Le paiement par carte sera '
              'disponible prochainement. '
              'Aucun numéro de carte '
              'n’est enregistré.',
        ),
        duration:
        Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // VALIDATION ET ENVOI
  // ============================================================

  void _submitPayment() {
    if (selectedMethod == null) {
      return;
    }

    // ----------------------------------------------------------
    // DATES
    // ----------------------------------------------------------

    if (totalNights <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner une période '
                'de séjour valide.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // TOTAL
    // ----------------------------------------------------------

    if (totalFinal <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Le montant du séjour est invalide.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
// MOBILE MONEY
// ==========================================================

    if (selectedMethod != 'carte_bancaire') {
      final phoneNumber = phoneController.text
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .trim();

      // --------------------------------------------------------
      // CHAMP OBLIGATOIRE
      // --------------------------------------------------------

      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez saisir le numéro utilisé pour le paiement.',
            ),
          ),
        );

        return;
      }

      // --------------------------------------------------------
      // VALIDATION DU NUMÉRO
      // --------------------------------------------------------

      if (!validatePhone(phoneNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Numéro invalide (${_getPhoneLength()} chiffres requis).',
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        return;
      }

      // --------------------------------------------------------
      // RETOUR VERS LE PARENT
      // --------------------------------------------------------

      widget.onSuccess(
        selectedMethod!,
        phoneNumber,
        selectedCountryCode,
        null,
        null,
        null,
        null,
      );

      if (mounted) {
        Navigator.pop(context);
      }

      return;
    }
    // ----------------------------------------------------------
    // CARTE BANCAIRE
    // ----------------------------------------------------------

    _showCardNotAvailableMessage();
  }

  // ============================================================
  // RÉSUMÉ PRIX
  // ============================================================

  Widget _buildSummaryBox() {
    final prixBase = subtotal;

    final totalFinalValue =
        totalFinal;

    final reduction =
        totalReduction;

    final hasReduction =
        reduction > 0;

    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: borderGrey,
        ),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            'Prix par nuit',
            '${formatPrice(pricePerNight)} FCFA',
          ),

          const SizedBox(height: 8),

          _buildPriceRow(
            'Nombre de nuits',
            '$totalNights',
          ),

          const SizedBox(height: 8),

          _buildPriceRow(
            'Sous-total',
            '${formatPrice(prixBase)} FCFA',
          ),

          if (hasReduction) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
              children: [
                Text(
                  'Réduction',
                  style:
                  GoogleFonts.poppins(
                    color:
                    successGreen,
                  ),
                ),
                Text(
                  '- ${formatPrice(reduction)} FCFA',
                  style:
                  GoogleFonts.poppins(
                    color:
                    successGreen,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          const Padding(
            padding:
            EdgeInsets.symmetric(
              vertical: 12,
            ),
            child: Divider(
              height: 1,
            ),
          ),

          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
            children: [
              Text(
                'Total à payer',
                style:
                GoogleFonts.poppins(
                  color: textDark,
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${formatPrice(totalFinalValue)} FCFA',
                style:
                GoogleFonts.poppins(
                  color:
                  _accentColor,
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      String label,
      String value,
      ) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment
          .spaceBetween,
      children: [
        Text(
          label,
          style:
          GoogleFonts.poppins(
            color: textGrey,
          ),
        ),
        Text(
          value,
          style:
          GoogleFonts.poppins(
            color: textDark,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
      String title, {
        bool showClose = true,
      }) {
    final adresse =
        widget.appartement[
        'adresse']
            ?.toString() ??
            '';

    final titre =
        widget.appartement[
        'titre']
            ?.toString() ??
            'Appartement';

    final ville =
        widget.appartement[
        'ville']
            ?.toString() ??
            '';

    final location = [
      titre,
      adresse,
      ville,
    ].where(
          (e) => e.isNotEmpty,
    ).join(' • ');

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment
          .start,
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style:
                GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  _accentColor,
                ),
              ),
            ),
            if (showClose)
              GestureDetector(
                onTap: () =>
                    Navigator.pop(
                      context,
                    ),
                child:
                const Icon(
                  Icons.close,
                  color:
                  Colors.grey,
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        if (location.isNotEmpty)
          Text(
            '• $location',
            style:
            GoogleFonts.poppins(
              color: textGrey,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
          ),

        const SizedBox(height: 4),

        Text(
          getFormattedDates(),
          style:
          GoogleFonts.poppins(
            color: textGrey,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  // ============================================================
  // ÉTAPE 1 : CHOIX MÉTHODE
  // ============================================================

  Widget _selectStep() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment
          .start,
      children: [
        _buildHeader(
          'Méthode de paiement',
        ),

        Expanded(
          child:
          SingleChildScrollView(
            child: Column(
              children:
              methods.map((m) {
                final isSelected =
                    selectedMethod ==
                        m.id;

                final isCard =
                    m.id ==
                        'carte_bancaire';

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedMethod =
                          m.id;
                    });
                  },
                  child:
                  AnimatedContainer(
                    duration:
                    const Duration(
                      milliseconds:
                      200,
                    ),
                    margin:
                    const EdgeInsets
                        .only(
                      bottom: 12,
                    ),
                    padding:
                    const EdgeInsets
                        .all(16),
                    decoration:
                    BoxDecoration(
                      color: isSelected
                          ? lightOrange
                          : Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                        16,
                      ),
                      border:
                      Border.all(
                        color: isSelected
                            ? _accentColor
                            : borderGrey,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child:
                          Padding(
                            padding:
                            const EdgeInsets
                                .all(
                              6,
                            ),
                            child:
                            Image.asset(
                              m.icon,
                              fit: BoxFit
                                  .contain,
                              errorBuilder:
                                  (
                                  context,
                                  error,
                                  stackTrace,
                                  ) {
                                return Icon(
                                  Icons
                                      .payments_outlined,
                                  color:
                                  _accentColor,
                                  size:
                                  32,
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 16,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                    Text(
                                      m.name,
                                      style:
                                      GoogleFonts
                                          .poppins(
                                        color:
                                        textDark,
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                        fontSize:
                                        15,
                                      ),
                                    ),
                                  ),

                                  if (isCard)
                                    Container(
                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                        horizontal:
                                        7,
                                        vertical:
                                        3,
                                      ),
                                      decoration:
                                      BoxDecoration(
                                        color: Colors
                                            .grey
                                            .shade100,
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                          6,
                                        ),
                                      ),
                                      child:
                                      Text(
                                        'Bientôt',
                                        style:
                                        GoogleFonts
                                            .poppins(
                                          fontSize:
                                          9,
                                          fontWeight:
                                          FontWeight
                                              .w600,
                                          color:
                                          textGrey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(
                                height: 2,
                              ),

                              Text(
                                m.desc,
                                style:
                                GoogleFonts
                                    .poppins(
                                  color:
                                  textGrey,
                                  fontSize:
                                  12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Icon(
                          isSelected
                              ? Icons
                              .check_circle
                              : Icons
                              .radio_button_unchecked,
                          color:
                          isSelected
                              ? _accentColor
                              : borderGrey,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        Row(
          children: [
            Expanded(
              child:
              OutlinedButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                    ),
                style:
                OutlinedButton
                    .styleFrom(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 16,
                  ),
                  side:
                  BorderSide(
                    color:
                    borderGrey,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
                child: Text(
                  'Annuler',
                  style:
                  GoogleFonts
                      .poppins(
                    color:
                    textDark,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child:
              ElevatedButton(
                onPressed:
                selectedMethod ==
                    null
                    ? null
                    : nextStep,
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  _accentColor,
                  disabledBackgroundColor:
                  _accentColor
                      .withValues(
                    alpha: 0x5A,
                  ),
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 16,
                  ),
                  elevation: 0,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
                child: Text(
                  'Continuer',
                  style:
                  GoogleFonts
                      .poppins(
                    color:
                    Colors.white,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // ÉTAPE 2 : FORMULAIRE
  // ============================================================

  Widget _formStep() {
    final isCard =
        selectedMethod ==
            'carte_bancaire';

    final selectedPaymentMethod =
    methods.firstWhere(
          (m) => m.id == selectedMethod,
      orElse: () =>
      methods.first,
    );

    final selectedIcon =
        selectedPaymentMethod.icon;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment
          .start,
      children: [
        _buildHeader(
          'Confirmer le paiement',
        ),

        Expanded(
          child:
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                // =================================================
                // MOBILE MONEY
                // =================================================

                if (!isCard) ...[
                  Text(
                    'NUMÉRO UTILISÉ POUR LE PAIEMENT *',
                    style:
                    GoogleFonts
                        .poppins(
                      color:
                      textGrey,
                      fontSize: 12,
                      fontWeight:
                      FontWeight
                          .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      GestureDetector(
                        onTap:
                        _showCountryPicker,
                        child:
                        Container(
                          height: 56,
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal:
                            12,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            Colors
                                .white,
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                            border:
                            Border.all(
                              color:
                              borderGrey,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                selectedCountryCode,
                                style:
                                GoogleFonts
                                    .poppins(
                                  fontSize:
                                  16,
                                  fontWeight:
                                  FontWeight
                                      .w500,
                                ),
                              ),
                              const Icon(
                                Icons
                                    .arrow_drop_down,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child:
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            _formatPhone(value);
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: _getExamplePhone(),
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                            ),
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: Colors.grey,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: borderGrey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _accentColor,
                                width: 1.5,
                              ),
                            ),
                            errorText: _validatePaymentPhone(),
                            errorStyle: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding:
                    EdgeInsets.only(
                      top: 4.h,
                      left: 8.w,
                    ),
                    child: Text(
                      '$selectedCountryName • '
                          '${_getPhoneLength()} chiffres',
                      style:
                      GoogleFonts
                          .poppins(
                        fontSize:
                        11.sp,
                        color:
                        Colors
                            .grey[500],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Vous pouvez modifier ce numéro '
                        's\'il est différent de celui utilisé '
                        'pour votre compte.',
                    style:
                    GoogleFonts
                        .poppins(
                      fontSize:
                      10.5.sp,
                      color:
                      textGrey,
                    ),
                  ),
                ]

                // =================================================
                // CARTE BANCAIRE
                // =================================================

                else ...[
                  Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets
                        .all(16),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFF8F9FC,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        14,
                      ),
                      border:
                      Border.all(
                        color:
                        borderGrey,
                      ),
                    ),
                    child:
                    Column(
                      children: [
                        Icon(
                          Icons
                              .credit_card_outlined,
                          size: 42,
                          color:
                          _accentColor,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          'Paiement par carte',
                          style:
                          GoogleFonts
                              .poppins(
                            fontSize:
                            16,
                            fontWeight:
                            FontWeight
                                .w600,
                            color:
                            textDark,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          'Le paiement par carte sera '
                              'activé après intégration du '
                              'prestataire de paiement.',
                          textAlign:
                          TextAlign
                              .center,
                          style:
                          GoogleFonts
                              .poppins(
                            fontSize:
                            12,
                            color:
                            textGrey,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [
                            _buildCardBrand(
                              'VISA',
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            _buildCardBrand(
                              'Mastercard',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(
                  height: 12,
                ),

                _buildSummaryBox(),
              ],
            ),
          ),
        ),

        // ========================================================
        // LOGO
        // ========================================================

        if (selectedMethod != null)
          Padding(
            padding:
            const EdgeInsets
                .symmetric(
              vertical: 20,
            ),
            child:
            Center(
              child:
              Image.asset(
                selectedIcon,
                height: 60,
                fit: BoxFit
                    .contain,
                errorBuilder:
                    (
                    context,
                    error,
                    stackTrace,
                    ) {
                  return const SizedBox
                      .shrink();
                },
              ),
            ),
          ),

        // ========================================================
        // BOUTONS
        // ========================================================

        Row(
          children: [
            Expanded(
              child:
              OutlinedButton(
                onPressed:
                prevStep,
                style:
                OutlinedButton
                    .styleFrom(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 16,
                  ),
                  side:
                  BorderSide(
                    color:
                    borderGrey,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
                child:
                Text(
                  'Retour',
                  style:
                  GoogleFonts
                      .poppins(
                    color:
                    textDark,
                    fontSize: 16,
                    fontWeight:
                    FontWeight
                        .w600,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child:
              ElevatedButton(
                onPressed:
                _submitPayment,
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  _accentColor,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 16,
                  ),
                  elevation: 0,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
                child:
                Text(
                  isCard
                      ? 'Continuer'
                      : 'Confirmer',
                  style:
                  GoogleFonts
                      .poppins(
                    color:
                    Colors.white,
                    fontSize: 16,
                    fontWeight:
                    FontWeight
                        .w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // LOGOS CARTE
  // ============================================================

  Widget _buildCardBrand(
      String text,
      ) {
    return Container(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          6,
        ),
        border:
        Border.all(
          color: borderGrey,
        ),
      ),
      child:
      Text(
        text,
        style:
        GoogleFonts
            .poppins(
          fontSize: 10,
          fontWeight:
          FontWeight.bold,
          color:
          textDark,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return ClipRRect(
      borderRadius:
      const BorderRadius
          .vertical(
        top: Radius.circular(24),
      ),
      child:
      BackdropFilter(
        filter:
        ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child:
        Container(
          padding:
          const EdgeInsets
              .all(24),
          decoration:
          BoxDecoration(
            color:
            Colors.white,
            borderRadius:
            const BorderRadius
                .vertical(
              top:
              Radius.circular(
                24,
              ),
            ),
            border:
            Border(
              top:
              BorderSide(
                color:
                _accentColor,
                width: 4,
              ),
            ),
          ),
          child:
          Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration:
                const Duration(
                  milliseconds:
                  300,
                ),
                height:
                step == 0
                    ? 480
                    : 600,
                child:
                PageView(
                  controller:
                  pageController,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  children: [
                    _selectStep(),
                    _formStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    phoneController
        .dispose();

    cardController
        .dispose();

    expiryController
        .dispose();

    cvvController
        .dispose();

    pageController
        .dispose();

    super.dispose();
  }
}
