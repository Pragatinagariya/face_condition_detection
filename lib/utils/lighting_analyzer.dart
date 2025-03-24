import 'package:camera/camera.dart';
import 'dart:math';

class LightingAnalyzer {
  // Constants for lighting thresholds
  static const double _dimThreshold = 70.0;
  static const double _brightThreshold = 200.0;
  
  // Analyze the lighting conditions from a camera image
  static Map<String, dynamic> analyzeLighting(CameraImage image) {
    try {
      // Calculate the average brightness
      final brightness = _calculateAverageBrightness(image);
      
      // Determine lighting condition
      String condition;
      double intensity;
      
      if (brightness < _dimThreshold) {
        condition = "Too Dim";
        // Normalize intensity to range [-1.0, 0.0]
        intensity = -1.0 + (brightness / _dimThreshold);
      } else if (brightness > _brightThreshold) {
        condition = "Too Bright";
        // Normalize intensity to range [0.0, 1.0]
        intensity = (brightness - _brightThreshold) / (255.0 - _brightThreshold);
        intensity = min(intensity, 1.0);
      } else {
        condition = "Normal";
        // Normalize to range [-0.3, 0.3] for normal conditions
        intensity = (2.0 * (brightness - _dimThreshold) / (_brightThreshold - _dimThreshold)) - 1.0;
        intensity *= 0.3;
      }
      
      return {
        "condition": condition,
        "intensity": intensity,
        "brightness": brightness,
      };
    } catch (e) {
      print('Error analyzing lighting: $e');
      return {
        "condition": "Unknown",
        "intensity": 0.0,
        "brightness": 0.0,
      };
    }
  }

  // Calculate the average brightness of the image
  static double _calculateAverageBrightness(CameraImage image) {
    // Different calculation based on the image format
    if (image.format.group == ImageFormatGroup.yuv420) {
      // For YUV format, the Y plane represents the brightness
      final yPlane = image.planes[0];
      final bytes = yPlane.bytes;
      
      // Sample the brightness values
      double total = 0;
      final sampleSize = min(1000, bytes.length);
      final step = bytes.length ~/ sampleSize;
      
      for (int i = 0; i < bytes.length; i += step) {
        total += bytes[i];
      }
      
      return total / (bytes.length ~/ step);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      // For BGRA format, calculate from RGB values
      final plane = image.planes[0];
      final bytes = plane.bytes;
      
      double total = 0;
      int count = 0;
      
      // Sample the pixels
      final sampleSize = min(1000, bytes.length ~/ 4);
      final step = (bytes.length ~/ 4) ~/ sampleSize;
      
      for (int i = 0; i < bytes.length; i += step * 4) {
        if (i + 2 < bytes.length) {
          // Calculate brightness from RGB
          final r = bytes[i + 2];
          final g = bytes[i + 1];
          final b = bytes[i];
          
          // Weighted brightness formula
          final brightness = (0.299 * r + 0.587 * g + 0.114 * b);
          total += brightness;
          count++;
        }
      }
      
      return count > 0 ? total / count : 0;
    }
    
    return 0;
  }
}
