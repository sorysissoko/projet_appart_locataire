import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/parametre_header.dart';

class ModePaiementPage extends StatefulWidget {
  const ModePaiementPage({super.key});

  @override
  State<ModePaiementPage> createState() => _ModePaiementPageState();
}

class _ModePaiementPageState extends State<ModePaiementPage> {
  // Sample data - replace with actual payment methods from your backend
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      icon: Icons.credit_card,
      name: 'Carte de crédit',
      lastDigits: '**** 1234',
      isDefault: true,
    ),
    PaymentMethod(
      icon: Icons.account_balance_wallet,
      name: 'PayPal',
      email: 'user@example.com',
      isDefault: false,
    ),
    PaymentMethod(
      icon: Icons.account_balance,
      name: 'Virement bancaire',
      lastDigits: '**** 5678',
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFF2E5),
          body: Column(
            children: [
              // Header
              const ParametreHeader(title: "Modes de paiement"),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.w,
                            vertical: 5.h
                        ),
                        child: Text(
                          'Ajoutez et gérez vos modes de paiement grâce à notre système de paiement sécurisé.',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: const Color(0xCD8A4E1E),
                          ),
                        ),
                      ),

                      SizedBox(height: 30.h),

                      // Liste des modes de paiement existants
                      if (_paymentMethods.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(left: 16.w, bottom: 12.h),
                          child: Text(
                            'Vos méthodes de paiement',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8A4E1E),
                            ),
                          ),
                        ),
                        ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),
                        SizedBox(height: 20.h),
                      ],

                      // Bouton "Ajouter un mode de paiement"
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A4E1E),
                            minimumSize: Size(280.w, 50.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {
                            _showAddPaymentMethodDialog();
                          },
                          child: Text(
                            'Ajouter un mode de paiement',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0x80E85D26)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: const Color(0xFF8A4E1E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              method.icon,
              size: 24.sp,
              color: const Color(0xFF8A4E1E),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.name,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8A4E1E),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  method.lastDigits ?? method.email ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xCD8A4E1E),
                  ),
                ),
              ],
            ),
          ),
          if (method.isDefault)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF8A4E1E).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'Défaut',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8A4E1E),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.more_vert, size: 20.sp, color: const Color(0xFF8A4E1E)),
            onPressed: () => _showPaymentMethodOptions(method),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ajouter un mode de paiement',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8A4E1E),
                ),
              ),
              SizedBox(height: 20.h),
              _buildPaymentOption(
                icon: Icons.credit_card,
                title: 'Carte de crédit/débit',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to add card page
                },
              ),
              _buildPaymentOption(
                icon: Icons.account_balance_wallet,
                title: 'PayPal',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to add PayPal page
                },
              ),
              _buildPaymentOption(
                icon: Icons.account_balance,
                title: 'Virement bancaire',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to add bank account page
                },
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 28.sp, color: const Color(0xFF8A4E1E)),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: const Color(0xFF8A4E1E)),
      onTap: onTap,
    );
  }

  void _showPaymentMethodOptions(PaymentMethod method) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!method.isDefault)
                ListTile(
                  leading: const Icon(Icons.star, color: Color(0xFF8A4E1E)),
                  title: Text(
                    'Définir comme défaut',
                    style: GoogleFonts.inter(fontSize: 14.sp),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Update default payment method
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF8A4E1E)),
                title: Text(
                  'Modifier',
                  style: GoogleFonts.inter(fontSize: 14.sp),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit page
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Supprimer',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(method);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Supprimer le mode de paiement',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer ${method.name} ?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: GoogleFonts.inter(color: const Color(0xFF8A4E1E)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Delete payment method logic
                setState(() {
                  _paymentMethods.remove(method);
                });
              },
              child: Text(
                'Supprimer',
                style: GoogleFonts.inter(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PaymentMethod {
  final IconData icon;
  final String name;
  final String? lastDigits;
  final String? email;
  final bool isDefault;

  PaymentMethod({
    required this.icon,
    required this.name,
    this.lastDigits,
    this.email,
    required this.isDefault,
  });
}