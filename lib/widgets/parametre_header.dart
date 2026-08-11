import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ParametreHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;

  const ParametreHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne avec bouton retour
        Padding(
          padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5CE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Color (0xFF8A4E1E),),
                ),
              ),
            ],
          ),
        ),

        // Ligne avec le titre
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 40),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 27.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8A4E1E),
            ),
          ),
        ),
      ],
    );
  }
}
