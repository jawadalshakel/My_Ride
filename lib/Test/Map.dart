/* import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_widget/google_maps_widget.dart';
import 'package:my_ride/Test/bus_routes.dart';
import 'package:uuid/uuid.dart';
import 'location_service.dart';
import "package:http/http.dart" as http;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_ride/Test/testt.dart';

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
  final String _apiKey = "AIzaSyC0veARfXrDhY_kcaPEZMvdkZh1jfweNDs";
  late GoogleMapController mapController;
  late Position _currentPosition;
  late String _currentAddress = '';
  final startAddressController = TextEditingController();
  final searchAddressController = TextEditingController();
  String _startAddress = '';
  Set<Marker> markers = {};
  List<Waypoint> busRoute = [];
  Set<Polyline> polylines = {};
  final CameraPosition _initialLocation = const CameraPosition(target: LatLng(0.0, 0.0));
  var uuid = const Uuid();
  String _sessionToken = "22233";
  List<dynamic> _placesList = [];
  final mapsWidgetController = GlobalKey<GoogleMapsWidgetState>();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
    _getBusRouteFromFirebase();
    searchAddressController.addListener(() {
      onChange();
    });
  }

  void onChange() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSuggestion(searchAddressController.text);
  }

  void getSuggestion(String input) async {
    double userLat = _currentPosition.latitude;
    double userLng = _currentPosition.longitude;
    String baseURL = "https://maps.googleapis.com/maps/api/place/autocomplete/json";
    String request = "$baseURL?input=$input&key=$_apiKey&sessiontoken=$_sessionToken&location=$userLat,$userLng&radius=5000";
    var response = await http.get(Uri.parse(request));
    var data = response.body.toString();

    print(data);
    if (response.statusCode == 200) {
      setState(() {
        _placesList = jsonDecode(response.body.toString())["predictions"];
      });
    } else {
      throw Exception("Failed to load data");
    }
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
      _updatePolylines();
    } catch (e) {
      print(e);
    }
  }

  void _getBusRouteFromFirebase() async {
    try {
      DocumentSnapshot<Object?> routeDoc = await _firebaseService.getBusRouteDocument('A7');
      if (routeDoc.exists) {
        List<dynamic> waypoints = routeDoc['waypoints'];
        busRoute = waypoints.map((waypoint) => Waypoint(waypoint['latitude'], waypoint['longitude'], waypoint['description'])).toList();
        _updateMarkers();
        _updatePolylines();
      }
    } catch (e) {
      print(e);
    }
  }

  void _updateMarkers() async {
    markers.clear();

    Uint8List customStartMarker = await getBytesFromCircle(radius: 25);
    Uint8List customFinishMarker = await getBytesFromCircle(radius: 25);
    Uint8List customIntermediateMarker = await getBytesFromCircle(radius: 15);

    List<Marker> newMarkers = [];

    // Add start marker
    newMarkers.add(createMarker(busRoute.first, customStartMarker));

    // Add end marker
    newMarkers.add(createMarker(busRoute.last, customFinishMarker));

    // Add intermediate markers along the polyline
    for (int i = 1; i < busRoute.length - 1; i++) {
      Waypoint waypoint = busRoute[i];
      Marker newMarker = createMarker(waypoint, customIntermediateMarker);
      newMarkers.add(newMarker);
    }

    // Add additional markers along the polyline
    for (int i = 0; i < polylines.length; i++) {
      Polyline polyline = polylines.elementAt(i);

      List<LatLng> points = polyline.points;

      for (int j = 1; j < points.length - 1; j++) {
        Waypoint waypoint = Waypoint(points[j].latitude, points[j].longitude, "Intermediate $j");
        Marker newMarker = createMarker(waypoint, customIntermediateMarker);
        newMarkers.add(newMarker);
      }
    }

    setState(() {
      markers.addAll(newMarkers);
    });
  }

  Marker createMarker(Waypoint waypoint, Uint8List customMarker) {
    return Marker(
      markerId: MarkerId(waypoint.description),
      position: LatLng(waypoint.latitude, waypoint.longitude),
      infoWindow: InfoWindow(
        title: waypoint.description,
      ),
      icon: BitmapDescriptor.fromBytes(customMarker),
      anchor: const Offset(0.5, 0.5), // Center the marker on the coordinates
    );
  }

  void _updatePolylines() async {
    polylines.clear();

    for (int i = 0; i < busRoute.length - 1; i++) {
      Waypoint startPoint = busRoute[i];
      Waypoint endPoint = busRoute[i + 1];

      List<LatLng> segmentPoints = await DirectionsService(_apiKey).getRouteCoordinates(startPoint, endPoint);

      Polyline polyline = Polyline(
        polylineId: PolylineId('route$i'),
        width: 8,
        color: Colors.blue,
        points: segmentPoints,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );

      polylines.add(polyline);
    }

    setState(() {});
  }

  List<LatLng> _getPolylinePoints(Waypoint startPoint, Waypoint endPoint) {
    List<LatLng> polylinePoints = [];

    double fraction = 1.0 / 100; // Adjust this fraction for smoother polylines
    double t = 0.0;

    for (int i = 0; i < 100; i++) {
      double lat = (1 - t) * startPoint.latitude + t * endPoint.latitude;
      double lng = (1 - t) * startPoint.longitude + t * endPoint.longitude;

      polylinePoints.add(LatLng(lat, lng));

      t += fraction;
    }

    return polylinePoints;
  }

  Future<Uint8List> getBytesFromCircle({required double radius}) async {
    final int width = (radius * 2).toInt();

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint fillPaint = Paint()..color = Colors.white;
    final Paint strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(radius, radius), radius, fillPaint);
    canvas.drawCircle(Offset(radius, radius), radius, strokePaint);

    final ui.Image img = await pictureRecorder.endRecording().toImage(width, width);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return data!.buffer.asUint8List();
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
              polylines: polylines,
            ),
            Positioned(
              top: 30,
              left: 12,
              right: 12,
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      TextField(
                        controller: searchAddressController,
                        decoration: InputDecoration(
                          labelText: 'Search Address',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {},
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(8.0),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0.0),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      if (_placesList.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _placesList.length,
                            itemBuilder: (context, index) {
                              final place = _placesList[index];
                              return ListTile(
                                title: Text(place["description"]),
                                onTap: () {
                                  _moveToSuggestion(place);
                                },
                              );
                            },
                          ),
                        )
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

  void _moveToSuggestion(dynamic place) async {
    final selectedPlaceId = place["place_id"];
    String detailsRequest = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$selectedPlaceId&key=$_apiKey";

    var detailsResponse = await http.get(Uri.parse(detailsRequest));
    var detailsData = jsonDecode(detailsResponse.body);

    double lat = detailsData["result"]["geometry"]["location"]["lat"];
    double lng = detailsData["result"]["geometry"]["location"]["lng"];
    String address = detailsData["result"]["formatted_address"];

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 18.0,
        ),
      ),
    );

    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId("selected-location"),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: "Selected Location",
          snippet: address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    setState(() {
      startAddressController.text = address;
      _placesList.clear();
    });
  }
}
 */