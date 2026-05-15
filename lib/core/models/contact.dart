class ContactModel {
  final String id;
  final String userId;
  final String name;
  final String relation;
  final String phone;
  final DateTime? addedAt;

  ContactModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.relation,
    required this.phone,
    this.addedAt,
  });

  factory ContactModel.fromMap(Map<String, dynamic> data, String docId) {
    return ContactModel(
      id: docId,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unknown',
      relation: data['relation'] ?? 'Guardian',
      phone: data['phone'] ?? '',
      addedAt: data['addedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'relation': relation,
      'phone': phone,
      'addedAt': addedAt,
    };
  }
}
