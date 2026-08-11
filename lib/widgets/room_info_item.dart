import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoomInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double width;
  const RoomInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 25.sp, color: const Color(0xFFE36830)),
          SizedBox(width: 3.w),
          Flexible(
            child: Text(
              value.isEmpty ? label : '$label : $value',
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF673A15)
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}