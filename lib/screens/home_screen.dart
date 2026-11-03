import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../services/location_service.dart';
import '../services/speech_service.dart';
import '../services/incident_service.dart';
import '../widgets/microphone_button.dart';
import 'map_screen.dart';
import 'assistant_screen.dart';
import 'report_incident_screen.dart';
import 'score_explanation_screen.dart';
import 'my_reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final loc = Provider.of<LocationService>(context, listen: false);
    _originController.text = loc.origin;
    _destController.text = loc.destination;
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    super.dispose();
  }

  void _onCompareRoutes() {
    final loc = Provider.of<LocationService>(context, listen: false);
    loc.setOrigin(_originController.text);
    loc.setDestination(_destController.text);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  void _onTalkToSuraksha() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssistantScreen(autoStartListening: true),
      ),
    );
  }

  void _onExamplePromptSelected(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssistantScreen(initialPrompt: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocationService>(context);
    final speech = Provider.of<SpeechService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E), // Deep navy
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF4DB6AC),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppConfig.appName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Text(
              AppConfig.tagline,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFFB0BEC5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined, color: Colors.white),
            tooltip: 'My Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyReportsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'About Risk Scores & Data',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScoreExplanationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.report_problem_outlined,
              color: Colors.white,
            ),
            tooltip: 'Report Incident',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportIncidentScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // India Emergency Quick Dial Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emergency, color: Color(0xFFC62828), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY: Call 112 (Police) | 1091 (Women)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB71C1C),
                          ),
                        ),
                        Text(
                          'SURAKSHA AI is not an emergency dispatch service.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Dataset Provenance indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'HYDERABAD DATASET: Telangana Police, SHE Teams & OpenCity Data',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route Planning Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Plan Your Safe Route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Origin input
                    TextField(
                      controller: _originController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.trip_origin,
                          color: Color(0xFF00897B),
                          size: 18,
                        ),
                        labelText: 'Origin',
                        hintText: 'e.g. Matrusri Engineering College',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Current location shortcut button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          loc.useCurrentLocation();
                          _originController.text = loc.origin;
                        },
                        icon: const Icon(
                          Icons.my_location,
                          size: 14,
                          color: Color(0xFF00796B),
                        ),
                        label: const Text(
                          'Use Demo College Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00796B),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Destination input
                    TextField(
                      controller: _destController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.place,
                          color: Color(0xFFD32F2F),
                          size: 18,
                        ),
                        labelText: 'Destination',
                        hintText: 'e.g. Saidabad Metro Station',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Compare Routes Button
                    ElevatedButton.icon(
                      onPressed: _onCompareRoutes,
                      icon: const Icon(Icons.alt_route, size: 20),
                      label: const Text('Compare Routes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Incident Reporting & My Reports Quick Action Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportIncidentScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add_location_alt_outlined,
                      size: 18,
                      color: Color(0xFFE65100),
                    ),
                    label: const Text(
                      'Report Hazard',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFFFB74D)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: const Color(0xFFFFF8E1),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyReportsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.assignment_outlined,
                      size: 18,
                      color: Color(0xFF0288D1),
                    ),
                    label: Text(
                      'My Reports (${Provider.of<IncidentService>(context).myReports.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0288D1),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF81D4FA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: const Color(0xFFE1F5FE),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Prominent Voice Assistant Microphone Section
            Card(
              elevation: 1,
              color: const Color(0xFFE0F2F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFB2DFDB), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Voice Assistant: Suraksha',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Speak naturally to find routes, compare safety scores, or report incidents.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF00695C)),
                    ),
                    const SizedBox(height: 16),
                    MicrophoneButton(
                      state: speech.state,
                      size: 68,
                      onTap: _onTalkToSuraksha,
                      onStopSpeaking: speech.stopSpeaking,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Example Prompts
            const Text(
              'Try Asking Suraksha:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF37474F),
              ),
            ),
            const SizedBox(height: 8),
            _buildExamplePromptChip(
              'Which route has fewer recorded incidents?',
            ),
            _buildExamplePromptChip(
              'Compare routes from my college to the nearest metro station.',
            ),
            _buildExamplePromptChip('Why are you recommending this route?'),
            _buildExamplePromptChip(
              "Show women's safety incidents near this route.",
            ),
            _buildExamplePromptChip(
              'Explain where this incident data came from.',
            ),
            _buildExamplePromptChip(
              'Check the status of my submitted incident reports.',
            ),
            _buildExamplePromptChip(
              'Report poor street lighting near colony entrance.',
            ),

            const SizedBox(height: 24),

            // Accessible Safety Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCFD8DC)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield, size: 16, color: Color(0xFF546E7A)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SAFETY DISCLAIMER: Heuristic scores reflect recorded incident information in the selected period. SURAKSHA AI cannot guarantee personal safety or predict harm. Always remain alert.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF546E7A),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplePromptChip(String prompt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => _onExamplePromptSelected(prompt),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: Color(0xFF00796B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prompt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF263238),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
