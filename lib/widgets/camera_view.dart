import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraView extends StatelessWidget {
  final CameraController controller;

  const CameraView({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    
    // Calculate scale to fill the screen and maintain aspect ratio
    final scale = 1 / (controller.value.aspectRatio * deviceRatio);
    
    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Center(
        child: CameraPreview(controller),
      ),
    );
  }
}
