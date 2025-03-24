// Enums for lighting conditions
enum LightingCondition {
  tooDark,
  normal,
  tooBright,
  unknown
}

class LightingAnalyzer {
  // Analyze lighting from brightness value
  // brightness: -1.0 (very dark) to 1.0 (very bright)
  static LightingCondition analyzeLighting(double brightness) {
    if (brightness < -0.3) {
      return LightingCondition.tooDark;
    } else if (brightness > 0.3) {
      return LightingCondition.tooBright;
    } else {
      return LightingCondition.normal;
    }
  }
  
  // Get a human-readable label for a lighting condition
  static String getLightingLabel(LightingCondition condition) {
    switch (condition) {
      case LightingCondition.tooDark:
        return 'Too Dark';
      case LightingCondition.normal:
        return 'Good Lighting';
      case LightingCondition.tooBright:
        return 'Too Bright';
      default:
        return 'Unknown';
    }
  }
  
  // Get an icon representation of lighting condition
  static String getLightingIcon(LightingCondition condition) {
    switch (condition) {
      case LightingCondition.tooDark:
        return '🌑';
      case LightingCondition.normal:
        return '🌤️';
      case LightingCondition.tooBright:
        return '☀️';
      default:
        return '❓';
    }
  }
  
  // Get lighting recommendation based on the condition
  static String getLightingRecommendation(LightingCondition condition) {
    switch (condition) {
      case LightingCondition.tooDark:
        return 'Try moving to a brighter area or turn on more lights.';
      case LightingCondition.tooBright:
        return 'Try reducing direct light or moving to a more shaded area.';
      case LightingCondition.normal:
        return 'Great lighting conditions!';
      default:
        return 'Unable to determine lighting conditions.';
    }
  }
}