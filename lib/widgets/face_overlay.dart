import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceOverlay extends StatelessWidget {
  final List<Face> faces;
  final Size previewSize;
  final Size screenSize;
  
  const FaceOverlay({
    Key? key,
    required this.faces,
    required this.previewSize,
    required this.screenSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FaceOverlayPainter(
        faces: faces,
        previewSize: previewSize,
        screenSize: screenSize,
      ),
    );
  }
}

class FaceOverlayPainter extends CustomPainter {
  final List<Face> faces;
  final Size previewSize;
  final Size screenSize;
  
  FaceOverlayPainter({
    required this.faces,
    required this.previewSize,
    required this.screenSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Paint settings for the face boundaries
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.green;
    
    // Paint settings for the facial landmarks
    final Paint landmarkPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue
      ..strokeWidth = 3.0;
    
    for (final Face face in faces) {
      // Calculate scale factors to map the face coordinates from
      // the image space to the screen space
      final double scaleX = size.width / previewSize.height;
      final double scaleY = size.height / previewSize.width;
      
      // Draw face boundary
      final double left = face.boundingBox.left * scaleX;
      final double top = face.boundingBox.top * scaleY;
      final double right = face.boundingBox.right * scaleX;
      final double bottom = face.boundingBox.bottom * scaleY;
      
      // Draw the face rectangle
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );
      
      // In google_ml_kit 0.7.3, we'll draw key facial points if available
      if (face.leftEyeOpenProbability != null) {
        // Draw a circle for left eye
        canvas.drawCircle(
          Offset(
            (left + right) / 4, // Approximate left eye position
            (top + top + bottom) / 3,
          ),
          5.0,
          landmarkPaint,
        );
        
        // Draw a circle for right eye
        canvas.drawCircle(
          Offset(
            (left + right) * 3 / 4, // Approximate right eye position
            (top + top + bottom) / 3,
          ),
          5.0,
          landmarkPaint,
        );
        
        // Draw a circle for nose
        canvas.drawCircle(
          Offset(
            (left + right) / 2, // Approximate nose position
            (top + bottom) / 2,
          ),
          5.0,
          landmarkPaint,
        );
        
        // Draw a circle for mouth
        canvas.drawCircle(
          Offset(
            (left + right) / 2, // Approximate mouth position
            (top + bottom) * 2 / 3,
          ),
          5.0,
          landmarkPaint,
        );
      }
      
      // Write the confidence score using smiling probability
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: 'Smiling: ${((face.smilingProbability ?? 0) * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(left, top - 20));
    }
  }
  
  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}