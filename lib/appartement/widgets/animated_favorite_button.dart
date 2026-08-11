import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/favorite_appart/favorites_service.dart';

class AnimatedFavoriteButton extends StatefulWidget {
  final String appartementId;
  final Map<String, dynamic> appartementData;
  final double iconSize;
  final bool hasBackground;

  const AnimatedFavoriteButton({
    super.key,
    required this.appartementId,
    required this.appartementData,
    required this.iconSize,
    this.hasBackground = false,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _triggerAnimation() => _controller.forward(from: 0.0);

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.watch<FavoritesService>().isFavorite(widget.appartementId);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          _triggerAnimation();
          context.read<FavoritesService>().toggleFavorite(
            widget.appartementId,
            appartementData: widget.appartementData,
          );
        },
        child: widget.hasBackground
            ? Container(
          padding: EdgeInsets.all(4.w),
          decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
          child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: widget.iconSize, color: isFavorite ? Colors.red : Colors.white),
        )
            : Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: widget.iconSize, color: isFavorite ? Colors.red : Colors.grey.shade500),
      ),
    );
  }
}