import 'package:url_launcher/url_launcher.dart';
import 'location_service.dart';

class WhatsAppService {
  final LocationService _locationService = LocationService();

  /// Send SOS WhatsApp message with location to multiple contacts
  Future<Map<String, dynamic>> sendSOSWhatsAppMessages({
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

      // Clean phone number (remove + prefix for WhatsApp)
      String cleanPhone = _cleanPhoneNumber(phone);

      try {
        bool sent = await _sendWhatsAppMessage(cleanPhone, sosMessage);

        results.add({
          'contact': name,
          'phone': phone,
          'whatsappPhone': cleanPhone,
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

  /// Build the SOS message text for WhatsApp
  String _buildSOSMessage({
    required String userName,
    required String mapsLink,
    required String address,
    required String coordinates,
    String? customMessage,
  }) {
    StringBuffer message = StringBuffer();

    message.writeln('🚨 *EMERGENCY SOS* 🚨');
    message.writeln('');
    message.writeln('*This is an emergency alert from $userName*');
    message.writeln('');

    if (customMessage != null && customMessage.isNotEmpty) {
      message.writeln(customMessage);
      message.writeln('');
    }

    message.writeln('📍 *MY LOCATION:*');
    message.writeln(address);

    if (mapsLink.isNotEmpty) {
      message.writeln('');
      message.writeln('🗺️ *VIEW ON MAP:*');
      message.writeln(mapsLink);
    }

    if (coordinates.isNotEmpty) {
      message.writeln('');
      message.writeln('📌 *Coordinates:* $coordinates');
    }

    message.writeln('');
    message.writeln('Sent via *Women Safety App*');

    return message.toString();
  }

  /// Clean phone number for WhatsApp API
  String _cleanPhoneNumber(String phone) {
    // Remove all non-digit characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Remove + if present, we'll add it back
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // If no country code, assume +91 (India)
    if (!cleaned.startsWith('91') && cleaned.length == 10) {
      cleaned = '91$cleaned';
    }

    return cleaned;
  }

  /// Send WhatsApp message
  Future<bool> _sendWhatsAppMessage(String phone, String message) async {
    try {
      // Encode message for URL
      String encodedMessage = Uri.encodeComponent(message);

      // Try WhatsApp API scheme
      String whatsappUrl = 'https://wa.me/$phone?text=$encodedMessage';

      Uri uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }

      // Fallback to WhatsApp app scheme
      String appUrl = 'whatsapp://send?phone=$phone&text=$encodedMessage';
      Uri appUri = Uri.parse(appUrl);

      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return true;
      }

      return false;
    } catch (e) {
      print('WhatsApp Error: $e');
      return false;
    }
  }

  /// Send a simple WhatsApp message (non-SOS)
  Future<bool> sendWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      String cleanPhone = _cleanPhoneNumber(phoneNumber);
      String encodedMessage = Uri.encodeComponent(message);

      String whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';
      Uri uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }

      return false;
    } catch (e) {
      print('WhatsApp Error: $e');
      return false;
    }
  }

  /// Check if WhatsApp is installed
  Future<bool> isWhatsAppInstalled() async {
    try {
      Uri uri = Uri.parse('whatsapp://');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }
}
