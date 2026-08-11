import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE85D26),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 25.h, top: 8.h, bottom: 8.h),
          child: Stack(
            children: [
              // Titre centré dynamique
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Définition obligatoire de la taille de l'AppBar pour PreferredSizeWidget
  @override
  Size get preferredSize => Size.fromHeight(70.h);
}