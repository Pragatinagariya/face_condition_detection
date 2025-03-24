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
  
  FacialCondition({
    required this.emotion,
    required this.confidence,
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
        return 'Keep enjoying your day!';
      case EmotionType.sad:
        return 'Take a moment for self-care or talk to someone.';
      case EmotionType.angry:
        return 'Take a few deep breaths to calm down.';
      case EmotionType.surprised:
        return 'Take a moment to process what surprised you.';
      case EmotionType.fearful:
        return 'Practice some calming breathing exercises.';
      case EmotionType.disgusted:
        return 'Try to move away from what\'s causing your discomfort.';
      case EmotionType.neutral:
        return 'You\'re balanced. Continue your activities.';
      case EmotionType.tired:
        return 'Consider taking a short break or nap if possible.';
      case EmotionType.stressed:
        return 'Try some stress-reduction techniques like deep breathing.';
      default:
        return 'Unable to provide a recommendation.';
    }
  }
}