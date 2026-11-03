import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../services/emergency_service.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final locService = Provider.of<LocalizationService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          locService.t('settings_title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Language Selector Card (English / తెలుగు)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.translate_outlined,
                          color: Color(0xFF00796B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locService.t('lang_title'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      locService.t('lang_subtitle'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'en',
                            icon: const Icon(Icons.language, size: 16),
                            label: Text(
                              locService.t('lang_en'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          ButtonSegment(
                            value: 'te',
                            icon: const Icon(Icons.translate, size: 16),
                            label: Text(
                              locService.t('lang_te'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        selected: {locService.languageCode},
                        onSelectionChanged: (Set<String> newSelection) {
                          locService.setLanguage(newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Theme Mode Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.palette_outlined,
                          color: Color(0xFF00796B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locService.t('theme_title'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      locService.t('theme_subtitle'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: const Icon(Icons.light_mode, size: 16),
                            label: Text(locService.t('theme_light'), style: const TextStyle(fontSize: 11)),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: const Icon(Icons.dark_mode, size: 16),
                            label: Text(locService.t('theme_dark'), style: const TextStyle(fontSize: 11)),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: const Icon(Icons.settings_system_daydream, size: 16),
                            label: Text(locService.t('theme_system'), style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                        selected: {themeService.themeMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          themeService.setThemeMode(newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Emergency Calling Card (112 & 1091)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFEF9A9A), width: 0.8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.emergency,
                          color: Color(0xFFC62828),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locService.t('nav_emergency'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC62828),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Direct dialer shortcuts for life-threatening emergencies or immediate police assistance. Requires explicit confirmation.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade300
                            : const Color(0xFF455A64),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // 112 National Emergency
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.call, size: 16),
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  locService.t('helpline_112'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Police · Fire · Medical',
                                  style: TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62828),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              EmergencyService.promptAndLaunchHelpline(
                                context,
                                number: EmergencyService.nationalEmergencyNumber,
                                title: locService.t('helpline_112'),
                                description: 'India unified emergency service connecting to Police, Fire, and Ambulance dispatch in Telangana.',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 1091 Women Helpline
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.shield, size: 16),
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  locService.t('helpline_1091'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Women Safety Wing',
                                  style: TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              EmergencyService.promptAndLaunchHelpline(
                                context,
                                number: EmergencyService.womenHelplineNumber,
                                title: locService.t('helpline_1091'),
                                description: 'Dedicated 24x7 helpline for women in distress, stalking complaints, and SHE Teams assistance.',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Mapping & Navigation Stack Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: Color(0xFF1A237E),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mapping & Navigation Architecture',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildStackItem(
                      title: 'Interactive Map SDK',
                      description: 'Google Maps for Android (google_maps_flutter) with native Light & Dark styles',
                      icon: Icons.layers_outlined,
                    ),
                    const Divider(height: 16),
                    _buildStackItem(
                      title: 'Turn-by-Turn Navigation',
                      description: 'Seamless handoff to Google Maps app with prefilled origin and destination',
                      icon: Icons.navigation_outlined,
                    ),
                    const Divider(height: 16),
                    _buildStackItem(
                      title: 'Road Routing Engine',
                      description: 'Open Source Routing Machine (OSRM) with GeoJSON polyline decoding',
                      icon: Icons.alt_route,
                    ),
                    const Divider(height: 16),
                    _buildStackItem(
                      title: 'Geocoding & Place Search',
                      description: 'Photon by Komoot with offline Hyderabad landmark fallback',
                      icon: Icons.search,
                    ),
                    const Divider(height: 16),
                    _buildStackItem(
                      title: 'Cost Efficiency Guarantee',
                      description: 'Zero paid APIs beyond the standard Google Maps SDK (no paid Places or Routes APIs)',
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 5. Attribution & Licensing Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.copyright, color: Colors.blueGrey, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Attribution & Licensing',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Interactive mapping powered by Google Maps Android SDK.\n'
                      'Geocoding and routing data ${AppConfig.osmAttribution} under ODbL.\n\n'
                      'SURAKSHA AI is built for transparent public safety research and community innovation.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStackItem({
    required String title,
    required String description,
    required IconData icon,
    Color iconColor = const Color(0xFF00796B),
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
