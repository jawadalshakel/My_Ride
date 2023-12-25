import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_widget/google_maps_widget.dart';
import 'package:my_ride/Test/bus_routes.dart';
import 'package:my_ride/Test/location_service.dart';
import 'package:uuid/uuid.dart';
import "package:http/http.dart" as http;

class HomeMap extends StatefulWidget {
  const HomeMap({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class Waypoint {
  final double latitude;
  final double longitude;
  final String description;

  Waypoint(this.latitude, this.longitude, this.description);
}

class WaypointBubble extends StatelessWidget {
  final Waypoint waypoint;
  final double distance;
  final String documentName;
  final Color documentColor;
  final Function onTap; // New onTap parameter

  const WaypointBubble({
    Key? key,
    required this.waypoint,
    required this.distance,
    required this.documentName,
    required this.documentColor,
    required this.onTap, // Include onTap in the constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Wrap with GestureDetector for onTap
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: 20, height: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: documentColor,
                  shape: BoxShape.rectangle,
                ),
                child: Center(
                  child: Text(
                    documentName,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  waypoint.description,
                ),
                const SizedBox(height: 5),
                Text(
                  '${distance.toStringAsFixed(2)} km',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapScreenState extends State<HomeMap> {
  final LocationService _locationService = LocationService();
  final String _apiKey = "";
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
  List<Widget> waypointBubbles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
      _getBusRoutes();
    });
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
    } catch (e) {
      print(e);
    }
  }

  Future<double> _calculateWalkingDistance(double startLat, double startLng, double endLat, double endLng) async {
    final String apiKey = _apiKey;
    final String baseUrl = "https://maps.googleapis.com/maps/api/directions/json";

    final String request = "$baseUrl?origin=$startLat,$startLng&destination=$endLat,$endLng&mode=walking&key=$apiKey";

    final http.Response response = await http.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data["status"] == "OK") {
        final List<dynamic> routes = data["routes"];
        if (routes.isNotEmpty) {
          final Map<String, dynamic> route = routes[0];
          final List<dynamic> legs = route["legs"];
          if (legs.isNotEmpty) {
            final Map<String, dynamic> leg = legs[0];
            final Map<String, dynamic> distance = leg["distance"];
            return distance["value"] / 1000.0; // Convert meters to kilometers
          }
        }
      }
    }
    throw Exception("Failed to calculate walking distance");
  }

  Future<void> _getBusRoutes() async {
    List<String> routeIds = await _firebaseService.getAllBusRoutes();
    List<Waypoint> allWaypoints = [];

    // Create a list to store all the futures
    List<Future<List<Waypoint>>> waypointFutures = [];

    for (var routeId in routeIds) {
      // Add each fetch operation to the list
      waypointFutures.add(_firebaseService.getClosestBusStops(_currentPosition.latitude, _currentPosition.longitude));
    }

    // Wait for all futures to complete
    List<List<Waypoint>> results = await Future.wait(waypointFutures);

    // Flatten the list of lists into a single list
    results.forEach((waypoints) {
      allWaypoints.addAll(waypoints);
    });

    // Process the closest waypoints for all routes as needed
    _updateWaypointBubbles(allWaypoints);
  }

  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // Earth radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = pow(sin(dLat / 2), 2) + cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  Future<void> _updateWaypointBubbles(List<Waypoint> waypoints) async {
    waypoints.sort(
      (a, b) => _calculateHaversineDistance(
        _currentPosition.latitude,
        _currentPosition.longitude,
        a.latitude,
        a.longitude,
      ).compareTo(
        _calculateHaversineDistance(
          _currentPosition.latitude,
          _currentPosition.longitude,
          b.latitude,
          b.longitude,
        ),
      ),
    );

    // Use a set to store unique waypoint coordinates
    Set<String> uniqueWaypoints = Set();

    waypointBubbles.clear();

    for (int i = 0; i < waypoints.length; i++) {
      Waypoint waypoint = waypoints[i];
      double distance = await _calculateWalkingDistance(
        _currentPosition.latitude,
        _currentPosition.longitude,
        waypoint.latitude,
        waypoint.longitude,
      );

      // Fetch document name and color from Firestore
      String documentId = await _getDocumentId(waypoint);
      Color documentColor = await _getDocumentColor(documentId);

      // Create a unique key for the waypoint
      String waypointKey = '${waypoint.latitude}_${waypoint.longitude}';

      // Check if the waypoint is not already present in the bubbles list
      if (!uniqueWaypoints.contains(waypointKey)) {
        uniqueWaypoints.add(waypointKey);
        waypointBubbles.add(
          WaypointBubble(
            waypoint: waypoint,
            distance: distance,
            documentName: documentId,
            documentColor: documentColor,
            onTap: () => _handleWaypointBubbleTap(waypoint, documentColor), // Add onTap here
          ),
        );

        // Break the loop if we have added three unique waypoints
        if (waypointBubbles.length == 3) {
          break;
        }
      }
    }

    setState(() {});
  }

  void _handleWaypointBubbleTap(Waypoint waypoint, documentColor) async {
    double lat = waypoint.latitude;
    double lng = waypoint.longitude;

    // Zoom in on the waypoint location
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 18.0,
        ),
      ),
    );

    // Draw the route
    await _drawRouteToWaypoint(waypoint, documentColor);

    setState(() {
      startAddressController.text = waypoint.description;
      _placesList.clear();
    });
  }

  Future<void> _drawRouteToWaypoint(Waypoint waypoint, Color documentColor) async {
    try {
      // Get the document ID for the selected waypoint
      String documentId = await _getDocumentId(waypoint);

      // Get all waypoints associated with the chosen document
      List<Waypoint> waypoints = await _getWaypointsForDocument(documentId);

      // Create markers for each waypoint
      Set<Marker> waypointMarkers = waypoints.map((w) {
        return Marker(
          markerId: MarkerId("waypoint_${w.latitude}_${w.longitude}"),
          position: LatLng(w.latitude, w.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: w.description),
        );
      }).toSet();

      // Add the selected location marker
      waypointMarkers.add(
        Marker(
          markerId: const MarkerId("selected-location"),
          position: LatLng(waypoint.latitude, waypoint.longitude),
          infoWindow: InfoWindow(title: waypoint.description),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Define the Polyline ID
      PolylineId polylineId = PolylineId("route_to_waypoint_$documentId");

      // Initialize the list of LatLng points for the Polyline
      List<LatLng> polylinePoints = [];

      // Draw the route segment between consecutive waypoints
      for (int i = 0; i < waypoints.length - 1; i++) {
        Waypoint startWaypoint = waypoints[i];
        Waypoint endWaypoint = waypoints[i + 1];

        // Make a Directions API request for driving mode
        List<LatLng> segmentPoints = await _getDrivingRoute(startWaypoint, endWaypoint);

        // Add the segment points to the overall polyline
        polylinePoints.addAll(segmentPoints);
      }

      // Create a Polyline object with the documentColor
      Polyline polyline = Polyline(
        polylineId: polylineId,
        color: documentColor,
        points: polylinePoints,
        width: 5,
      );

      // Clear existing markers and polylines before adding new ones
      markers.clear();
      polylines.clear();

      // Add the new markers and polyline to the state
      setState(() {
        markers.addAll(waypointMarkers);
        polylines.add(polyline);
      });
    } catch (e) {
      print("Error drawing route: $e");
    }
  }

  Future<List<LatLng>> _getDrivingRoute(Waypoint startWaypoint, Waypoint endWaypoint) async {
    // Make a Directions API request for driving mode
    String apiKey = ""; // Replace with your actual API key
    String request = "https://maps.googleapis.com/maps/api/directions/json?origin=${startWaypoint.latitude},${startWaypoint.longitude}&destination=${endWaypoint.latitude},${endWaypoint.longitude}&mode=driving&key=$apiKey";
    var response = await http.get(Uri.parse(request));
    var data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["status"] == "OK") {
      // Extract the encoded polyline points from the response
      return _decodePolyline(data['routes'][0]['overview_polyline']['points']);
    } else {
      print("Error response from Directions API: ${data["status"]}");
      return [];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<List<Waypoint>> _getWaypointsForDocument(String documentId) async {
    try {
      // Replace "busRoutes" with your actual Firestore collection name
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection("busRoutes").doc(documentId).get().then((doc) => FirebaseFirestore.instance.collection("busRoutes").where("waypoints", isEqualTo: doc["waypoints"]).get());

      if (querySnapshot.docs.isNotEmpty) {
        List<Waypoint> waypoints = [];
        for (var doc in querySnapshot.docs) {
          List<dynamic> waypointData = doc['waypoints'];
          waypoints.addAll(
            waypointData.map(
              (waypoint) => Waypoint(
                waypoint['latitude'],
                waypoint['longitude'],
                waypoint['description'],
              ),
            ),
          );
        }
        return waypoints;
      } else {
        // Handle case when document doesn't exist or has no waypoints
        return [];
      }
    } catch (e) {
      // Handle errors
      print("Error fetching waypoints for document: $e");
      return [];
    }
  }

  Future<String> _getDocumentId(Waypoint waypoint) async {
    try {
      // Replace "busRoutes" with your actual Firestore collection name
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance.collection("busRoutes").where("waypoints", arrayContains: {
        "latitude": waypoint.latitude,
        "longitude": waypoint.longitude,
        "description": waypoint.description,
      }).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming the first document in the result set contains the waypoint
        return querySnapshot.docs.first.id;
      } else {
        // Handle case when document doesn't exist
        return "Unknown"; // Default name if document doesn't exist
      }
    } catch (e) {
      // Handle errors
      print("Error retrieving document name: $e");
      return "Unknown"; // Default name in case of error
    }
  }

  Future<Color> _getDocumentColor(String documentId) async {
    try {
      // Replace "busRoutes" with your actual Firestore collection name
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await FirebaseFirestore.instance.collection("busRoutes").doc(documentId).get();

      if (documentSnapshot.exists) {
        // Assuming "color" is a field in your document containing the color code
        String colorCode = documentSnapshot["color"];
        return Color(int.parse(colorCode.replaceAll("#", ""), radix: 16));
      } else {
        // Handle case when document doesn't exist
        return Colors.grey; // Default color if document doesn't exist
      }
    } catch (e) {
      // Handle errors
      print("Error retrieving document color: $e");
      return Colors.grey; // Default color in case of error
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
            // Add the waypoint bubbles display here
            Positioned(
              bottom: 8,
              left: 5,
              right: 5,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Closest Bus Stops',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 5),
                    waypointBubbles.isEmpty
                        ? CircularProgressIndicator() // Loading indicator
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: waypointBubbles,
                            ),
                          ),
                  ],
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
