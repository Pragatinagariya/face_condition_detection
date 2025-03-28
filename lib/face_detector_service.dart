import 'dart:math';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;

import 'models/face_data.dart';
import 'emotion_analyzer.dart';
import 'lighting_analyzer.dart';

class FaceDetectorService {
  FaceDetector? _faceDetector;
  EmotionAnalyzer? _emotionAnalyzer;
  LightingAnalyzer _lightingAnalyzer = LightingAnalyzer();
  bool _isInitialized = false;
  
  InputImage? get inputImage => null;
  
  Future<void> initialize() async {
    // Initialize face detector with options
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true, 
      enableTracking: true,
      minFaceSize: 0.15,
    );
    
    _faceDetector = GoogleMlKit.vision.faceDetector(options);
    
    // Initialize emotion analyzer
    _emotionAnalyzer = await EmotionAnalyzer.create();
    
    _isInitialized = true;
  }
  
  Future<FaceData?> processImage(
    CameraImage image,
    int sensorOrientation,
    bool isFrontCamera,
  ) async {
    if (!_isInitialized || _faceDetector == null) {
      return null;
    }
    
    try {
      // Convert camera image to InputImage format
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      
      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      // Calculate rotation
      int rotation = sensorOrientation;
      if (Platform.isAndroid) {
        rotation = isFrontCamera ? (sensorOrientation + 90) % 360 : (sensorOrientation + 270) % 360;
      } else if (Platform.isIOS) {
        rotation = isFrontCamera ? (sensorOrientation + 90) % 360 : (sensorOrientation + 90) % 360;
      } else {
        // For web or other platforms
        rotation = 0;
      }
      
      // Convert rotation to InputImageRotation
      final InputImageRotation imageRotation = rotation == 0
          ? InputImageRotation.rotation0deg
          : rotation == 90
              ? InputImageRotation.rotation0deg
              : rotation == 180
                  ? InputImageRotation.rotation180deg
                  : InputImageRotation.rotation270deg;
      
      // Create InputImage
         
      // Detect faces
      final List<Face> faces = await _faceDetector!.processImage(inputImage!);
      
      // If no face is detected, return null
      if (faces.isEmpty) {
        return null;
      }
      
      // Analyze lighting conditions
      final imgLib = _convertYUV420ToImage(image);
      final LightingCondition lightingCondition = LightingAnalyzer.analyzeLighting(imgLib as double);
      
      // Only process the first face for now (most prominent)
      final Face face = faces.first;
      
      // Extract face image for emotion analysis
      final faceImage = _extractFaceImage(imgLib, face, imageSize);
      
      // Analyze emotion
      final EmotionResult emotionResult = (await EmotionAnalyzer.analyzeEmotion(faceImage as Map<String, double>)) as EmotionResult;
      
      // Get face bounds
      final faceRect = face.boundingBox;
      
      // Create face data
      return FaceData(
        boundingBox: faceRect,
        emotionType: emotionResult.dominantEmotion,
        emotionConfidence: emotionResult.confidence,
        lightingCondition: lightingCondition,
        isSmilingProbability: face.smilingProbability ?? 0.0,
        leftEyeOpenProbability: face.leftEyeOpenProbability ?? 0.0,
        rightEyeOpenProbability: face.rightEyeOpenProbability ?? 0.0,
      );
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }
  
  // Convert YUV420 format CameraImage to image_lib Image
  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    
    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;
    
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: Uint8List(width * height * 3).buffer,
    );
    
    for (int h = 0; h < height; h++) {
      int uvh = (h / 2).floor();
      
      for (int w = 0; w < width; w++) {
        int uvw = (w / 2).floor();
        
        final yIndex = h * yRowStride + w;
        final uvIndex = uvh * uvRowStride + uvw * uvPixelStride;
        
        final y = cameraImage.planes[0].bytes[yIndex];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];
        
        // Convert YUV to RGB
        int r = (y + 1.402 * (v - 128)).round().clamp(0, 255);
        int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).round().clamp(0, 255);
        int b = (y + 1.772 * (u - 128)).round().clamp(0, 255);
        
        image.setPixelRgba(w, h, r, g, b, 255);
      }
    }
    
    return image;
  }
  
  img.Image _extractFaceImage(img.Image inputImage, Face face, Size imageSize) {
    // Calculate scale factors
    final scaleX = inputImage.width / imageSize.width;
    final scaleY = inputImage.height / imageSize.height;
    
    // Scale face bounding box
    final scaledLeft = (face.boundingBox.left * scaleX).toInt();
    final scaledTop = (face.boundingBox.top * scaleY).toInt();
    final scaledWidth = (face.boundingBox.width * scaleX).toInt();
    final scaledHeight = (face.boundingBox.height * scaleY).toInt();
    
    // Ensure face box is within image bounds
    final left = max(0, scaledLeft);
    final top = max(0, scaledTop);
    final right = min(inputImage.width, scaledLeft + scaledWidth);
    final bottom = min(inputImage.height, scaledTop + scaledHeight);
    
    // Extract face region
    final faceImage = img.copyCrop(
      inputImage,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
    
    // Resize for emotion analysis
    return img.copyResize(faceImage, width: 48, height: 48);
  }
  
  void dispose() {
    _faceDetector?.close();
    _emotionAnalyzer?.dispose();
  }
}

class EmotionResult {
  get confidence => null;
  
  get dominantEmotion => null;
}
