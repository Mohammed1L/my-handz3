import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _selectedLocation = LatLng(24.7136, 46.6753); // Default: Riyadh
  final MapController _mapController = MapController();
  LocationData? _currentLocation;
  final Location _locationService = Location();
  double _zoom = 13.0;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final hasPermission = await _locationService.requestPermission();
    final isServiceEnabled = await _locationService.serviceEnabled() ||
        await _locationService.requestService();

    if (hasPermission == PermissionStatus.granted && isServiceEnabled) {
      final location = await _locationService.getLocation();
      setState(() {
        _currentLocation = location;
        _selectedLocation = LatLng(location.latitude!, location.longitude!);
      });

      _mapController.move(
        _selectedLocation,
        _zoom,
      );
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
    });
  }

  void _confirmLocation() {
    Navigator.pop(context, _selectedLocation);
  }

  void _recenterToUser() {
    if (_currentLocation != null) {
      final latlng = LatLng(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
      );
      setState(() {
        _selectedLocation = latlng;
      });
      _mapController.move(latlng, _zoom);
    }
  }

  void _zoomIn() {
    setState(() => _zoom += 1);
    _mapController.move(_mapController.center, _zoom);
  }

  void _zoomOut() {
    setState(() => _zoom -= 1);
    _mapController.move(_mapController.center, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select Your Location",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007EA7)),
        ),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: const Color(0xFF007EA7),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _selectedLocation,
              zoom: _zoom,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 50,
                    height: 50,
                    point: _selectedLocation,
                    rotate: true,
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(
                        _currentLocation!.latitude!,
                        _currentLocation!.longitude!,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        size: 30,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          Positioned(
            bottom: 100,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  backgroundColor: const Color(0xFFB2DFDB),
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, color: Color(0xFF007EA7)),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  backgroundColor: const Color(0xFFB2DFDB),
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, color: Color(0xFF007EA7)),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'recenter',
                  mini: true,
                  backgroundColor: const Color(0xFFB2DFDB),
                  onPressed: _recenterToUser,
                  child: const Icon(Icons.my_location, color: Color(0xFF007EA7)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _confirmLocation,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB2DFDB),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            "Confirm Location",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF007EA7),
            ),
          ),
        ),
      ),
    );
  }
}
