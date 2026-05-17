import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  String? _errorMessage;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location service are disabled.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _permissionDenied = true;
          _errorMessage = 'Location permission denied.';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _updateLocation(position);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(_updateLocation);
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to get location: $e';
      });
    }
  }

  void _updateLocation(Position position) {
    final location = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentLocation = location;
      _errorMessage = null;
    });

    _mapController.move(location, 16.0);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenStreetMap Location'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _onRecenter,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            _errorMessage ?? 'Location permission is denied.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (_currentLocation == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding your location...'),
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _currentLocation,
        zoom: 16.0,
        minZoom: 3.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.women_safety',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation!,
              width: 80,
              height: 80,
              builder: (context) => const Icon(
                Icons.location_on,
                size: 48,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
              showFlutterMapAttribution: false,
            ),
          ),
        ),
      ],
    );
  }

  void _onRecenter() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0);
    }
  }
}
