import 'package:flutter/material.dart';

class CurrentLocationMarker extends StatefulWidget {
  final double? accuracyMeters;

  const CurrentLocationMarker({super.key, this.accuracyMeters});

  @override
  State<CurrentLocationMarker> createState() => _CurrentLocationMarkerState();
}

class _CurrentLocationMarkerState extends State<CurrentLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: false);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer translucent pulsating ring
            Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0288D1).withValues(
                    alpha: (1.4 - _pulseAnimation.value).clamp(0.0, 0.4),
                  ),
                ),
              ),
            ),
            // White outline ring
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            // Deep blue core
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0288D1),
              ),
            ),
          ],
        );
      },
    );
  }
}
