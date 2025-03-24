enum EmotionType {
  happy,
  sad,
  angry,
  surprised,
  fearful,
  disgusted,
  neutral,
  tired,
  stressed
}

class FacialCondition {
  final EmotionType emotion;
  final double confidence;
  final double lightingQuality;
  
  FacialCondition({
    required this.emotion,
    required this.confidence,
    this.lightingQuality = 0.9, // Default to good lighting
  });
  
  String get emotionName {
    switch (emotion) {
      case EmotionType.happy:
        return 'Happy';
      case EmotionType.sad:
        return 'Sad';
      case EmotionType.angry:
        return 'Angry';
      case EmotionType.surprised:
        return 'Surprised';
      case EmotionType.fearful:
        return 'Fearful';
      case EmotionType.disgusted:
        return 'Disgusted';
      case EmotionType.neutral:
        return 'Neutral';
      case EmotionType.tired:
        return 'Tired';
      case EmotionType.stressed:
        return 'Stressed';
      default:
        return 'Unknown';
    }
  }
  
  String get description {
    switch (emotion) {
      case EmotionType.happy:
        return 'You seem happy and relaxed.';
      case EmotionType.sad:
        return 'You appear to be sad or down.';
      case EmotionType.angry:
        return 'You seem angry or frustrated.';
      case EmotionType.surprised:
        return 'You appear to be surprised.';
      case EmotionType.fearful:
        return 'You seem fearful or anxious.';
      case EmotionType.disgusted:
        return 'You appear to be disgusted.';
      case EmotionType.neutral:
        return 'Your expression is neutral.';
      case EmotionType.tired:
        return 'You seem tired. Consider taking a rest.';
      case EmotionType.stressed:
        return 'You appear stressed. Try to relax.';
      default:
        return 'Unable to determine your condition.';
    }
  }
  
  String get recommendation {
    switch (emotion) {
      case EmotionType.happy:
        return 'Keep enjoying your day! Your positive mood is great for productivity.';
      case EmotionType.sad:
        return 'Take a moment for self-care or talk to someone. A short walk might help improve your mood.';
      case EmotionType.angry:
        return 'Take a few deep breaths to calm down. Consider a brief break from screens.';
      case EmotionType.surprised:
        return 'Take a moment to process what surprised you. Return to normal activities when ready.';
      case EmotionType.fearful:
        return 'Practice some calming breathing exercises. Try counting to 10 slowly while breathing deeply.';
      case EmotionType.disgusted:
        return 'Try to move away from what\'s causing your discomfort. A change of environment might help.';
      case EmotionType.neutral:
        return 'You\'re balanced. Continue your activities as normal.';
      case EmotionType.tired:
        return 'You appear fatigued. Consider taking a 15-minute break, a short walk, or having a healthy snack to boost your energy.';
      case EmotionType.stressed:
        return 'Your stress levels seem elevated. Try a 2-minute breathing exercise or step away from your current task briefly.';
      default:
        return 'Unable to provide a recommendation.';
    }
  }
  
  // Get a more detailed analysis based on confidence level
  String getDetailedAnalysis([double? externalLightingQuality]) {
    // Use provided lighting quality or the internal one
    final double effectiveLightingQuality = externalLightingQuality ?? lightingQuality;
    
    // Adjust analysis based on lighting quality
    String lightingNote = "";
    if (effectiveLightingQuality < 0.6) {
      lightingNote = " Note: Detection accuracy may be affected by current lighting conditions.";
    }
    
    // Base analysis on emotion and confidence
    if (confidence > 0.8) {
      switch (emotion) {
        case EmotionType.tired:
          return "High confidence that you're experiencing fatigue. Physical signs like drooping eyelids and reduced facial movement detected.$lightingNote";
        case EmotionType.stressed:
          return "Strong indicators of stress detected in your facial expressions, particularly around your eyes and mouth.$lightingNote";
        default:
          return "High confidence in the detected emotional state.$lightingNote";
      }
    } else if (confidence > 0.5) {
      return "Moderate confidence in the detected emotional state.$lightingNote";
    } else {
      return "Low confidence in the detected emotional state. Try improving lighting or positioning your face more clearly in frame.$lightingNote";
    }
  }
}