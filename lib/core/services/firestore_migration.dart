import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _userContactsRef(
          String userId) =>
      _firestore.collection('users').doc(userId).collection('contacts');

  static CollectionReference<Map<String, dynamic>> _userHistoryRef(
          String userId) =>
      _firestore.collection('users').doc(userId).collection('sos_history');

  static Future<void> _ensureUserDocument(String userId) async {
    await _firestore.collection('users').doc(userId).set(
      {
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> migrateContacts(String userId) async {
    await _ensureUserDocument(userId);

    final snapshot = await _firestore
        .collection('contacts')
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data.remove('userId');

      final targetDoc = _userContactsRef(userId).doc(doc.id);
      batch.set(targetDoc, data, SetOptions(merge: true));
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  static Future<void> migrateHistory(String userId) async {
    await _ensureUserDocument(userId);

    final snapshot = await _firestore
        .collection('sos_historys')
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data.remove('userId');

      final targetDoc = _userHistoryRef(userId).doc(doc.id);
      batch.set(targetDoc, data, SetOptions(merge: true));
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  static Future<void> migrateUserRootCollections(String userId) async {
    await migrateContacts(userId);
    await migrateHistory(userId);
  }
}
