import 'package:flutter/material.dart';
import 'package:face_condition_detector/models/facial_condition.dart';

class AnalysisOverlay extends StatelessWidget {
  final FacialCondition? condition;
  final String lightingCondition;
  
  const AnalysisOverlay({
    Key? key,
    required this.condition,
    required this.lightingCondition, required face, required Size previewSize, required Size screenSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Lighting indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getLightingIcon(lightingCondition),
                  color: _getLightingColor(lightingCondition),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  lightingCondition,
                  style: TextStyle(
                    color: _getLightingColor(lightingCondition),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Emotion indicator (if available)
            if (condition != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getEmotionIcon(condition?.emotion ?? EmotionType.neutral),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    condition?.emotionName ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  IconData _getLightingIcon(String condition) {
    switch (condition) {
      case "Too Dark":
        return Icons.nightlight_round;
      case "Too Bright":
        return Icons.wb_sunny;
      case "Normal":
      default:
        return Icons.wb_auto;
    }
  }
  
  Color _getLightingColor(String condition) {
    switch (condition) {
      case "Too Dark":
      case "Too Bright":
        return Colors.orange;
      case "Normal":
      default:
        return Colors.green;
    }
  }
  
  IconData _getEmotionIcon(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return Icons.sentiment_very_satisfied;
      case EmotionType.sad:
        return Icons.sentiment_very_dissatisfied;
      case EmotionType.angry:
        return Icons.sentiment_very_dissatisfied;
      case EmotionType.surprised:
        return Icons.sentiment_satisfied_alt;
      case EmotionType.fearful:
        return Icons.sentiment_dissatisfied;
      case EmotionType.disgusted:
        return Icons.sick;
      case EmotionType.neutral:
        return Icons.sentiment_neutral;
      case EmotionType.tired:
        return Icons.nights_stay;
      case EmotionType.stressed:
        return Icons.psychology;
      default:
        return Icons.face;
    }
  }
}