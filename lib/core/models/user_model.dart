class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String status; // active, blocked, inactive
  final String role; // user, emergency_contact, admin
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isBlocked;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.status,
    required this.role,
    required this.createdAt,
    required this.lastSeen,
    required this.isBlocked,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String docId) {
    final statusValue = data['status'] ?? 'active';
    final isBlockedValue = data['isBlocked'] ?? statusValue == 'blocked';

    return UserModel(
      id: docId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      location: data['location'] ?? '',
      status: statusValue,
      role: data['role'] ?? 'user',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastSeen: data['lastSeen']?.toDate() ?? DateTime.now(),
      isBlocked: isBlockedValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'status': status,
      'role': role,
      'createdAt': createdAt,
      'lastSeen': lastSeen,
      'isBlocked': isBlocked,
    };
  }
}
