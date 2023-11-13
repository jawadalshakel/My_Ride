import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class Waypoint {
  final double latitude;
  final double longitude;
  final String description;

  Waypoint(this.latitude, this.longitude, this.description);
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  late GoogleMapController mapController;
  late Position _currentPosition;
  late String _currentAddress = '';
  final startAddressController = TextEditingController();
  final searchAddressController = TextEditingController();
  String _startAddress = '';
  Set<Marker> markers = {};
  List<Waypoint> busRoute = [];
  final CameraPosition _initialLocation = const CameraPosition(target: LatLng(0.0, 0.0));

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializeBusRoute();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await _locationService.getCurrentLocation();
      _getAddress();
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition.latitude, _currentPosition.longitude),
            zoom: 18.0,
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getAddress() async {
    try {
      _currentAddress = await _locationService.getAddress(_currentPosition);
      setState(() {
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
      _updateMarkers();
    } catch (e) {
      print(e);
    }
  }

  void _initializeBusRoute() {
    // Replace these coordinates with the actual coordinates of your bus stops
    busRoute = [
      Waypoint(37.7749, -122.4194, 'Start Point'),
      Waypoint(37.7761, -122.4182, 'Stop 1'),
      Waypoint(37.7783, -122.4159, 'Stop 2'),
      Waypoint(37.7799, -122.4146, 'Stop 3'),
      Waypoint(37.7816, -122.4125, 'Stop 4'),
      Waypoint(37.7839, -122.4104, 'Finish Point'),
    ];
  }

  void _updateMarkers() {
    markers.clear();
    double startLatitude = _currentPosition.latitude;
    double startLongitude = _currentPosition.longitude;

    Marker startMarker = Marker(
      markerId: const MarkerId('start'),
      position: LatLng(startLatitude, startLongitude),
      infoWindow: InfoWindow(
        title: 'Start',
        snippet: _startAddress,
      ),
      icon: BitmapDescriptor.defaultMarker,
    );

    markers.add(startMarker);

    for (var waypoint in busRoute) {
      Marker busStopMarker = Marker(
        markerId: MarkerId(waypoint.description),
        position: LatLng(waypoint.latitude, waypoint.longitude),
        infoWindow: InfoWindow(
          title: waypoint.description,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      markers.add(busStopMarker);
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              markers: markers,
            ),
            Positioned(
              top: 30,
              left: 12,
              right: 12,
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: searchAddressController,
                        decoration: InputDecoration(
                          labelText: 'Search Address',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              // Handle search logic here
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: startAddressController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Start Address',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 12,
              child: ClipOval(
                child: Material(
                  color: Colors.orange.shade100,
                  child: InkWell(
                    splashColor: Colors.orange,
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.my_location),
                    ),
                    onTap: () {
                      _getCurrentLocation();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
