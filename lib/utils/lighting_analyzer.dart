import 'package:camera/camera.dart';
import 'dart:math';

class LightingAnalyzer {
  // Constants for lighting conditions
  static const double _darkThreshold = 50.0;
  static const double _brightThreshold = 200.0;
  
  // Returns the current lighting condition: "Too Dark", "Normal", or "Too Bright"
  Future<String> analyzeLighting(CameraImage image) async {
    try {
      final double brightness = _calculateBrightness(image);
      
      if (brightness < _darkThreshold) {
        return "Too Dark";
      } else if (brightness > _brightThreshold) {
        return "Too Bright";
      } else {
        return "Normal";
      }
    } catch (e) {
      print('Error analyzing lighting: $e');
      return "Normal"; // Default to normal if there's an error
    }
  }
  
  // Calculate the average brightness of the image
  double _calculateBrightness(CameraImage image) {
    // For YUV_420 format commonly used by cameras
    if (image.format.group == ImageFormatGroup.yuv420) {
      // Y plane contains the brightness information (luma)
      final Plane yPlane = image.planes[0];
      final int width = image.width;
      final int height = image.height;
      
      // Sample a subset of pixels for efficiency
      final int samplingRate = 16; // Sample every 16th pixel
      int totalSamples = 0;
      double totalBrightness = 0;
      
      for (int y = 0; y < height; y += samplingRate) {
        for (int x = 0; x < width; x += samplingRate) {
          final int pixel = yPlane.bytes[y * yPlane.bytesPerRow + x];
          totalBrightness += pixel;
          totalSamples++;
        }
      }
      
      return totalBrightness / max(1, totalSamples);
    } else {
      // For other formats, we could implement more complex brightness calculation
      // For now, just return a middle value
      return 125.0;
    }
  }
  
  // Get recommendation based on lighting condition
  String getLightingRecommendation(String condition) {
    switch (condition) {
      case "Too Dark":
        return "Environment is too dark. Try moving to a better lit area or turn on some lights.";
      case "Too Bright":
        return "Environment is too bright. Try reducing direct light or moving to a more shaded area.";
      case "Normal":
      default:
        return "Lighting conditions are good for face detection.";
    }
  }
}