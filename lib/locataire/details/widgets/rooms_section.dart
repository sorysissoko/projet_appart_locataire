import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../widgets/room_info_item.dart';

class RoomsSection extends StatelessWidget {
  final Map<String, dynamic>? info;
  final String type;

  const RoomsSection({
    super.key,
    required this.info,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Wrap(
          spacing: 12.w,
          runSpacing: 1.h,
          alignment: WrapAlignment.center,
          children: [
            RoomInfoItem(icon: Icons.apartment_outlined, label: type, value: '', width: 80.w),
            RoomInfoItem(
              icon: Icons.stairs_outlined,
              label: 'Étage',
              value: info?['etage']?.toString() ?? '',
              width: 110.w,
            ),
            RoomInfoItem(
              icon: Icons.weekend_outlined,
              label: 'Salon',
              value: info?['salon']?.toString() ?? '',
              width: 90.w,
            ),
            RoomInfoItem(
              icon: Icons.king_bed_outlined,
              label: 'Chbres',
              value: info?['chambre']?.toString() ?? '',
              width: 120.w,
            ),
            RoomInfoItem(
              icon: Icons.bathtub_outlined,
              label: 'Pièces',
              value: info?['douche']?.toString() ?? '',
              width: 100.w,
            ),
            RoomInfoItem(
              icon: Icons.kitchen_outlined,
              label: 'Cuisine',
              value: info?['cuisine']?.toString() ?? '',
              width: 110.w,
            ),
          ],
        ),
      ),
    );
  }
}