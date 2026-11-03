import 'package:flutter/material.dart';

class ScoreExplanationScreen extends StatelessWidget {
  const ScoreExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1326)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'About Risk Scores & Methodology',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0A2B24)
                    : const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF004D40)
                      : const Color(0xFFB2DFDB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transparent Heuristic Safety Scoring',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF80CBC4)
                          : const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'SURAKSHA AI computes deterministic, evidence-backed scores based strictly on recorded incident data. The LLM does NOT invent or guess risk scores.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFB2DFDB)
                          : const Color(0xFF00695C),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              context: context,
              title: '1. What Does the Score Measure?',
              content:
                  'The score (0–100) measures recorded incident exposure along a 200-meter corridor surrounding the route geometry during the selected reporting period (last 90 days).\n\n'
                  '• 0–25: Low Recorded Exposure (few or minor recorded incidents)\n'
                  '• 26–55: Moderate Recorded Exposure (recorded lighting issues or occasional reports)\n'
                  '• 56–80: Elevated Recorded Exposure (multiple infrastructure defects or isolated stretches)\n'
                  '• 81–100: High Recorded Exposure (frequent recorded harassment or safety notices)',
            ),

            _buildSection(
              context: context,
              title: '2. The Mathematical Heuristic Formula',
              content:
                  'To avoid penalizing longer routes unfairly, the backend normalizes by distance:\n\n'
                  'Exposure Density = (Sum of Category Weights for Verified Incidents) / Max(Distance in km, 0.5 km)\n\n'
                  'Category Weights:\n'
                  '• Harassment / Assault: 3.0\n'
                  '• Poor Street Lighting: 1.5\n'
                  '• Deserted / Isolated Stretch: 1.5\n'
                  '• Road Obstruction / Excavation: 1.0\n'
                  '• Suspicious Activity: 1.5\n\n'
                  'Normalized Score = min(100.0, round(10.0 + (Exposure Density × 22.0), 1))',
            ),

            _buildSection(
              context: context,
              title: '3. Verification Lifecycle & Score Isolation',
              content:
                  '• VERIFIED Incidents: Confirmed through police records, municipal audits, and civic works notices. Only verified incidents contribute to the route risk score.\n\n'
                  '• PENDING Reports: Submitted by community members. These are highlighted in blue on the map with warning indicators, but they strictly DO NOT alter verified route scores until audited.\n\n'
                  '• NEEDS_REVIEW: Flagged when duplicate submissions or community confirmations reach review threshold.\n\n'
                  '• REJECTED Reports: Filtered out and never contribute to scoring.',
            ),

            _buildSection(
              context: context,
              title: '4. Data Provenance & Precision Transparency',
              content:
                  '• Official Sources: Telangana Police, Hyderabad Traffic Police, SHE Teams Annual Reports, OpenCity Urban Data Portal, and GHMC street lighting audits.\n\n'
                  '• Location Precision: Records are tagged EXACT, APPROXIMATE, or AREA_ONLY. Broad police-station or ward aggregates (AREA_ONLY) are never placed as misleading street-level pins.\n\n'
                  '• Synthetic Isolation: Demonstration scenario records are strictly tagged is_simulated: true in demo_incidents.json and clearly distinguished from real public safety data.',
            ),

            _buildSection(
              context: context,
              title: '5. Critical Safety Limitations & Emergency Protocol',
              content:
                  '⚠️ SURAKSHA AI is an informational assistant, NOT an emergency dispatch service.\n'
                  '⚠️ In an immediate emergency, dial 112 (Police) or 1091 (Women Helpline).\n'
                  '⚠️ A lower score DOES NOT guarantee that a route is safe.\n'
                  '⚠️ The absence of recorded incidents DOES NOT imply an area is hazard-free; incidents may be under-reported.\n'
                  '⚠️ The score does NOT predict the mathematical probability of personal harm.',
              isAlert: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String content,
    bool isAlert = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color borderColor;
    Color titleColor;
    Color contentColor;

    if (isAlert) {
      bgColor = isDark ? const Color(0xFF331E05) : const Color(0xFFFFF3E0);
      borderColor = isDark ? const Color(0xFFB26A00) : const Color(0xFFFFB74D);
      titleColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
      contentColor = isDark ? const Color(0xFFFFCC80) : const Color(0xFFBF360C);
    } else {
      bgColor = isDark ? const Color(0xFF141C33) : Colors.white;
      borderColor = isDark ? const Color(0xFF232D4D) : Colors.grey.shade300;
      titleColor = isDark ? Colors.white : const Color(0xFF263238);
      contentColor = isDark ? Colors.grey.shade300 : const Color(0xFF455A64);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 12, color: contentColor, height: 1.4),
          ),
        ],
      ),
    );
  }
}
