import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  /// Get current location with permission handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        return addressParts.join(', ');
      }
      return 'Unknown location';
    } catch (e) {
      print('Error getting address: $e');
      return 'Location unavailable';
    }
  }

  /// Generate Google Maps link from coordinates
  String generateGoogleMapsLink(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  /// Generate full location message with map link
  Future<Map<String, String>> getLocationMessage() async {
    Position? position = await getCurrentLocation();

    if (position == null) {
      return {
        'link': '',
        'address': 'Location unavailable',
        'coordinates': '',
      };
    }

    String address = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    String mapsLink = generateGoogleMapsLink(
      position.latitude,
      position.longitude,
    );

    return {
      'link': mapsLink,
      'address': address,
      'coordinates': '${position.latitude}, ${position.longitude}',
    };
  }

  /// Open location in maps app
  Future<void> openLocationInMaps(double latitude, double longitude) async {
    String mapsUrl = generateGoogleMapsLink(latitude, longitude);
    Uri uri = Uri.parse(mapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Make phone call
  Future<void> makePhoneCall(String phoneNumber) async {
    String telUrl = 'tel:$phoneNumber';
    Uri uri = Uri.parse(telUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Send SMS
  Future<void> sendSMS(String phoneNumber, String message) async {
    String smsUrl = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
    Uri uri = Uri.parse(smsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
