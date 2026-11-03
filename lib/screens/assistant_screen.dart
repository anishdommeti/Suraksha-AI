import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/chat_message_model.dart';
import '../models/route_model.dart';
import '../services/assistant_service.dart';
import '../services/speech_service.dart';
import '../services/location_service.dart';
import '../services/navigation_launcher_service.dart';
import '../services/localization_service.dart';
import '../widgets/microphone_button.dart';
import 'map_screen.dart';
import 'my_reports_screen.dart';

class AssistantScreen extends StatefulWidget {
  final bool autoStartListening;
  final String? initialPrompt;

  const AssistantScreen({
    super.key,
    this.autoStartListening = false,
    this.initialPrompt,
  });

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPrompt != null) {
        _sendPrompt(widget.initialPrompt!);
      } else if (widget.autoStartListening) {
        _startListening();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendPrompt(String text) {
    if (text.trim().isEmpty) return;
    final assistant = Provider.of<AssistantService>(context, listen: false);
    final loc = Provider.of<LocationService>(context, listen: false);
    final locService = Provider.of<LocalizationService>(context, listen: false);

    _textController.clear();
    assistant.sendMessage(
      text,
      speakResponse: true,
      origin: loc.origin,
      destination: loc.destination,
      originCoords: loc.originCoordsNullable ?? loc.originCoords,
      locationService: loc,
      isTelugu: locService.isTelugu,
    );
    _scrollToBottom();
  }

  void _startListening() {
    final speech = Provider.of<SpeechService>(context, listen: false);
    speech.startListening(
      onResult: (text) {
        if (text.trim().isNotEmpty) {
          _sendPrompt(text);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final assistant = Provider.of<AssistantService>(context);
    final speech = Provider.of<SpeechService>(context);
    final locService = Provider.of<LocalizationService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF00897B),
              child: Icon(Icons.support_agent, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppConfig.assistantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    locService.isTelugu
                        ? 'యాక్షన్-సామర్థ్యం గల వాయిస్ ఏజెంట్'
                        : 'Action-Capable Voice Agent',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFB0BEC5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
          if (speech.isSpeaking)
            IconButton(
              icon: const Icon(Icons.volume_off, color: Colors.amberAccent),
              tooltip: 'Stop Speaking',
              onPressed: speech.stopSpeaking,
            ),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            tooltip: 'View Map',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapScreen(
                    initialSelectedRouteId: assistant.selectedRouteId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Speech recognition active banner
          if (speech.isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.redAccent.shade100,
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      speech.recognizedWords.isEmpty
                          ? 'Listening... speak your request'
                          : speech.recognizedWords,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB71C1C),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.stop_circle_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: speech.stopListening,
                  ),
                ],
              ),
            ),

          // Speech error banner
          if (speech.errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      speech.errorMessage,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.orange,
                    ),
                    onPressed: speech.clearError,
                  ),
                ],
              ),
            ),

          // Conversation Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: assistant.messages.length,
              itemBuilder: (context, idx) {
                final msg = assistant.messages[idx];
                return _buildMessageBubble(msg, speech, isDark);
              },
            ),
          ),

          // Processing Indicator
          if (assistant.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00796B),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Suraksha is executing backend tools...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF00796B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Voice Control & Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141C33) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF223055)
                      : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick suggestion chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _buildQuickChip(
                          locService.isTelugu ? 'నా ప్రస్తుత స్థానాన్ని ఉపయోగించు' : 'Use my current location',
                          isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickChip(
                          locService.isTelugu ? 'శంషాబాద్ ఎయిర్‌పోర్ట్ తీసుకెళ్లు' : 'Take me to Rajiv Gandhi International Airport',
                          isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickChip(
                          locService.isTelugu ? 'ఉప్పల్ స్టేడియం' : 'Navigate to Uppal Stadium',
                          isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickChip(
                          locService.isTelugu ? 'మార్గాలు పోల్చండి' : 'Compare candidate routes',
                          isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickChip(
                          locService.isTelugu ? 'రూట్ ఎందుకు సిఫార్సు చేయబడింది?' : 'Why recommend this route?',
                          isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickChip(
                          locService.isTelugu ? 'మహిళల భద్రతా సంఘటనలు' : "Women's safety incidents",
                          isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickChip(
                          locService.isTelugu ? 'సమస్యను నివేదించండి' : 'Report a hazard',
                          isDark,
                        ),
                      ],
                    ),
                  ),

                  // Text input row with large mic button
                  Row(
                    children: [
                      // Large Microphone button
                      MicrophoneButton(
                        state: speech.state,
                        size: 48,
                        onTap: _startListening,
                        onStopSpeaking: speech.stopSpeaking,
                      ),
                      const SizedBox(width: 10),

                      // Text Field
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                          decoration: InputDecoration(
                            hintText: locService.isTelugu ? 'సురక్షను అడగండి లేదా మాట్లాడండి...' : 'Ask Suraksha or speak...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF18223E)
                                : const Color(0xFFF0F4F8),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: _sendPrompt,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Send Button
                      IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF00897B),
                        ),
                        onPressed: () => _sendPrompt(_textController.text),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, bool isDark) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF80CBC4) : const Color(0xFF004D40),
        ),
      ),
      backgroundColor: isDark
          ? const Color(0xFF18223E)
          : const Color(0xFFE0F2F1),
      side: BorderSide(
        color: isDark ? const Color(0xFF00796B) : const Color(0xFF80CBC4),
        width: 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onPressed: () => _sendPrompt(label),
    );
  }

  Widget _buildCleanFormattedText(String text, bool isUser, bool isDark) {
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // 1. Header (### or ##)
      if (trimmed.startsWith('### ') || trimmed.startsWith('## ')) {
        final headerText = trimmed
            .replaceFirst(RegExp(r'^#{2,3}\s*'), '')
            .replaceAll('**', '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isUser
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFF4DB6AC)
                          : const Color(0xFF1A237E)),
              ),
            ),
          ),
        );
        continue;
      }

      // 2. Bullet point (• or - or *)
      final bool isBullet =
          trimmed.startsWith('• ') ||
          trimmed.startsWith('- ') ||
          (trimmed.startsWith('* ') && !trimmed.startsWith('**'));
      final content = isBullet ? trimmed.substring(2) : trimmed;

      // Parse bold segments (**bold**) cleanly
      final spans = <TextSpan>[];
      final parts = content.split('**');
      final textColor = isUser
          ? Colors.white
          : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF263238));

      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isEmpty) continue;
        final bool isBold = (i % 2 == 1);
        spans.add(
          TextSpan(
            text: parts[i],
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        );
      }

      if (isBullet) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 6),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUser ? Colors.white70 : const Color(0xFF00796B),
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: spans,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: RichText(
              text: TextSpan(
                children: spans,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRouteComparisonCards(
    List<RouteComparisonCardData> cards,
    bool isDark,
  ) {
    final assistant = Provider.of<AssistantService>(context, listen: false);
    final locService = Provider.of<LocalizationService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          locService.isTelugu
              ? 'రూట్ల పోలిక & భద్రతా వివరాలు'
              : 'Route Comparison & Safety Trade-offs',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF4DB6AC) : const Color(0xFF1A237E),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        ...cards.map((card) {
          final isRec = card.isRecommended;
          final isSelected = assistant.selectedRouteId == card.routeId;

          Color scoreColor = const Color(0xFF2E7D32); // Green
          if (card.score >= 50) {
            scoreColor = const Color(0xFFC62828); // Red
          } else if (card.score >= 30) {
            scoreColor = const Color(0xFFE65100); // Orange
          }

          final cardBg = isRec
              ? (isDark ? const Color(0xFF132B20) : const Color(0xFFF1F8E9))
              : (isDark ? const Color(0xFF18223E) : Colors.white);
          final cardBorderColor = isSelected
              ? const Color(0xFF00796B)
              : (isRec
                    ? (isDark
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFA5D6A7))
                    : (isDark
                          ? const Color(0xFF223055)
                          : const Color(0xFFCFD8DC)));

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cardBorderColor,
                width: isSelected ? 2.0 : (isRec ? 1.5 : 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Name & Recommended Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        card.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF263238),
                        ),
                      ),
                    ),
                    if (isRec) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 10),
                            SizedBox(width: 3),
                            Text(
                              'RECOMMENDED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Metrics row: Distance, Duration & Score
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${card.distanceKm.toStringAsFixed(1)} km • ${card.durationMinutes} mins',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF37474F),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: scoreColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Score: ${card.score.toStringAsFixed(1)}/100',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Recommendation reason
                if (card.recommendationReason.isNotEmpty) ...[
                  Text(
                    card.recommendationReason,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF546E7A),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Incidents summary chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${card.verifiedCount} verified audit record${card.verifiedCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...card.topHazards.map(
                      (h) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          h,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Action Buttons: View on Map & Navigate in Google Maps
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.map_outlined, size: 14),
                        label: Text(
                          isSelected
                              ? (locService.isTelugu ? 'మ్యాప్‌లో ఉంది' : 'On Map')
                              : (locService.isTelugu ? 'మ్యాప్‌లో చూడు' : 'View on Map'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? const Color(0xFF00796B)
                              : const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          assistant.selectRoute(card.routeId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapScreen(
                                initialSelectedRouteId: card.routeId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.navigation_rounded,
                          size: 14,
                          color: Color(0xFF00796B),
                        ),
                        label: Text(
                          locService.isTelugu ? 'గూగుల్ మ్యాప్స్' : 'Google Maps',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00796B),
                          side: const BorderSide(
                            color: Color(0xFF00796B),
                            width: 1.2,
                          ),
                          backgroundColor: const Color(0xFFE0F2F1),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          RouteModel? matchingRoute;
                          try {
                            matchingRoute = assistant.activeRoutes.firstWhere(
                              (r) => r.routeId == card.routeId,
                            );
                          } catch (_) {}

                          final loc = Provider.of<LocationService>(
                            context,
                            listen: false,
                          );
                          final dest =
                              matchingRoute != null &&
                                  matchingRoute.geometry.isNotEmpty
                              ? matchingRoute.geometry.last
                              : (loc.currentGpsCoords ??
                                    const LatLng(17.3616, 78.4947));
                          final orig =
                              matchingRoute != null &&
                                  matchingRoute.geometry.isNotEmpty
                              ? matchingRoute.geometry.first
                              : loc.currentGpsCoords;

                          NavigationLauncherService.launchGoogleMapsNavigation(
                            context: context,
                            destination: dest,
                            origin: orig,
                            isOriginCurrentLocation: loc.usingCurrentLocation,
                            destinationName: card.name,
                            originName: loc.origin,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMessageBubble(
    ChatMessageModel msg,
    SpeechService speech,
    bool isDark,
  ) {
    final locService = Provider.of<LocalizationService>(context);
    final isUser = msg.isUser;
    final bubbleBg = isUser
        ? const Color(0xFF1A237E)
        : (isDark ? const Color(0xFF141C33) : Colors.white);
    final bubbleBorder = isUser
        ? null
        : Border.all(
            color: isDark ? const Color(0xFF223055) : Colors.grey.shade200,
          );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: bubbleBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender name & replay audio button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUser ? Icons.person : Icons.shield_outlined,
                      size: 13,
                      color: isUser ? Colors.white70 : const Color(0xFF00897B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUser ? (locService.isTelugu ? 'మీరు' : 'You') : AppConfig.assistantName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUser ? Colors.white70 : const Color(0xFF00897B),
                      ),
                    ),
                  ],
                ),
                if (!isUser && msg.spokenText.isNotEmpty)
                  GestureDetector(
                    onTap: () => speech.speak(msg.spokenText),
                    child: const Icon(
                      Icons.volume_up_outlined,
                      size: 16,
                      color: Color(0xFF00796B),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Clean formatted message text without raw markdown symbols
            _buildCleanFormattedText(msg.text, isUser, isDark),

            // Route Comparison Cards
            if (msg.comparisonCards != null && msg.comparisonCards!.isNotEmpty)
              _buildRouteComparisonCards(msg.comparisonCards!, isDark),

            // Confirmation Prompt Action Buttons
            if (msg.isConfirmationPrompt) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 14),
                      label: const Text(
                        'Confirm Submission',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _sendPrompt('Confirm submission'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                    ),
                    onPressed: () => _sendPrompt('Cancel'),
                    child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],

            // Backend Tools Called Badge
            if (msg.toolsCalled.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: msg.toolsCalled.map((tool) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt,
                          size: 12,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Tool: ${tool.toolName}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // Suggested follow-up prompt chips
            if (msg.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: msg.suggestedActions.map((action) {
                  return ActionChip(
                    label: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00695C),
                      ),
                    ),
                    backgroundColor: const Color(0xFFE0F2F1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    onPressed: () => _sendPrompt(action),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
