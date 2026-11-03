import 'package:flutter/material.dart';

import '../models/incident_model.dart';

class IncidentMarkerWidget extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onTap;

  const IncidentMarkerWidget({
    super.key,
    required this.incident,
    required this.onTap,
  });

  Color _getCategoryColor() {
    switch (incident.category) {
      case 'ROAD_ACCIDENT':
        return const Color(0xFFD32F2F); // Red
      case 'TRAFFIC_HAZARD':
        return const Color(0xFFE65100); // Deep Orange
      case 'WOMEN_SAFETY':
        return const Color(0xFFC2185B); // Magenta/Pink
      case 'HARASSMENT':
        return const Color(0xFF7B1FA2); // Purple
      case 'ASSAULT':
        return const Color(0xFFB71C1C); // Crimson
      case 'POOR_STREET_LIGHTING':
        return const Color(0xFFF57C00); // Amber
      case 'UNSAFE_OR_ISOLATED_AREA':
        return const Color(0xFF3949AB); // Indigo
      case 'ROAD_OBSTRUCTION':
        return const Color(0xFF5D4037); // Brown
      case 'THEFT':
        return const Color(0xFF455A64); // Blue Grey
      default:
        return const Color(0xFF616161);
    }
  }

  IconData _getCategoryIcon() {
    switch (incident.category) {
      case 'ROAD_ACCIDENT':
        return Icons.car_crash_outlined;
      case 'TRAFFIC_HAZARD':
        return Icons.warning_amber_rounded;
      case 'WOMEN_SAFETY':
        return Icons.shield_outlined;
      case 'HARASSMENT':
        return Icons.record_voice_over_outlined;
      case 'ASSAULT':
        return Icons.personal_injury_outlined;
      case 'POOR_STREET_LIGHTING':
        return Icons.lightbulb_outline;
      case 'UNSAFE_OR_ISOLATED_AREA':
        return Icons.visibility_off_outlined;
      case 'ROAD_OBSTRUCTION':
        return Icons.construction_outlined;
      case 'THEFT':
        return Icons.lock_outline;
      default:
        return Icons.report_problem_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor();
    final iconData = _getCategoryIcon();

    Color borderColor;
    double borderWidth = 2.0;

    if (incident.isOfficialSource) {
      borderColor = const Color(
        0xFFFFD54F,
      ); // Gold border for official police audits
      borderWidth = 2.5;
    } else if (incident.verificationStatus == 'VERIFIED') {
      borderColor = const Color(
        0xFF81C784,
      ); // Green border for verified community
    } else if (incident.isPending) {
      borderColor = const Color(0xFF0288D1); // Blue border for pending
    } else {
      borderColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: incident.isPending
              ? catColor.withValues(alpha: 0.85)
              : catColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: catColor.withValues(alpha: 0.35),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(child: Icon(iconData, color: Colors.white, size: 15)),
            // Badge indicator in top-right corner for pending or official
            if (incident.isPending)
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0288D1),
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else if (incident.isOfficialSource)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD54F),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
