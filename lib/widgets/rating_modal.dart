// lib/widgets/rating_modal.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final bool showNumber;

  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 14,
    this.color = Colors.amber,
    this.showNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(starCount, (index) {
            final diff = rating - index;

            IconData icon;

            if (diff >= 1) {
              icon = Icons.star;
            } else if (diff >= 0.5) {
              icon = Icons.star_half;
            } else {
              icon = Icons.star_border;
            }

            return Icon(icon, size: size, color: color);
          }),
        ),
        if (showNumber) ...[
          SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: size,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]
      ],
    );
  }
}