import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/sos_model.dart';
import '../models/contact.dart';
import 'location_service.dart';
import 'sms_service.dart';
import 'whatsapp_service.dart';

class SOSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final LocationService _locationService = LocationService();
  final SMSService _smsService = SMSService();
  final WhatsAppService _whatsAppService = WhatsAppService();

  /// Trigger complete SOS emergency flow
  Future<Map<String, dynamic>> triggerSOS({
    String? customMessage,
  }) async {
    try {
      // 1. Get current user
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('SOS Debug: User not authenticated');
        }
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      String userId = user.uid;
      String userEmail = user.email ?? '';
      String userName = user.displayName ?? 'User';

      if (kDebugMode) {
        print('SOS Debug: Triggering SOS for user $userId ($userEmail)');
      }

      if (kDebugMode) {
        debugPrint(
            'Note: On emulator, phone calls and WhatsApp may not fully work. Test on a real device for full functionality.');
      }

      // 2. Get user document for name
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        userName = userDoc.data()?['name'] ?? userName;
      }

      // 3. Get location
      if (kDebugMode) {
        print('SOS Debug: Getting location for user $userId');
      }

      Map<String, String> locationData =
          await _locationService.getLocationMessage();

      double latitude = 0;
      double longitude = 0;
      String address = locationData['address'] ?? 'Location unavailable';
      String mapsLink = locationData['link'] ?? '';

      if (kDebugMode) {
        print('SOS Debug: Location data - address: $address, link: $mapsLink');
      }

      // Try to get position coordinates
      var position = await _locationService.getCurrentLocation();
      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
        if (kDebugMode) {
          print('SOS Debug: Got position - lat: $latitude, lng: $longitude');
        }
      } else {
        if (kDebugMode) {
          print('SOS Debug: Failed to get position');
        }
      }

      // 4. Get emergency contacts (max 3)
      List<ContactModel> contacts = await _getEmergencyContacts(userId);

      if (kDebugMode) {
        print('SOS Debug: Found ${contacts.length} contacts for user $userId');
        for (var contact in contacts) {
          print(
              'SOS Debug: Contact - ${contact.name}: ${contact.phone}, addedAt: ${contact.addedAt}');
        }
      }

      if (contacts.isEmpty) {
        return {
          'success': false,
          'error':
              'No emergency contacts configured. Please add contacts first.',
        };
      }

      // 5. Prepare contacts for services
      List<Map<String, String>> contactList =
          contacts.map((c) => {'name': c.name, 'phone': c.phone}).toList();

      // 6. Send SMS to all contacts
      Map<String, dynamic> smsResult = {};
      try {
        smsResult = await _smsService.sendSOSMessages(
          contacts: contactList,
          userName: userName,
          customMessage: customMessage,
        );
        if (kDebugMode) debugPrint('SOS Debug: SMS result: $smsResult');
      } catch (e) {
        if (kDebugMode) debugPrint('SOS Debug: SMS sending error: $e');
      }

      // 7. Send WhatsApp to all contacts
      Map<String, dynamic> whatsappResult = {};
      try {
        whatsappResult = await _whatsAppService.sendSOSWhatsAppMessages(
          contacts: contactList,
          userName: userName,
          customMessage: customMessage,
        );
        if (kDebugMode)
          debugPrint('SOS Debug: WhatsApp result: $whatsappResult');
      } catch (e) {
        if (kDebugMode) debugPrint('SOS Debug: WhatsApp sending error: $e');
      }

      // 8. Make auto-call to primary contact (1st contact)
      bool callInitiated = false;
      String primaryContactPhone = '';
      if (contacts.isNotEmpty) {
        primaryContactPhone = contacts[0].phone;
        try {
          await _locationService.makePhoneCall(primaryContactPhone);
          callInitiated = true;
        } catch (e) {
          if (kDebugMode) debugPrint('SOS Debug: auto-call error: $e');
        }
      }

      // 9. Save SOS history to Firestore
      String sosId = await _saveSOSHistory(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        latitude: latitude,
        longitude: longitude,
        address: address,
        mapsLink: mapsLink,
        contacts: contactList,
        customMessage: customMessage,
      );

      // 10. Notify admin
      await _notifyAdmin(
        sosId: sosId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        latitude: latitude,
        longitude: longitude,
        address: address,
        mapsLink: mapsLink,
        primaryContact: contacts.isNotEmpty ? contacts[0].name : 'None',
        primaryContactPhone: primaryContactPhone,
      );

      return {
        'success': true,
        'sosId': sosId,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'mapsLink': mapsLink,
        },
        'contacts': {
          'total': contacts.length,
          'smsResult': smsResult,
          'whatsappResult': whatsappResult,
        },
        'primaryCall': {
          'initiated': callInitiated,
          'contact': contacts.isNotEmpty ? contacts[0].name : null,
          'phone': primaryContactPhone,
        },
        'adminNotified': true,
      };
    } catch (e) {
      if (kDebugMode) {
        print('SOS Trigger Error: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get emergency contacts for a user
  Future<List<ContactModel>> _getEmergencyContacts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .limit(3)
          .get();

      List<ContactModel> contacts = snapshot.docs
          .map((doc) => ContactModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by addedAt if available, otherwise by document ID (creation order)
      contacts.sort((a, b) {
        if (a.addedAt != null && b.addedAt != null) {
          return a.addedAt!.compareTo(b.addedAt!);
        } else if (a.addedAt != null) {
          return -1; // a comes first if it has addedAt
        } else if (b.addedAt != null) {
          return 1; // b comes first if it has addedAt
        } else {
          // Both don't have addedAt, sort by ID (creation order)
          return a.id.compareTo(b.id);
        }
      });

      // Update contacts that don't have addedAt field
      await _updateContactsWithAddedAt(userId, snapshot.docs);

      return contacts;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting contacts: $e');
      }
      return [];
    }
  }

  /// Update existing contacts to have addedAt field if missing
  Future<void> _updateContactsWithAddedAt(
      String userId, List<QueryDocumentSnapshot> docs) async {
    try {
      WriteBatch batch = _firestore.batch();
      int updateCount = 0;

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('addedAt') || data['addedAt'] == null) {
          batch.update(doc.reference, {
            'addedAt': FieldValue.serverTimestamp(),
          });
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        if (kDebugMode) {
          print('Updated $updateCount contacts with addedAt field');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating contacts with addedAt: $e');
      }
      // Don't throw - this is a background update
    }
  }

  /// Save SOS history to Firestore
  Future<String> _saveSOSHistory({
    required String userId,
    required String userName,
    required String userEmail,
    required double latitude,
    required double longitude,
    required String address,
    required String mapsLink,
    required List<Map<String, String>> contacts,
    String? customMessage,
  }) async {
    try {
      // Create main SOS document
      DocumentReference sosDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sos_history')
          .add({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'latitude': latitude,
        'longitude': longitude,
        'location': address,
        'mapsLink': mapsLink,
        'severity': 'high',
        'status': 'active',
        'timestamp': FieldValue.serverTimestamp(),
        'customMessage': customMessage,
        'contactsNotified': contacts.length,
        'primaryContact': contacts.isNotEmpty ? contacts[0]['name'] : null,
        'primaryContactPhone':
            contacts.isNotEmpty ? contacts[0]['phone'] : null,
      });

      // Also save to root-level sos_alerts for admin access
      await _firestore.collection('sos_alerts').doc(sosDoc.id).set({
        'id': sosDoc.id,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'latitude': latitude,
        'longitude': longitude,
        'location': address,
        'mapsLink': mapsLink,
        'severity': 'high',
        'status': 'active',
        'timestamp': FieldValue.serverTimestamp(),
        'customMessage': customMessage,
        'contactsNotified': contacts.length,
        'primaryContact': contacts.isNotEmpty ? contacts[0]['name'] : null,
        'primaryContactPhone':
            contacts.isNotEmpty ? contacts[0]['phone'] : null,
        'createdAt': DateTime.now(),
      });

      return sosDoc.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving SOS history: $e');
      }
      rethrow;
    }
  }

  /// Notify admin about SOS trigger
  Future<void> _notifyAdmin({
    required String sosId,
    required String userId,
    required String userName,
    required String userEmail,
    required double latitude,
    required double longitude,
    required String address,
    required String mapsLink,
    required String primaryContact,
    required String primaryContactPhone,
  }) async {
    try {
      // Update admin notification collection
      await _firestore.collection('admin_notifications').add({
        'type': 'sos_alert',
        'sosId': sosId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'latitude': latitude,
        'longitude': longitude,
        'location': address,
        'mapsLink': mapsLink,
        'primaryContact': primaryContact,
        'primaryContactPhone': primaryContactPhone,
        'status': 'unread',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Also update dashboard stats - increment active SOS
      final statsDoc = _firestore.collection('stats').doc('dashboard');
      await statsDoc.set({
        'activeSOS': FieldValue.increment(1),
        'lastSOSUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error notifying admin: $e');
      }
      // Don't throw - admin notification is secondary
    }
  }

  // ================= EXISTING METHODS =================

  /// Get SOS history for current user
  Future<List<SOSModel>> getSOSHistory({int limit = 20}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sos_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SOSModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading SOS history: $e');
      }
      return [];
    }
  }

  /// Cancel an active SOS
  Future<void> cancelSOS(String sosId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update user subcollection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sos_history')
          .doc(sosId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Update root sos_alerts
      await _firestore.collection('sos_alerts').doc(sosId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Decrement active SOS count
      final statsDoc = _firestore.collection('stats').doc('dashboard');
      await statsDoc.update({
        'activeSOS': FieldValue.increment(-1),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling SOS: $e');
      }
      rethrow;
    }
  }

  /// Get active SOS for current user
  Future<SOSModel?> getActiveSOS() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sos_history')
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return SOSModel.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active SOS: $e');
      }
      return null;
    }
  }

  /// Check if user has emergency contacts (for debugging)
  Future<Map<String, dynamic>> checkEmergencyContacts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
          'contacts': [],
        };
      }

      String userId = user.uid;
      List<ContactModel> contacts = await _getEmergencyContacts(userId);

      return {
        'success': true,
        'userId': userId,
        'contactCount': contacts.length,
        'contacts': contacts
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'phone': c.phone,
                  'addedAt': c.addedAt?.toIso8601String(),
                })
            .toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'contacts': [],
      };
    }
  }
}
