import 'package:flutter/material.dart';
import 'package:service/rating/rating_widget.dart';

class ReservationRatingSection extends StatelessWidget {
  final double average;
  final int count;
  final int? currentUserRating;
  final VoidCallback onRatePressed;

  const ReservationRatingSection({
    super.key,
    required this.average,
    required this.count,
    required this.currentUserRating,
    required this.onRatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return RatingSection(
      average: average,
      count: count,
      currentUserRating: currentUserRating,
      onRatePressed: onRatePressed,
    );
  }
}