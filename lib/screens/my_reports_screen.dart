import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/incident_model.dart';
import '../services/incident_service.dart';
import 'report_incident_screen.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'VERIFIED':
        return const Color(0xFF2E7D32); // Green
      case 'NEEDS_REVIEW':
        return const Color(0xFFE65100); // Orange
      case 'REJECTED':
        return const Color(0xFFC62828); // Red
      case 'PENDING':
      default:
        return const Color(0xFF0288D1); // Blue
    }
  }

  Color _getStatusBgColor(String status, bool isDark) {
    final base = _getStatusColor(status);
    return base.withValues(alpha: isDark ? 0.2 : 0.12);
  }

  @override
  Widget build(BuildContext context) {
    final incidentService = Provider.of<IncidentService>(context);
    final reports = incidentService.myReports;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Community Reports',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: reports.isEmpty
          ? _buildEmptyState(context, isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length + 1,
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  return _buildHeaderNotice(isDark);
                }
                final rep = reports[idx - 1];
                return _buildReportCard(context, rep, isDark);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New Report'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReportIncidentScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderNotice(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF004D40).withValues(alpha: 0.25)
            : const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF00796B) : const Color(0xFFB2DFDB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF00897B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Submitted reports remain in PENDING status until reviewed by community auditors. They do not alter official route scores until verified.',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF80CBC4)
                    : const Color(0xFF004D40),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    IncidentModel rep,
    bool isDark,
  ) {
    final statusColor = _getStatusColor(rep.verificationStatus);
    final statusBgColor = _getStatusBgColor(rep.verificationStatus, isDark);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with ID and Status Badge
            Row(
              children: [
                Text(
                  rep.id,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF37474F),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    rep.verificationStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Category
            Row(
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  rep.formattedCategory,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF263238),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              rep.description,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF455A64),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            // Metadata row
            Row(
              children: [
                Text(
                  'Precision: ${rep.locationPrecision}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Severity: ${rep.severity}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                if (rep.isAnonymous)
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_off_outlined,
                        size: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Anonymous',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (rep.reviewNotes != null && rep.reviewNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E284A)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Moderator Note: ${rep.reviewNotes}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF616161),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: isDark ? Colors.grey.shade600 : const Color(0xFF90A4AE),
            ),
            const SizedBox(height: 16),
            Text(
              'No Reports Submitted Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF37474F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reports submitted on your device will appear here with real-time verification tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF78909C),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportIncidentScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Submit an Incident Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
