import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/message/message.dart';
import 'package:mobile_app/parametres/profile.dart';
import 'package:mobile_app/favorite_appart/page_favorite.dart';
import 'package:mobile_app/providers/tab_provider.dart';

import '../appartement/acceuil/views/appartement_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const Color _orangeColor = Color(0xFFE85D26);

  // Dimensions et marges unifiées pour un ajustement au pixel près
  static const double _notchMargin = 8.0;
  static const double _fabDiameter = 60.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<TabProvider>(
      builder: (context, tabProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFEFE0),
          extendBody: true,
          body: IndexedStack(
            index: tabProvider.currentIndex,
            children: const [
              AppartementPage(),
              FavoritesPage(),
              MessagePage(),
              ProfilePage(),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: _buildFloatingButton(_orangeColor),

          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: CustomPaint(
                foregroundPainter: NotchedBorderPainter(
                  borderColor: Color(0xFFF6D3BD),
                  borderWidth: 2.h,
                  notchMargin: _notchMargin,
                  fabRadius: (_fabDiameter.w) / 2,
                ),
                child: BottomAppBar(
                  height: 60.h,
                  color: const Color(0xFFFEF0E6),
                  elevation: 0,
                  shape: const CircularNotchedRectangle(),
                  notchMargin: _notchMargin,
                  child: SizedBox(
                    height: 50.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(Icons.home, Icons.home_outlined, 0, _orangeColor, tabProvider),
                        _buildNavItem(Icons.favorite, Icons.favorite_border, 1, _orangeColor, tabProvider),

                        SizedBox(width: 40.w),

                        _buildNavItem(Icons.message, Icons.message_outlined, 2, _orangeColor, tabProvider),
                        _buildNavItem(Icons.person, Icons.person_outline, 3, _orangeColor, tabProvider),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Nouvelle version sans le paramètre label
  Widget _buildNavItem(
      IconData activeIcon,
      IconData inactiveIcon,
      int index,
      Color color,
      TabProvider tabProvider,
      ) {
    final isSelected = tabProvider.currentIndex == index;
    return GestureDetector(
      onTap: () => tabProvider.changeTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3.h,
            width: isSelected ? 25.w : 0,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 4.h),
          Icon(
            isSelected ? activeIcon : inactiveIcon,
            color: isSelected ? color : Color(0xA58A4E1E),
            size: 30.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(Color color) {
    return SizedBox(
      width: _fabDiameter.w,
      height: _fabDiameter.h,
      child: FloatingActionButton(
        onPressed: () {
          // Action carte
        },
        backgroundColor: color,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Icon(Icons.map, color: Colors.white, size: 26.sp),
      ),
    );
  }
}
class NotchedBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double notchMargin;
  final double fabRadius;

  const NotchedBorderPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.notchMargin,
    required this.fabRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final notchRadius = fabRadius + notchMargin;

    if (centerX - notchRadius < 0) return;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(centerX - notchRadius, 0);

    // Trace the U-shaped notch
    path.arcToPoint(
      Offset(centerX + notchRadius, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant NotchedBorderPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.notchMargin != notchMargin ||
        oldDelegate.fabRadius != fabRadius;
  }
}