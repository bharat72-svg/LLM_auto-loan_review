class ContractAnalysis {
  final String id;
  final String filename;
  final Map<String, dynamic> slaAnalysis;
  final Map<String, dynamic> vehicleDetails;
  final String fairnessScore;
  final DateTime timestamp;

  ContractAnalysis({
    required this.id,
    required this.filename,
    required this.slaAnalysis,
    required this.vehicleDetails,
    required this.fairnessScore,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'slaAnalysis': slaAnalysis,
        'vehicleDetails': vehicleDetails,
        'fairnessScore': fairnessScore,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ContractAnalysis.fromJson(Map<String, dynamic> json) {
    return ContractAnalysis(
      id: json['id'],
      filename: json['filename'],
      slaAnalysis: Map<String, dynamic>.from(json['slaAnalysis']),
      vehicleDetails: Map<String, dynamic>.from(json['vehicleDetails']),
      fairnessScore: json['fairnessScore'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
