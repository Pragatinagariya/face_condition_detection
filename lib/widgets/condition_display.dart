import 'package:flutter/material.dart';
import '../models/facial_condition.dart';
import '../utils/lighting_analyzer.dart';

class ConditionDisplay extends StatelessWidget {
  final FacialCondition? facialCondition;
  final String lightingCondition;
  final bool faceDetected;
  final LightingAnalyzer _lightingAnalyzer = LightingAnalyzer();
  
  ConditionDisplay({
    Key? key,
    required this.facialCondition,
    required this.lightingCondition,
    required this.faceDetected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status heading
          const Text(
            "Analysis Results",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8.0),
          
          // Face detection status
          Row(
            children: [
              Icon(
                faceDetected ? Icons.face : Icons.face_outlined,
                color: faceDetected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8.0),
              Text(
                faceDetected 
                    ? "Face detected" 
                    : "No face detected. Position your face in the frame.",
                style: TextStyle(
                  color: faceDetected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4.0),
          
          // Lighting condition
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getLightingIcon(lightingCondition),
                    color: _getLightingColor(lightingCondition),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    "Lighting: $lightingCondition",
                    style: TextStyle(
                      color: _getLightingColor(lightingCondition),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (lightingCondition != "Normal")
                Padding(
                  padding: const EdgeInsets.only(left: 32.0, top: 4.0),
                  child: Text(
                    _lightingAnalyzer.getLightingRecommendation(lightingCondition),
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: _getLightingColor(lightingCondition),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8.0),
          
          // Emotional state when face is detected
          if (faceDetected && facialCondition != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getEmotionIcon(facialCondition!.emotion),
                      size: 22,
                      color: _getEmotionColor(facialCondition!.emotion),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      "Emotional State: ${facialCondition!.emotionName}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  facialCondition!.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4.0),
                // Detailed analysis based on lighting quality
                Text(
                  facialCondition!.getDetailedAnalysis(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  "Recommendation:",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                  child: Text(
                    facialCondition!.recommendation,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            )
          else if (faceDetected)
            const Text("Analyzing facial condition..."),
        ],
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
      case EmotionType.tired:
        return Icons.nights_stay;
      case EmotionType.stressed:
        return Icons.psychology;
      case EmotionType.neutral:
      default:
        return Icons.sentiment_neutral;
    }
  }
  
  Color _getEmotionColor(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return Colors.green;
      case EmotionType.sad:
        return Colors.blue;
      case EmotionType.angry:
        return Colors.red;
      case EmotionType.surprised:
        return Colors.purple;
      case EmotionType.fearful:
        return Colors.orange;
      case EmotionType.disgusted:
        return Colors.brown;
      case EmotionType.tired:
        return Colors.indigo;
      case EmotionType.stressed:
        return Colors.deepOrange;
      case EmotionType.neutral:
      default:
        return Colors.grey;
    }
  }
}