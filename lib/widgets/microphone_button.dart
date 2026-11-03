import 'package:flutter/material.dart';

import '../services/speech_service.dart';

class MicrophoneButton extends StatelessWidget {
  final VoiceState state;
  final VoidCallback onTap;
  final VoidCallback? onStopSpeaking;
  final double size;

  const MicrophoneButton({
    super.key,
    required this.state,
    required this.onTap,
    this.onStopSpeaking,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    Color buttonColor;
    IconData iconData;
    String statusLabel;

    switch (state) {
      case VoiceState.listening:
        buttonColor = Colors.redAccent;
        iconData = Icons.mic;
        statusLabel = 'Listening...';
        break;
      case VoiceState.processing:
        buttonColor = Colors.amber.shade700;
        iconData = Icons.hourglass_top;
        statusLabel = 'Processing...';
        break;
      case VoiceState.speaking:
        buttonColor = const Color(0xFF00796B); // Deep teal
        iconData = Icons.volume_up;
        statusLabel = 'Speaking (tap to stop)';
        break;
      case VoiceState.error:
        buttonColor = Colors.orange;
        iconData = Icons.mic_off;
        statusLabel = 'Tap to retry mic';
        break;
      case VoiceState.idle:
        buttonColor = const Color(0xFF00897B); // Teal 600
        iconData = Icons.mic;
        statusLabel = 'Talk to Suraksha';
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (state == VoiceState.speaking && onStopSpeaking != null) {
              onStopSpeaking!();
            } else {
              onTap();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.35),
                  blurRadius: state == VoiceState.listening ? 18 : 8,
                  spreadRadius: state == VoiceState.listening ? 4 : 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: state == VoiceState.processing
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(iconData, color: Colors.white, size: size * 0.5),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          statusLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: state == VoiceState.listening
                ? Colors.redAccent
                : const Color(0xFF37474F),
          ),
        ),
      ],
    );
  }
}
