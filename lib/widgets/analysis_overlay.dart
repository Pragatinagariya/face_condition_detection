import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/face_data.dart';
import '../lighting_analyzer.dart';

class AnalysisOverlay extends StatelessWidget {
  const AnalysisOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FaceDataModel>(
      builder: (context, faceDataModel, child) {
        final faceData = faceDataModel.faceData;
        
        if (faceData == null) {
          return _buildNoFaceDetectedOverlay();
        }
        
        return Stack(
          fit: StackFit.expand,
          children: [
            // Face bounding box
            CustomPaint(
              painter: FaceBoundingBoxPainter(faceData.boundingBox),
            ),
            
            // Information panel
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: _buildInfoPanel(faceData, context),
            ),
            
            // Lighting adjustment suggestion
            if (faceData.lightingCondition != LightingCondition.normal)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: _buildLightingAdjustmentPanel(faceData.lightingCondition),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildNoFaceDetectedOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No face detected',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoPanel(FaceData faceData, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Face Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Emotion
          _buildInfoRow(
            context,
            'Emotion',
            faceData.emotionLabel,
            _getEmotionIcon(faceData.emotionType),
            _getEmotionColor(faceData.emotionType),
            faceData.emotionConfidence,
          ),
          
          const SizedBox(height: 8),
          
          // Tiredness
          _buildInfoRow(
            context,
            'Tiredness',
            _getTirednessLabel(faceData.tirednessScore),
            Icons.nightlight_round,
            _getValueColor(faceData.tirednessScore),
            faceData.tirednessScore,
          ),
          
          const SizedBox(height: 8),
          
          // Stress
          _buildInfoRow(
            context,
            'Stress',
            _getStressLabel(faceData.stressScore),
            Icons.psychology,
            _getValueColor(faceData.stressScore),
            faceData.stressScore,
          ),
          
          const SizedBox(height: 8),
          
          // Lighting
          _buildInfoRow(
            context,
            'Lighting',
            faceData.lightingLabel,
            _getLightingIcon(faceData.lightingCondition),
            _getLightingColor(faceData.lightingCondition),
            null,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    double? progressValue,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        if (progressValue != null)
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
      ],
    );
  }
  
  Widget _buildLightingAdjustmentPanel(LightingCondition condition) {
    String message;
    IconData icon;
    
    switch (condition) {
      case LightingCondition.tooDark:
        message = 'Environment is too dark - move to a brighter area';
        icon = Icons.brightness_low;
        break;
      case LightingCondition.tooBright:
        message = 'Environment is too bright - reduce light or change angle';
        icon = Icons.brightness_high;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _getLightingColor(condition),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getEmotionIcon(dynamic emotionType) {
    switch (emotionType) {
      case EmotionType.happy:
        return Icons.sentiment_very_satisfied;
      case EmotionType.sad:
        return Icons.sentiment_dissatisfied;
      case EmotionType.angry:
        return Icons.sentiment_very_dissatisfied;
      case EmotionType.surprised:
        return Icons.sentiment_neutral;
      case EmotionType.fearful:
        return Icons.sentiment_very_dissatisfied;
      case EmotionType.disgusted:
        return Icons.sick;
      case EmotionType.neutral:
        return Icons.sentiment_neutral;
      case EmotionType.tired:
        return Icons.bedtime;
      case EmotionType.stressed:
        return Icons.psychology;
      default:
        return Icons.face;
    }
  }
  
  Color _getEmotionColor(dynamic emotionType) {
    switch (emotionType) {
      case EmotionType.happy:
        return Colors.green;
      case EmotionType.sad:
        return Colors.blue;
      case EmotionType.angry:
        return Colors.red;
      case EmotionType.surprised:
        return Colors.amber;
      case EmotionType.fearful:
        return Colors.purple;
      case EmotionType.disgusted:
        return Colors.deepOrange;
      case EmotionType.neutral:
        return Colors.grey;
      case EmotionType.tired:
        return Colors.indigo;
      case EmotionType.stressed:
        return Colors.deepOrange;
      default:
        return Colors.white;
    }
  }
  
  IconData _getLightingIcon(LightingCondition condition) {
    switch (condition) {
      case LightingCondition.tooDark:
        return Icons.brightness_low;
      case LightingCondition.tooBright:
        return Icons.brightness_high;
      case LightingCondition.normal:
        return Icons.brightness_medium;
      default:
        return Icons.brightness_medium;
    }
  }
  
  Color _getLightingColor(LightingCondition condition) {
    switch (condition) {
      case LightingCondition.tooDark:
        return Colors.blue;
      case LightingCondition.tooBright:
        return Colors.amber;
      case LightingCondition.normal:
        return Colors.green;
      default:
        return Colors.white;
    }
  }
  
  Color _getValueColor(double value) {
    if (value < 0.3) return Colors.green;
    if (value < 0.6) return Colors.amber;
    return Colors.red;
  }
  
  String _getTirednessLabel(double score) {
    if (score < 0.3) return 'Alert';
    if (score < 0.6) return 'Slightly Tired';
    return 'Very Tired';
  }
  
  String _getStressLabel(double score) {
    if (score < 0.3) return 'Relaxed';
    if (score < 0.6) return 'Moderate';
    return 'Stressed';
  }
}

class FaceBoundingBoxPainter extends CustomPainter {
  final Rect boundingBox;
  
  FaceBoundingBoxPainter(this.boundingBox);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Scale the bounding box to match the screen size
    final scaleX = size.width;
    final scaleY = size.height;
    
    final scaledRect = Rect.fromLTRB(
      boundingBox.left * scaleX,
      boundingBox.top * scaleY,
      boundingBox.right * scaleX,
      boundingBox.bottom * scaleY,
    );
    
    // Draw the face bounding box
    canvas.drawRect(scaledRect, paint);
    
    // Draw corner accents
    final cornerLength = scaledRect.width * 0.1; // 10% of width for corners
    
    // Top left corner
    canvas.drawLine(
      Offset(scaledRect.left, scaledRect.top),
      Offset(scaledRect.left + cornerLength, scaledRect.top),
      paint..color = Colors.blue
    );
    canvas.drawLine(
      Offset(scaledRect.left, scaledRect.top),
      Offset(scaledRect.left, scaledRect.top + cornerLength),
      paint
    );
    
    // Top right corner
    canvas.drawLine(
      Offset(scaledRect.right, scaledRect.top),
      Offset(scaledRect.right - cornerLength, scaledRect.top),
      paint
    );
    canvas.drawLine(
      Offset(scaledRect.right, scaledRect.top),
      Offset(scaledRect.right, scaledRect.top + cornerLength),
      paint
    );
    
    // Bottom left corner
    canvas.drawLine(
      Offset(scaledRect.left, scaledRect.bottom),
      Offset(scaledRect.left + cornerLength, scaledRect.bottom),
      paint
    );
    canvas.drawLine(
      Offset(scaledRect.left, scaledRect.bottom),
      Offset(scaledRect.left, scaledRect.bottom - cornerLength),
      paint
    );
    
    // Bottom right corner
    canvas.drawLine(
      Offset(scaledRect.right, scaledRect.bottom),
      Offset(scaledRect.right - cornerLength, scaledRect.bottom),
      paint
    );
    canvas.drawLine(
      Offset(scaledRect.right, scaledRect.bottom),
      Offset(scaledRect.right, scaledRect.bottom - cornerLength),
      paint
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
