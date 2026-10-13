import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../widgets/room_info_item.dart';

class ReservationRoomsSection extends StatelessWidget {
  final Map<String, dynamic>? appartementInfo;
  final String type;

  const ReservationRoomsSection({
    super.key,
    required this.appartementInfo,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        child: Wrap(
          spacing: 8.w,
          runSpacing: 15.h,
          alignment: WrapAlignment.center,
          children: [
            RoomInfoItem(icon: Icons.apartment_outlined, label: type, value: '', width: 80.w),
            RoomInfoItem(
              icon: Icons.stairs_outlined,
              label: 'Étage',
              value: appartementInfo?['etage']?.toString() ?? '',
              width: 110.w,
            ),
            RoomInfoItem(
              icon: Icons.weekend_outlined,
              label: 'Salon',
              value: appartementInfo?['salon']?.toString() ?? '',
              width: 90.w,
            ),
            RoomInfoItem(
              icon: Icons.king_bed_outlined,
              label: 'Chbres',
              value: appartementInfo?['chambre']?.toString() ?? '',
              width: 120.w,
            ),
            RoomInfoItem(
              icon: Icons.bathtub_outlined,
              label: 'Pièces',
              value: appartementInfo?['douche']?.toString() ?? '',
              width: 100.w,
            ),
            RoomInfoItem(
              icon: Icons.kitchen_outlined,
              label: 'Cuisine',
              value: appartementInfo?['cuisine']?.toString() ?? '',
              width: 110.w,
            ),
          ],
        ),
      ),
    );
  }
}