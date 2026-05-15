import 'package:url_launcher/url_launcher.dart';
import 'location_service.dart';

class SMSService {
  final LocationService _locationService = LocationService();

  /// Send SOS SMS with location to multiple contacts
  Future<Map<String, dynamic>> sendSOSMessages({
    required List<Map<String, String>> contacts,
    required String userName,
    String? customMessage,
  }) async {
    // Get current location
    Map<String, String> locationData =
        await _locationService.getLocationMessage();

    String mapsLink = locationData['link'] ?? '';
    String address = locationData['address'] ?? 'Location unavailable';
    String coordinates = locationData['coordinates'] ?? '';

    // Build SOS message
    String sosMessage = _buildSOSMessage(
      userName: userName,
      mapsLink: mapsLink,
      address: address,
      coordinates: coordinates,
      customMessage: customMessage,
    );

    // Track results
    List<Map<String, dynamic>> results = [];
    int successCount = 0;
    int failCount = 0;

    // Send to all contacts
    for (var contact in contacts) {
      String phone = contact['phone'] ?? '';
      String name = contact['name'] ?? 'Contact';

      if (phone.isEmpty) {
        results.add({
          'contact': name,
          'phone': phone,
          'status': 'failed',
          'error': 'Empty phone number',
        });
        failCount++;
        continue;
      }

      try {
        // Try to open SMS with pre-filled message
        bool sent = await _sendSMSWithFallback(phone, sosMessage);

        results.add({
          'contact': name,
          'phone': phone,
          'status': sent ? 'sent' : 'opened',
          'message': sosMessage,
        });

        if (sent) successCount++;
      } catch (e) {
        results.add({
          'contact': name,
          'phone': phone,
          'status': 'failed',
          'error': e.toString(),
        });
        failCount++;
      }
    }

    return {
      'success': failCount == 0,
      'totalContacts': contacts.length,
      'successCount': successCount,
      'failCount': failCount,
      'results': results,
      'location': {
        'link': mapsLink,
        'address': address,
        'coordinates': coordinates,
      },
      'message': sosMessage,
    };
  }

  /// Build the SOS message text
  String _buildSOSMessage({
    required String userName,
    required String mapsLink,
    required String address,
    required String coordinates,
    String? customMessage,
  }) {
    StringBuffer message = StringBuffer();

    message.writeln('🚨 EMERGENCY SOS 🚨');
    message.writeln('');
    message.writeln('This is an emergency alert from $userName');
    message.writeln('');

    if (customMessage != null && customMessage.isNotEmpty) {
      message.writeln(customMessage);
      message.writeln('');
    }

    message.writeln('📍 MY LOCATION:');
    message.writeln(address);

    if (mapsLink.isNotEmpty) {
      message.writeln('');
      message.writeln('🗺️ VIEW ON MAP: $mapsLink');
    }

    if (coordinates.isNotEmpty) {
      message.writeln('');
      message.writeln('📌 Coordinates: $coordinates');
    }

    message.writeln('');
    message.writeln('Sent via Women Safety App');

    return message.toString();
  }

  /// Send SMS with fallback to SMS app
  Future<bool> _sendSMSWithFallback(String phone, String message) async {
    try {
      // Try direct SMS URL scheme
      String encodedMessage = Uri.encodeComponent(message);
      String smsUrl = 'sms:$phone?body=$encodedMessage';

      Uri uri = Uri.parse(smsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }

      // Fallback: try without body (opens SMS app)
      String fallbackUrl = 'sms:$phone';
      Uri fallbackUri = Uri.parse(fallbackUrl);

      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri);
        return true;
      }

      return false;
    } catch (e) {
      print('SMS Error: $e');
      return false;
    }
  }

  /// Send a simple SMS (non-SOS)
  Future<bool> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      String encodedMessage = Uri.encodeComponent(message);
      String smsUrl = 'sms:$phoneNumber?body=$encodedMessage';

      Uri uri = Uri.parse(smsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }

      return false;
    } catch (e) {
      print('SMS Error: $e');
      return false;
    }
  }
}
