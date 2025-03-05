/* import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPicker extends StatefulWidget {
  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late GoogleMapController _mapController;
  LatLng _currentPosition = LatLng(0, 0);
  String _currentAddress = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _getAddressFromLatLng(_currentPosition);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    setState(() {
      _currentAddress = "${place.locality}, ${place.country}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 14.0,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('currentLocation'),
                  position: _currentPosition,
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text('Selected Location: $_currentAddress'),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Enter Location Name',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _currentAddress = value;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _currentAddress);
                  },
                  child: Text('Select Location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({Key? key}) : super(key: key);

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late GoogleMapController _mapController;
  LatLng _currentPosition = const LatLng(0, 0);
  String _currentAddress = '';
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check location services
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    // Get current location
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Move camera to current location
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition,
            zoom: 15.0,
          ),
        ),
      );

      await _getAddressFromLatLng(_currentPosition);
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // More detailed address
          _currentAddress = "${place.street}, ${place.locality}, "
              "${place.administrativeArea}, ${place.country}";
          _addressController.text = _currentAddress;
        });
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _currentPosition = position;
    });
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 15.0,
        ),
      ),
    );
    _getAddressFromLatLng(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Tree Location'),
        backgroundColor: const Color(0xFF00C853),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 14.0,
              ),
              onTap: _onMapTap,
              markers: {
                Marker(
                  markerId: const MarkerId('selectedLocation'),
                  position: _currentPosition,
                  draggable: true,
                  onDragEnd: (newPosition) {
                    _onMapTap(newPosition);
                  },
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Location Name',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _currentAddress = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'address': _currentAddress,
                      'latitude': _currentPosition.latitude,
                      'longitude': _currentPosition.longitude,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Confirm Location'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding:
            const EdgeInsets.only(bottom: 80), // Adjust this value as needed
        child: FloatingActionButton(
          onPressed: _getCurrentLocation,
          backgroundColor: const Color(0xFF00C853),
          child: const Icon(Icons.my_location),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
