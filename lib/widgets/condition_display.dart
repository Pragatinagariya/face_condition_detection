import 'package:flutter/material.dart';
import 'package:face_condition_detector/models/facial_condition.dart';
import 'package:face_condition_detector/utils/lighting_analyzer.dart';

class ConditionDisplay extends StatelessWidget {
  final FacialCondition? facialCondition;
  final String lightingCondition;
  final bool faceDetected;
  
  const ConditionDisplay({
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
          
          const SizedBox(height: 8.0),
          
          // Emotional state when face is detected
          if (faceDetected && facialCondition != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Emotional State: ${facialCondition!.emotionName}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  facialCondition!.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4.0),
                Text(
                  "Recommendation: ${facialCondition!.recommendation}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
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
}