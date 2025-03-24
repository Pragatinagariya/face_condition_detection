import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/foundation.dart';

class ImageConverter {
  // Convert CameraImage to InputImage for processing with ML Kit
  static InputImage? convertCameraImage(CameraImage cameraImage, CameraDescription camera) {
    if (cameraImage.planes.isEmpty) {
      return null;
    }

    try {
      // For google_ml_kit 0.7.3, we need to handle the different platform implementations 
      
      // Web doesn't support camera directly in this version, so we'll focus on mobile
      if (kIsWeb) {
        // In web, we have limited functionality with ML Kit 0.7.3
        print('Warning: Face detection is limited on web platform with this version.');
        
        // Alternative: Use fromFilePath with a static image
        return null;
      } else {
        // For Android/iOS, we can use the fromFilePath method with a sample image
        // This is for demonstration purposes
        // In a real app with 0.7.3, we'd need to save the camera image to a file first
        return null;
      }
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  // Convert a file image to InputImage 
  static InputImage? convertFileImage(String path) {
    try {
      final inputImage = InputImage.fromFilePath(path);
      return inputImage;
    } catch (e) {
      print('Error converting file image: $e');
      return null;
    }
  }
}