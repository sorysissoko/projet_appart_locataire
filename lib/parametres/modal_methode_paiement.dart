import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final Function(String method, String? phone, String? card) onSuccess;
  final Map<String, dynamic> appartement;
  final int totalNights;
  final double totalPrice;
  final DateTime? startDate;
  final DateTime? endDate;

  const PaymentBottomSheet({
    super.key,
    required this.amount,
    required this.onSuccess,
    required this.appartement,
    required this.totalNights,
    required this.totalPrice,
    this.startDate,
    this.endDate,
  });

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  int step = 0;
  String? selectedMethod;

  final phoneController = TextEditingController();
  final cardController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  final PageController pageController = PageController();

  // Couleurs principales
  final Color _accentColor = const Color(0xFFE85D26);
  final Color lightOrange = const Color(0xFFFFF6F1);
  final Color textDark = const Color(0xFF2D3748);
  final Color textGrey = const Color(0xFF718096);
  final Color borderGrey = const Color(0xFFE2E8F0);
  final Color successGreen = const Color(0xFF00C853);

  // Pays où Orange Money est disponible
  String selectedCountryCode = '+223';
  String selectedCountryName = 'Mali';

  final List<Map<String, String>> orangeMoneyCountries = [
    {'code': '+223', 'name': 'Mali', 'flag': '🇲🇱', 'length': '8', 'example': '70 00 00 00'},
    {'code': '+221', 'name': 'Sénégal', 'flag': '🇸🇳', 'length': '9', 'example': '77 000 00 00'},
    {'code': '+225', 'name': 'Côte d\'Ivoire', 'flag': '🇨🇮', 'length': '8', 'example': '01 02 03 04'},
    {'code': '+226', 'name': 'Burkina Faso', 'flag': '🇧🇫', 'length': '8', 'example': '70 00 00 00'},
    {'code': '+227', 'name': 'Niger', 'flag': '🇳🇪', 'length': '8', 'example': '90 00 00 00'},
    {'code': '+229', 'name': 'Bénin', 'flag': '🇧🇯', 'length': '8', 'example': '97 00 00 00'},
    {'code': '+228', 'name': 'Togo', 'flag': '🇹🇬', 'length': '8', 'example': '90 00 00 00'},
    {'code': '+224', 'name': 'Guinée', 'flag': '🇬🇳', 'length': '9', 'example': '60 00 00 00'},
    {'code': '+237', 'name': 'Cameroun', 'flag': '🇨🇲', 'length': '9', 'example': '69 00 00 00'},
    {'code': '+242', 'name': 'Congo', 'flag': '🇨🇬', 'length': '9', 'example': '06 000 000'},
    {'code': '+243', 'name': 'RDC', 'flag': '🇨🇩', 'length': '9', 'example': '81 00 00 00'},
    {'code': '+261', 'name': 'Madagascar', 'flag': '🇲🇬', 'length': '9', 'example': '32 00 00 00'},
    {'code': '+212', 'name': 'Maroc', 'flag': '🇲🇦', 'length': '9', 'example': '06 00 00 00'},
    {'code': '+222', 'name': 'Mauritanie', 'flag': '🇲🇷', 'length': '8', 'example': '30 00 00 00'},
    {'code': '+245', 'name': 'Guinée-Bissau', 'flag': '🇬🇼', 'length': '7', 'example': '95 00 00'},
    {'code': '+231', 'name': 'Liberia', 'flag': '🇱🇷', 'length': '8', 'example': '77 00 00 00'},
    {'code': '+232', 'name': 'Sierra Leone', 'flag': '🇸🇱', 'length': '8', 'example': '76 00 00 00'},
    {'code': '+267', 'name': 'Botswana', 'flag': '🇧🇼', 'length': '8', 'example': '71 00 00 00'},
    {'code': '+20', 'name': 'Égypte', 'flag': '🇪🇬', 'length': '10', 'example': '0100 000 0000'},
  ];

  final methods = [
    PaymentMethod(
      id: "orange",
      name: "Orange Money",
      desc: "Paiement mobile Orange",
      bg: const Color(0xFFFFF3E8),
      icon: "assets/images/orangemoney.png",
    ),
    PaymentMethod(
      id: "moov",
      name: "Moov Money",
      desc: "Paiement mobile Moov Africa",
      bg: const Color(0xFFE8F0FF),
      icon: "assets/images/Moov_Africa_Malitel_(logo).png",
    ),
    PaymentMethod(
      id: "wave",
      name: "Wave",
      desc: "Transfert d'argent rapide",
      bg: const Color(0xFFE8F6FF),
      icon: "assets/images/wave-logo.png",
    ),
    PaymentMethod(
      id: "visa",
      name: "Carte bancaire",
      desc: "Visa / Mastercard",
      bg: const Color(0xFFECEEFF),
      icon: "assets/images/visa.png",
    ),
  ];

  String formatPrice(num price) {
    final formatter = NumberFormat("#,###", "fr_FR");
    return formatter.format(price);
  }

  double get pricePerNight {
    return double.tryParse(widget.appartement['prix']?.toString() ?? '0') ?? 0.0;
  }

  int get actualTotalNights {
    if (widget.startDate != null && widget.endDate != null) {
      return widget.endDate!.difference(widget.startDate!).inDays;
    }
    return widget.totalNights;
  }

  int get totalNights {
    return actualTotalNights;
  }

  double get totalFinal {
    return widget.totalPrice;
  }

  double get totalWithoutReduction {
    return pricePerNight * totalNights;
  }

  Map<String, double> get reductions {
    double fraisService = 5000;
    double prixProprietaire = pricePerNight - fraisService;
    return _calculerPrixAvecReduction(
      prixProprietaire: prixProprietaire,
      fraisService: fraisService,
      nuits: totalNights,
    );
  }

  Map<String, double> _calculerPrixAvecReduction({
    required double prixProprietaire,
    required double fraisService,
    required int nuits,
  }) {
    double reductionProprietaire = 0;
    double reductionService = 0;

    if (nuits >= 1 && nuits <= 2) {
      reductionProprietaire = 0;
      reductionService = 0;
    } else if (nuits >= 3 && nuits <= 4) {
      reductionProprietaire = 0.05;
      reductionService = 0.0;
    } else if (nuits == 5) {
      reductionProprietaire = 0.07;
      reductionService = 0.02;
    } else if (nuits >= 6 && nuits <= 10) {
      reductionProprietaire = 0.10;
      reductionService = 0.03;
    } else if (nuits >= 11 && nuits <= 15) {
      reductionProprietaire = 0.13;
      reductionService = 0.05;
    } else if (nuits >= 16 && nuits <= 20) {
      reductionProprietaire = 0.17;
      reductionService = 0.07;
    } else if (nuits >= 21 && nuits <= 25) {
      reductionProprietaire = 0.20;
      reductionService = 0.10;
    } else if (nuits >= 26 && nuits <= 30) {
      reductionProprietaire = 0.25;
      reductionService = 0.15;
    }

    double reductionProprietaireMontant = prixProprietaire * reductionProprietaire;
    double reductionServiceMontant = fraisService * reductionService;
    double totalReduction = (reductionProprietaireMontant + reductionServiceMontant) * nuits;

    return {
      "reductionProprietaire": reductionProprietaireMontant * nuits,
      "reductionService": reductionServiceMontant * nuits,
      "totalReduction": totalReduction,
      "total": totalReduction,
    };
  }

  // Validation du numéro selon le pays
  bool validatePhone(String phone) {
    final cleaned = phone.replaceAll(" ", "").replaceAll("-", "");
    final country = orangeMoneyCountries.firstWhere(
          (c) => c['code'] == selectedCountryCode,
      orElse: () => {'length': '8'},
    );
    final int expectedLength = int.parse(country['length']!);
    return RegExp(r'^[0-9]{' + expectedLength.toString() + r'}$').hasMatch(cleaned);
  }

  // Formatage auto du téléphone
  void _formatPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final country = orangeMoneyCountries.firstWhere(
          (c) => c['code'] == selectedCountryCode,
      orElse: () => {'length': '8'},
    );
    final int length = int.parse(country['length']!);

    String formatted = '';
    if (length == 8) {
      for (int i = 0; i < digits.length && i < 8; i++) {
        if (i == 2 || i == 4 || i == 6) formatted += ' ';
        formatted += digits[i];
      }
    } else if (length == 9) {
      for (int i = 0; i < digits.length && i < 9; i++) {
        if (i == 2 || i == 5) formatted += ' ';
        formatted += digits[i];
      }
    } else if (length == 10) {
      for (int i = 0; i < digits.length && i < 10; i++) {
        if (i == 3 || i == 6) formatted += ' ';
        formatted += digits[i];
      }
    } else {
      formatted = digits;
    }

    if (phoneController.text != formatted) {
      phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // Validation carte Visa
  bool validateVisaCard(String cardNumber) {
    final cleaned = cardNumber.replaceAll(" ", "").replaceAll("-", "");
    return RegExp(r'^4[0-9]{12}(?:[0-9]{3})?$').hasMatch(cleaned);
  }

  // Formatage auto de la carte bancaire
  void _formatCardNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += digits[i];
    }
    if (cardController.text != formatted) {
      cardController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // Formatage auto de l'expiration (MM/AA)
  void _formatExpiry(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) formatted += '/';
      formatted += digits[i];
    }
    if (expiryController.text != formatted) {
      expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void nextStep() {
    setState(() => step++);
    pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void prevStep() {
    setState(() => step--);
    pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String getFormattedDates() {
    if (widget.startDate != null && widget.endDate != null) {
      final start = widget.startDate!;
      final end = widget.endDate!;
      final nuits = end.difference(start).inDays;
      return "$nuits nuit${nuits > 1 ? 's' : ''} • Du ${_formatDateMonth(start)} au ${_formatDateFull(end)}";
    }
    return "Dates non sélectionnées";
  }

  String _formatDateMonth(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  String _formatDateFull(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 450,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Sélectionnez votre pays",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: orangeMoneyCountries.length,
                  itemBuilder: (context, index) {
                    final country = orangeMoneyCountries[index];
                    return ListTile(
                      leading: Text(country['flag']!, style: const TextStyle(fontSize: 28)),
                      title: Text(country['name']!),
                      subtitle: Text("${country['code']} • ${country['length']} chiffres"),
                      trailing: selectedCountryCode == country['code']
                          ? Icon(Icons.check_circle, color: _accentColor)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedCountryCode = country['code']!;
                          selectedCountryName = country['name']!;
                          phoneController.clear();
                        });
                        Navigator.pop(context);
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
    final country = orangeMoneyCountries.firstWhere(
          (c) => c['code'] == selectedCountryCode,
      orElse: () => {'example': '70 00 00 00'},
    );
    return country['example']!;
  }

  String _getPhoneLength() {
    final country = orangeMoneyCountries.firstWhere(
          (c) => c['code'] == selectedCountryCode,
      orElse: () => {'length': '8'},
    );
    return country['length']!;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: _accentColor, width: 4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: step == 0 ? 480 : (step == 1 ? 600 : 350),
                child: PageView(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
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

  Widget _buildHeader(String title, {bool showClose = true}) {
    final adresse = widget.appartement['adresse']?.toString() ?? 'Type';
    final titre = widget.appartement['titre']?.toString() ?? 'Titre';
    final ville = widget.appartement['ville']?.toString() ?? 'Ville';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _accentColor,
              ),
            ),
            if (showClose)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "• $titre $adresse $ville",
          style: TextStyle(color: textGrey, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          getFormattedDates(),
          style: TextStyle(color: textGrey, fontSize: 12),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSummaryBox() {
    final reductionTotal = reductions['totalReduction'] ?? 0;
    final hasReduction = reductionTotal > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Prix par nuit", style: TextStyle(color: textGrey)),
              Text("${formatPrice(pricePerNight)} FCFA",
                  style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Nombre de nuits", style: TextStyle(color: textGrey)),
              Text("$totalNights",
                  style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Sous-total", style: TextStyle(color: textGrey)),
              Text("${formatPrice(pricePerNight * totalNights)} FCFA",
                  style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
            ],
          ),
          if (hasReduction) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Réduction", style: TextStyle(color: Colors.green)),
                Text("- ${formatPrice(reductionTotal)} FCFA",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total à payer",
                  style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                "${formatPrice(totalFinal)} FCFA",
                style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selectStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Méthode de paiement"),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: methods.map((m) {
                final isSelected = selectedMethod == m.id;

                return GestureDetector(
                  onTap: () => setState(() => selectedMethod = m.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? lightOrange : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _accentColor : borderGrey,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              m.icon,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: TextStyle(
                                  color: textDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.desc,
                                style: TextStyle(color: textGrey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? _accentColor : borderGrey,
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: borderGrey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Annuler", style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: selectedMethod == null ? null : nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  disabledBackgroundColor: _accentColor.withValues(alpha: 0x5A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Continuer", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _formStep() {
    final isCard = selectedMethod == "visa";

    // Récupération dynamique de l'icône de la méthode sélectionnée
    final selectedIcon = methods.firstWhere((m) => m.id == selectedMethod, orElse: () => methods.first).icon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Confirmer le paiement"),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCard) ...[
                  Text("NUMÉRO DE TÉLÉPHONE", style: TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showCountryPicker,
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderGrey),
                          ),
                          child: Row(
                            children: [
                              Text(
                                selectedCountryCode,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: _formatPhone,
                          decoration: InputDecoration(
                            hintText: _getExamplePhone(),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _accentColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 2.h, left: 8.w),
                    child: Text(
                      "$selectedCountryName • ${_getPhoneLength()} chiffres",
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ),
                ] else ...[
                  Text("NUMÉRO DE CARTE", style: TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cardController,
                    keyboardType: TextInputType.number,
                    onChanged: _formatCardNumber,
                    decoration: InputDecoration(
                      hintText: "XXXX XXXX XXXX XXXX",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.credit_card_outlined, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("EXPIRATION", style: TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: expiryController,
                              keyboardType: TextInputType.number,
                              onChanged: _formatExpiry,
                              decoration: InputDecoration(
                                hintText: "MM/AA",
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderGrey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _accentColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("CVV", style: TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: cvvController,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "123",
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderGrey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _accentColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 5),
                _buildSummaryBox(),
              ],
            ),
          ),
        ),

        // --- EMPLACEMENT DU LOGO : Parfaitement centré entre Total et les Boutons ---
        if (selectedMethod != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: Center(
              child: Image.asset(
                selectedIcon,
                height: 70, // Taille optimale et harmonieuse
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),

        const SizedBox(height: 1),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: borderGrey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Retour", style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (!isCard) {
                    final phoneNumber = phoneController.text.replaceAll(" ", "").replaceAll("-", "");
                    if (!validatePhone(phoneNumber)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Numéro invalide (${_getPhoneLength()} chiffres requis)"),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    final fullPhoneNumber = "$selectedCountryCode$phoneNumber";
                    widget.onSuccess(selectedMethod!, fullPhoneNumber, null);
                  } else {
                    final cardNumber = cardController.text.replaceAll(" ", "").replaceAll("-", "");
                    if (!validateVisaCard(cardNumber)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Numéro de carte Visa invalide")),
                      );
                      return;
                    }
                    widget.onSuccess(selectedMethod!, null, cardNumber);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Continuer", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}