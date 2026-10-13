import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE85D26),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 8.w,
            top: 8.h,
            bottom: 8.h,
          ),
          child: Row(
            children: [
              // ==================================================
              // TITRE
              // ==================================================

              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // ACTIONS
              // ==================================================

              if (actions != null && actions!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    left: 8.w,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(70.h);
}