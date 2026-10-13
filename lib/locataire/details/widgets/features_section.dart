import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../widgets/feature_card.dart';

class FeaturesSection extends StatelessWidget {
  final Map<String, dynamic>? info;
  final Map<String, dynamic>? role;

  const FeaturesSection({
    super.key,
    required this.info,
    required this.role,
  });

  String _ouiNon(dynamic value) {
    if (value == null) {
      return 'Non';
    }
    final v = value.toString().toLowerCase().trim();
    if (v.contains('animaux')) {
      return (v.contains('chien') || v.contains('chat') || v.contains('accept')) ? 'Oui' : 'Non';
    }
    if (v.contains('fumeur')) {
      return v.contains('accept') ? 'Oui' : 'Non';
    }
    if (v.contains('fête') || v.contains('fete')) {
      return v.contains('accept') ? 'Oui' : 'Non';
    }
    return (v == 'oui' ||
        v == 'true' ||
        v == '1' ||
        v.contains('accept') ||
        v.contains('yes') ||
        v.contains('accepter'))
        ? 'Oui'
        : 'Non';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFEFE0),
      height: 350.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
        child: Row(
          children: [
            FeatureCard(
              width: 230.w,
              title: 'Aperçu',
              items: [
                FeatureItemData(
                  Icons.flash_on,
                  'Service inclus',
                  _ouiNon(info?['service_inclus']),
                ),
                FeatureItemData(
                  Icons.wifi,
                  'Internet',
                  _ouiNon(info?['internet']),
                ),
                FeatureItemData(
                  Icons.local_parking,
                  'Stationnement',
                  _ouiNon(info?['stationnement']),
                ),
                FeatureItemData(
                  Icons.pets,
                  'Animaux',
                  _ouiNon(role?['animaux']),
                ),
              ],
            ),
            SizedBox(width: 30.w),
            FeatureCard(
              width: 250.w,
              title: "L'unité d'habitation",
              items: [
                FeatureItemData(
                  Icons.straighten,
                  'Taille',
                  '${info?['taille']?.toString() ?? '0'} m²',
                ),
                FeatureItemData(
                  Icons.chair,
                  'Meublé',
                  _ouiNon(info?['meuble']),
                ),
                FeatureItemData(
                  Icons.ac_unit,
                  'Climatisation',
                  _ouiNon(info?['climatisation']),
                ),
                FeatureItemData(
                  Icons.smoking_rooms,
                  'Fumeurs acceptés',
                  _ouiNon(role?['fumeur']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}