import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/sos_model.dart';
import '../models/contact.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ================= ADMIN =================

  Future<bool> isUserAdmin(String email) async {
    final doc = await _firestore.collection('admins').doc(email).get();
    return doc.exists;
  }

  Future<Map<String, dynamic>?> getAdminData() async {
    final email = _auth.currentUser?.email;
    if (email == null) return null;

    final doc = await _firestore.collection('admins').doc(email).get();
    return doc.data();
  }

  Future<void> updateAdminProfile(Map<String, dynamic> data) async {
    final email = _auth.currentUser?.email;
    if (email == null) return;

    await _firestore.collection('admins').doc(email).update(data);
  }

  Future<void> sendPasswordReset() async {
    final email = _auth.currentUser?.email;
    if (email != null) {
      await _auth.sendPasswordResetEmail(email: email);
    }
  }

  // ================= USERS =================

  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading all user: $e');
      }
      rethrow;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user: $e');
      }
      rethrow;
    }
  }

  // ================= DASHBOARD =================

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      int totalUsers = usersSnapshot.docs.length;

      // Get all contacts from subcollections
      int totalContacts = 0;
      for (var userDoc in usersSnapshot.docs) {
        final contactsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('contacts')
            .get();
        totalContacts += contactsSnapshot.docs.length;
      }

      // Get SOS counts from sos_alerts collection
      final allSOSSnapshot = await _firestore.collection('sos_alerts').get();
      final activeSOSSnapshot = await _firestore
          .collection('sos_alerts')
          .where('status', isEqualTo: 'active')
          .get();

      return {
        'totalUsers': totalUsers,
        'totalContacts': totalContacts,
        'totalSOS': allSOSSnapshot.docs.length,
        'activeSOS': activeSOSSnapshot.docs.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error loading dashboard stats: $e');
      }
      rethrow;
    }
  }

  Future<List<SOSModel>> getRecentSOSAlerts({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('sos_alerts')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SOSModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recent SOS alerts: $e');
      }
      rethrow;
    }
  }

  Future<List<ContactModel>> getEmergencyContacts({int limit = 100}) async {
    try {
      List<ContactModel> allContacts = [];
      final usersSnapshot = await _firestore.collection('users').get();

      // Get contacts from all users' subcollections
      for (var userDoc in usersSnapshot.docs) {
        final contactsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('contacts')
            .limit(limit)
            .get();

        for (var contactDoc in contactsSnapshot.docs) {
          allContacts
              .add(ContactModel.fromMap(contactDoc.data(), contactDoc.id));
        }
      }

      return allContacts.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading emergency contacts: $e');
      }
      return []; // Return empty list instead of crashing
    }
  }

  Future<List<SOSModel>> getActiveSOSAlerts({int limit = 100}) async {
    try {
      // Get all SOS alerts ordered by timestamp, then filter by status in code
      // This avoids composite index requirement
      final snapshot = await _firestore
          .collection('sos_alerts')
          .orderBy('timestamp', descending: true)
          .limit(limit * 2) // Get extra to account for filtering
          .get();

      final alerts = snapshot.docs
          .map((doc) => SOSModel.fromMap(doc.data(), doc.id))
          .where(
              (alert) => alert.status == 'active' || alert.status == 'pending')
          .take(limit)
          .toList();

      return alerts;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading active SOS alerts: $e');
      }
      rethrow;
    }
  }

  Future<List<SOSModel>> getSOSHistory({int limit = 100}) async {
    try {
      return []; // No SOS history for now
    } catch (e) {
      if (kDebugMode) {
        print('Error loading SOS history: $e');
      }
      rethrow;
    }
  }

  Future<void> resolveSOSAlert(String alertId, String notes) async {
    try {
      final adminEmail = _auth.currentUser?.email ?? 'Unknown';

      // Update main SOS alert document
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': adminEmail,
        'notes': notes,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving SOS alert: $e');
      }
      rethrow;
    }
  }

  Future<void> updateSOSStatus(String alertId, String newStatus) async {
    try {
      final adminEmail = _auth.currentUser?.email ?? 'Unknown';

      Map<String, dynamic> updateData = {
        'status': newStatus,
      };

      if (newStatus == 'resolved') {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
        updateData['resolvedBy'] = adminEmail;
      }

      // Update main SOS alert document
      await _firestore.collection('sos_alerts').doc(alertId).update(updateData);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating SOS status: $e');
      }
      rethrow;
    }
  }
}
