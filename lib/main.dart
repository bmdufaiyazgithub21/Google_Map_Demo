import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async'; // Import this for Timer

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Demo',
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  static final LatLng _center = const LatLng(25.7805898, 84.7048249);
  final Set<Marker> _markers = {};
  LatLng _currentMapPosition = _center;
  bool _isSatelliteView = false;
  String _currentAddress = '';
  TextEditingController _searchController = TextEditingController();

  // Function to handle tap on the map
  void _onMapTapped(LatLng tappedPosition) {
    setState(() {
      // Remove existing marker
      _markers.clear();

      // Add new marker at the tapped position
      _markers.add(Marker(
        markerId: MarkerId(tappedPosition.toString()),
        position: tappedPosition,
        infoWindow: InfoWindow(
          title: 'New Place',
          snippet: 'Welcome to your new location',
        ),
        icon: BitmapDescriptor.defaultMarker,
      ));

      // Move camera to the tapped position
      mapController.animateCamera(CameraUpdate.newLatLng(tappedPosition));

      // Get address details for tapped position
      _getAddress(tappedPosition);
    });
  }

  // Function to get address details using Geocoding API
  Future<void> _getAddress(LatLng position) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks != null && placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        setState(() {
          _currentAddress =
          "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}";
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _onAddMarkerButtonPressed() {
    // Add a new marker at the current map position
    _onMapTapped(_currentMapPosition);
  }

  void _onCameraMove(CameraPosition position) {
    _currentMapPosition = position.target;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _toggleMapType() {
    setState(() {
      _isSatelliteView = !_isSatelliteView;
    });
  }

  // Function to search for the entered location
  void _searchLocation(String searchTerm) async {
    try {
      List<Location> locations = await locationFromAddress(searchTerm);
      if (locations != null && locations.isNotEmpty) {
        Location location = locations[0];
        LatLng searchedPosition = LatLng(location.latitude, location.longitude);
        mapController.animateCamera(CameraUpdate.newLatLng(searchedPosition));
        _onMapTapped(searchedPosition);
      } else {
        print('Location not found');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 15),
        child: AppBar(
          title: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.greenAccent.shade200,
            ),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search location...',
                hintStyle: TextStyle(fontSize: 19),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    String searchTerm = _searchController.text.trim();
                    if (searchTerm.isNotEmpty) {
                      _searchLocation(searchTerm);
                    }
                  },
                ),
              ),
              onFieldSubmitted: (value) {
                _searchLocation(value);
              },
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            onTap: _onMapTapped, // Handle tap on map
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 10.0,
            ),
            markers: _markers,
            onCameraMove: _onCameraMove,
            mapType: _isSatelliteView ? MapType.satellite : MapType.normal,
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                children: [
                  FloatingActionButton(
                    onPressed: _onAddMarkerButtonPressed,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.map, size: 30.0),
                  ),
                  SizedBox(height: 16),
                  FloatingActionButton(
                    onPressed: _toggleMapType,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.layers, size: 30.0),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Current Address: $_currentAddress',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
