class SOSModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final double latitude;
  final double longitude;
  final String location;
  final String severity; // high, medium, low
  final String status; // active, resolved, cancelled
  final DateTime timestamp;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? notes;

  SOSModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.severity,
    required this.status,
    required this.timestamp,
    this.resolvedAt,
    this.resolvedBy,
    this.notes,
  });

  factory SOSModel.fromMap(Map<String, dynamic> data, String docId) {
    return SOSModel(
      id: docId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      severity: data['severity'] ?? 'medium',
      status: data['status'] ?? 'active',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      resolvedAt: data['resolvedAt']?.toDate(),
      resolvedBy: data['resolvedBy'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'severity': severity,
      'status': status,
      'timestamp': timestamp,
      'resolvedAt': resolvedAt,
      'resolvedBy': resolvedBy,
      'notes': notes,
    };
  }
}
