import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import 'screens/camera_screen.dart';
import 'models/face_detection_model.dart';
import 'services/camera_service.dart';
import 'services/face_detector_service.dart';
import 'services/tensorflow_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Get available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FaceDetectionModel(),
        ),
        Provider(
          create: (_) => CameraService(camera: firstCamera),
        ),
        Provider(
          create: (_) => FaceDetectorService(),
        ),
        Provider(
          create: (_) => TensorFlowService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Condition Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CameraScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
