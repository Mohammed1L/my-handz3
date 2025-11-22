import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:location/location.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _selectedLocation = const LatLng(24.7136, 46.6753); // Default: Riyadh
  GoogleMapController? _mapController;
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
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _selectedLocation, zoom: _zoom),
        ),
      );
    }
  }

  void _onMapTap(LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
    });
  }

  void _confirmLocation() {
    Navigator.pop(context, ll.LatLng(_selectedLocation.latitude, _selectedLocation.longitude));
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
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latlng, zoom: _zoom),
        ),
      );
    }
  }

  void _zoomIn() {
    setState(() => _zoom += 1);
    _mapController?.animateCamera(CameraUpdate.zoomTo(_zoom));
  }

  void _zoomOut() {
    setState(() => _zoom -= 1);
    _mapController?.animateCamera(CameraUpdate.zoomTo(_zoom));
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
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: _zoom),
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
              if (_currentLocation != null)
                Marker(
                  markerId: const MarkerId('me'),
                  position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
            },
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
