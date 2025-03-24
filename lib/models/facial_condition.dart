class FacialCondition {
  final double happy;
  final double sad;
  final double tired;
  final double stressed;
  final String dominantCondition;

  FacialCondition({
    required this.happy,
    required this.sad,
    required this.tired,
    required this.stressed,
    required this.dominantCondition,
  });

  factory FacialCondition.fromPredictions(Map<String, double> predictions) {
    // Find the dominant condition
    String dominant = "Unknown";
    double maxValue = 0.0;
    
    predictions.forEach((key, value) {
      if (value > maxValue) {
        maxValue = value;
        dominant = key;
      }
    });

    return FacialCondition(
      happy: predictions['happy'] ?? 0.0,
      sad: predictions['sad'] ?? 0.0,
      tired: predictions['tired'] ?? 0.0,
      stressed: predictions['stressed'] ?? 0.0,
      dominantCondition: dominant,
    );
  }

  // Default/empty facial condition
  factory FacialCondition.empty() {
    return FacialCondition(
      happy: 0.0,
      sad: 0.0,
      tired: 0.0,
      stressed: 0.0,
      dominantCondition: "Unknown",
    );
  }
}
