import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// EmergencyService
/// Manages explicit user-initiated emergency helpline connections to
/// India's integrated 112 emergency response and 1091 women helpline.
/// Never initiates silent, automatic calls. Always opens the native dialer.
class EmergencyService {
  static const String nationalEmergencyNumber = '112';
  static const String womenHelplineNumber = '1091';

  /// Shows confirmation dialog and opens native phone dialer for the specified helpline
  static Future<void> promptAndLaunchHelpline(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark ? const Color(0xFF141C33) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.emergency, color: Color(0xFFC62828), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFFB71C1C),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.grey.shade300
                      : const Color(0xFF37474F),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFC62828).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_in_talk,
                      color: Color(0xFFC62828),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dial: $number',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will open your phone dialer. No call is placed automatically.',
                style: TextStyle(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.call, size: 16),
              label: Text('Open Dialer ($number)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await launchDialer(context, number);
    }
  }

  /// Opens the device dialer with the requested number prefilled
  static Future<bool> launchDialer(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to open phone dialer for $number on this device.',
              ),
              backgroundColor: const Color(0xFFC62828),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialer error: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
      return false;
    }
  }
}
