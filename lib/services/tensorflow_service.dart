import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/facial_condition.dart';
import '../utils/image_converter.dart';

class TensorFlowService {
  late Interpreter _interpreter;
  late List<String> _labels;
  bool _isInitialized = false;
  
  final int inputSize = 224; // Standard size for many image classification models

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      // Load TFLite model
      final modelData = await rootBundle.load('assets/models/facial_expression_model.tflite');
      final modelBuffer = modelData.buffer;
      final model = Uint8List.view(modelBuffer);

      // Create interpreter
      _interpreter = await Interpreter.fromBuffer(model);
      
      // Load labels
      final labelsFile = await rootBundle.loadString('assets/models/facial_expression_labels.txt');
      _labels = labelsFile.split('\n');
      
      _isInitialized = true;
      print('TensorFlow model initialized with ${_labels.length} labels: $_labels');
    } catch (e) {
      print('Error initializing TensorFlow model: $e');
      rethrow;
    }
  }

  Future<FacialCondition> analyzeFacialCondition(
    CameraImage cameraImage,
    Face face,
    CameraDescription camera,
  ) async {
    if (!_isInitialized) {
      throw Exception('TensorFlow model not initialized');
    }
    
    try {
      // Convert the camera image to an image that can be processed
      final image = await ImageConverter.convertCameraImageToImage(cameraImage);
      if (image == null) {
        return FacialCondition.empty();
      }
      
      // Crop the face area from the image
      final faceImage = _cropFaceFromImage(image, face);
      if (faceImage == null) {
        return FacialCondition.empty();
      }
      
      // Prepare the face image for the model
      final inputData = _preprocessImage(faceImage);
      
      // Run inference
      final outputShape = [1, _labels.length];
      final outputBuffer = List<List<double>>.filled(
        1, 
        List<double>.filled(_labels.length, 0.0),
      );
      
      _interpreter.run(inputData, outputBuffer);
      
      // Process results
      final results = outputBuffer[0];
      final predictions = <String, double>{};
      
      for (int i = 0; i < _labels.length; i++) {
        predictions[_labels[i]] = results[i];
      }
      
      return FacialCondition.fromPredictions(predictions);
    } catch (e) {
      print('Error analyzing facial condition: $e');
      return FacialCondition.empty();
    }
  }

  img.Image? _cropFaceFromImage(img.Image image, Face face) {
    try {
      // Get the face bounding box
      final rect = face.boundingBox;
      
      // Add some padding to include more of the face
      final paddingX = rect.width * 0.2;
      final paddingY = rect.height * 0.2;
      
      // Calculate new bounds with padding
      final left = (rect.left - paddingX).clamp(0.0, image.width.toDouble()).toInt();
      final top = (rect.top - paddingY).clamp(0.0, image.height.toDouble()).toInt();
      final right = (rect.right + paddingX).clamp(0.0, image.width.toDouble()).toInt();
      final bottom = (rect.bottom + paddingY).clamp(0.0, image.height.toDouble()).toInt();
      
      // Crop the image to the face region
      final croppedImage = img.copyCrop(
        image,
        left,
        top,
        right - left,
        bottom - top,
      );
      
      return croppedImage;
    } catch (e) {
      print('Error cropping face from image: $e');
      return null;
    }
  }

  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Resize the image to the required input size
    final resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );
    
    // Convert to float values in range [0, 1]
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            // Normalize pixel values
            return [
              img.getRed(pixel) / 255.0,
              img.getGreen(pixel) / 255.0,
              img.getBlue(pixel) / 255.0,
            ];
          },
        ),
      ),
    );
    
    return input;
  }

  void dispose() {
    if (_isInitialized) {
      _interpreter.close();
      _isInitialized = false;
    }
  }
}
