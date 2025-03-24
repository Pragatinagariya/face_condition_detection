import 'package:image/image.dart' as img;

enum LightingCondition {
  tooDark,
  normal,
  tooBright
}

class LightingAnalyzer {
  static const double _DARK_THRESHOLD = 0.25;  // Below this is considered too dark
  static const double _BRIGHT_THRESHOLD = 0.75; // Above this is considered too bright
  
  LightingCondition analyzeLighting(img.Image image) {
    // Calculate average brightness
    int totalBrightness = 0;
    int pixelCount = 0;
    
    // Sample pixels (for performance, we can sample rather than process every pixel)
    int sampleStride = (image.width * image.height) > 1000000 ? 5 : 2;
    
    for (int y = 0; y < image.height; y += sampleStride) {
      for (int x = 0; x < image.width; x += sampleStride) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        // Weighted brightness calculation (human eye perceives green as brighter)
        final brightness = (0.299 * r + 0.587 * g + 0.114 * b).round();
        totalBrightness += brightness;
        pixelCount++;
      }
    }
    
    // Calculate average brightness (0-255)
    final averageBrightness = totalBrightness / (pixelCount * 255);
    
    // Analyze brightness level
    if (averageBrightness < _DARK_THRESHOLD) {
      return LightingCondition.tooDark;
    } else if (averageBrightness > _BRIGHT_THRESHOLD) {
      return LightingCondition.tooBright;
    } else {
      return LightingCondition.normal;
    }
  }
  
  // Get recommended camera exposure settings based on lighting condition
  Map<String, dynamic> getExposureSettings(LightingCondition condition) {
    switch (condition) {
      case LightingCondition.tooDark:
        return {
          'exposureCompensation': 1.0, // Increase exposure
          'sensitivity': 800,          // Increase ISO
        };
      case LightingCondition.tooBright:
        return {
          'exposureCompensation': -1.0, // Decrease exposure
          'sensitivity': 100,            // Lower ISO
        };
      case LightingCondition.normal:
      default:
        return {
          'exposureCompensation': 0.0, // Normal exposure
          'sensitivity': 400,          // Normal ISO
        };
    }
  }
}
