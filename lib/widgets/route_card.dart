import 'package:flutter/material.dart';

import '../models/route_model.dart';
import '../models/route_score_model.dart';

class RouteCard extends StatelessWidget {
  final RouteModel route;
  final RouteScoreModel? score;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onViewRoute;
  final VoidCallback onWhyThisScore;

  const RouteCard({
    super.key,
    required this.route,
    this.score,
    required this.isSelected,
    this.isRecommended = false,
    required this.onViewRoute,
    required this.onWhyThisScore,
  });

  Color _getScoreBadgeColor(double s) {
    if (s < 25.0) return const Color(0xFF2E7D32); // Green
    if (s < 55.0) return const Color(0xFFF57F17); // Amber/Yellow
    if (s < 80.0) return const Color(0xFFE65100); // Orange
    return const Color(0xFFC62828); // Red
  }

  @override
  Widget build(BuildContext context) {
    final double numScore = score?.score ?? 0.0;
    final Color badgeColor = _getScoreBadgeColor(numScore);

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF00897B)
              : (isRecommended
                    ? const Color(0xFF80CBC4)
                    : Colors.grey.shade300),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Name + Recommended badge + Score pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRecommended)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.thumb_up_alt_outlined,
                                size: 12,
                                color: Color(0xFF00796B),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LOWEST RECORDED INCIDENT EXPOSURE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00796B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        route.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Score Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor, width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        numScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                      Text(
                        'Risk Score',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Metrics row: Distance, Duration, Verified Incidents, Pending
            Row(
              children: [
                _buildMetric(Icons.straighten, '${route.distanceKm} km'),
                const SizedBox(width: 12),
                _buildMetric(
                  Icons.access_time,
                  '${route.durationMinutes} mins',
                ),
                const SizedBox(width: 12),
                _buildMetric(
                  Icons.verified_outlined,
                  '${score?.verifiedIncidentCount ?? 0} verified',
                  color: (score?.verifiedIncidentCount ?? 0) > 2
                      ? Colors.red.shade700
                      : const Color(0xFF37474F),
                ),
              ],
            ),
            if ((score?.pendingReportCount ?? 0) > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFF0288D1),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${score?.pendingReportCount} community report(s) pending verification',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0288D1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // Evidence summary
            Text(
              score?.evidenceSummary ?? route.summary,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onWhyThisScore,
                  icon: const Icon(Icons.help_outline, size: 15),
                  label: const Text('Why this score?'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00796B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onViewRoute,
                  icon: Icon(
                    isSelected ? Icons.check_circle : Icons.map_outlined,
                    size: 15,
                  ),
                  label: Text(isSelected ? 'Selected' : 'View route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? const Color(0xFF00796B)
                        : const Color(0xFFECEFF1),
                    foregroundColor: isSelected
                        ? Colors.white
                        : const Color(0xFF37474F),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(
    IconData icon,
    String label, {
    Color color = const Color(0xFF37474F),
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
