import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  /// Get current location with permission handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled');
        return null;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            'LocationService: Location permissions are permanently denied');
        // Optionally prompt user to open app settings
        try {
          await Geolocator.openAppSettings();
        } catch (_) {}
        return null;
      }

      // Get current position
      // Attempt to get a high accuracy current location
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('LocationService: Error getting location: $e');
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
      debugPrint('LocationService: Error getting address: $e');
      return 'Location unavailable';
    }
  }

  /// Generate OpenStreetMap link from coordinates
  String generateOpenStreetMapLink(double latitude, double longitude) {
    // Always return a valid OpenStreetMap URL. If coordinates are invalid
    // (e.g., 0,0) this still points to the main map page.
    if (latitude == 0 && longitude == 0) {
      return 'https://www.openstreetmap.org';
    }
    return 'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude';
  }

  /// Generate full location message with map link
  Future<Map<String, String>> getLocationMessage() async {
    Position? position = await getCurrentLocation();

    double lat = 0;
    double lon = 0;
    String address = 'Location unavailable';

    if (position != null) {
      lat = position.latitude;
      lon = position.longitude;
      try {
        address = await getAddressFromCoordinates(lat, lon);
      } catch (e) {
        debugPrint('LocationService: reverse geocoding failed: $e');
      }
    } else {
      debugPrint(
          'LocationService: position is null, returning generic map link');
    }

    String mapsLink = generateOpenStreetMapLink(lat, lon);

    return {
      'link': mapsLink,
      'address': address,
      'coordinates':
          position != null ? '${lat.toString()}, ${lon.toString()}' : '',
    };
  }

  /// Open location in maps app
  Future<void> openLocationInMaps(double latitude, double longitude) async {
    try {
      String mapsUrl = generateOpenStreetMapLink(latitude, longitude);
      Uri uri = Uri.parse(mapsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('LocationService: cannot launch maps uri: $uri');
      }
    } catch (e) {
      debugPrint('LocationService: openLocationInMaps error: $e');
    }
  }

  /// Make phone call
  Future<void> makePhoneCall(String phoneNumber) async {
    try {
      // Request phone permission at runtime if needed
      try {
        PermissionStatus p = await Permission.phone.status;
        if (!p.isGranted) {
          await Permission.phone.request();
        }
      } catch (e) {
        debugPrint('LocationService: phone permission request error: $e');
      }
      String telUrl = 'tel:$phoneNumber';
      Uri uri = Uri.parse(telUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('LocationService: cannot launch tel uri: $uri');
      }
    } catch (e) {
      debugPrint('LocationService: makePhoneCall error: $e');
    }
  }

  /// Send SMS
  Future<void> sendSMS(String phoneNumber, String message) async {
    try {
      String smsUrl = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
      Uri uri = Uri.parse(smsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('LocationService: cannot launch sms uri: $uri');
      }
    } catch (e) {
      debugPrint('LocationService: sendSMS error: $e');
    }
  }
}
