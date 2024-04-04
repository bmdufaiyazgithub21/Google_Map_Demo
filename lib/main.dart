import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator package
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler package

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
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    requestLocationPermission();

  }

  // Function to request location permission
  void requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      // Permission granted
    } else if (status.isDenied) {
      // Permission denied
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied
      // Open app settings to allow permission manually
      openAppSettings();
    }
  }

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
      if (placemarks.isNotEmpty) {
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
      if (locations.isNotEmpty) {
        Location location = locations[0];
        LatLng searchedPosition =
        LatLng(location.latitude, location.longitude);
        mapController.animateCamera(CameraUpdate.newLatLng(searchedPosition));
        _onMapTapped(searchedPosition);
      } else {
        print('Location not found');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      print('Current Location: $currentLocation'); // Debug statement
      setState(() {
        _currentMapPosition = currentLocation; // Update current position
        _markers.clear(); // Clear existing markers
        _markers.add(Marker(
          markerId: MarkerId(currentLocation.toString()),
          position: currentLocation,
          infoWindow: InfoWindow(
            title: 'Current Location',
            snippet: 'This is your current location',
          ),
          icon: BitmapDescriptor.defaultMarker,
        ));
      });
      mapController.animateCamera(CameraUpdate.newLatLng(currentLocation));
      _getAddress(currentLocation); // Get address details for current location
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  // Function to update markers
  void _updateMarkers(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId(position.toString()),
        position: position,
        infoWindow: InfoWindow(
          title: 'Current Location',
          snippet: 'This is your current location',
        ),
        icon: BitmapDescriptor.defaultMarker,
      ));
    });
  }




  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      right: false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 20),
          child: Padding(
            padding:
            const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                hintText: 'Search Here...',
                hintStyle: const TextStyle(fontSize: 21),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.location_on_outlined,
                      size: 30, color: Colors.black),
                  onPressed: () {},
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, size: 30, color: Colors.black),
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
        ),
        body: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              onTap: _onMapTapped, // Handle tap on map
              initialCameraPosition: CameraPosition(
                target: _currentMapPosition, // Update initial position here
                zoom: 10.0,
              ),
              markers: _markers,
              onCameraMove: _onCameraMove,
              mapType: _isSatelliteView ? MapType.satellite : MapType.normal,
            ),

            Positioned(
              top: 20,
              right: 20,
              child: Column(
                children: [
                  FloatingActionButton(
                    onPressed: _onAddMarkerButtonPressed,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    child: const CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: 17, // Adjust the radius to control the size of the circle
                      child: Icon(Icons.map, size: 30.0, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    onPressed: _toggleMapType,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    child: const CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: 17, // Adjust the radius to control the size of the circle
                      child: Icon(Icons.layers, size: 30.0, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 111.0, right: 7),
                child: FloatingActionButton(
                  onPressed: _getCurrentLocation, // Get current location
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Current Address: $_currentAddress',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Builder(
          builder: (context) => BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
                // Handle navigation based on index
                switch (index) {
                  case 0:
                  // Navigate to home
                    break;
                  case 1:
                  // Navigate to search
                    break;
                  case 2:
                  // Navigate to profile
                    break;
                  default:
                }
              });
            },
          ),
        ),
      ),
    );
  }
}
