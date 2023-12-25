/* import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_routes/google_maps_routes.dart';

class GoogleMapControllerExtension {
  final Set<Polyline> _polylines = {};

  void clearPolylines() {
    _polylines.clear();
  }

  void addPolylines(Set<Polyline> polylines) {
    _polylines.addAll(polylines);
  }

  // Additional methods to get or remove specific polylines if needed
  // ...

  // Your other methods or properties for GoogleMapController
  // ...
}

class MapsRoutes {
  Set<Polyline> routes = {};

  Future<Set<Polyline>> drawRoute(List<LatLng> points, String routeName, Color routeColor, String googleApiKey, {TravelModes? travelMode}) async {
    // Your existing implementation for drawing the route

    // Assuming routes is updated internally
    routes.clear();
    // ... Add polylines to routes based on points, routeName, routeColor, googleApiKey, and travelMode

    return routes;
  }
}

class mapRoute extends StatefulWidget {
  const mapRoute({Key? key}) : super(key: key);

  @override
  State<mapRoute> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<mapRoute> {
  final Completer<GoogleMapController> _controller = Completer();
  final GoogleMapControllerExtension _extendedController = GoogleMapControllerExtension();

  List<LatLng> points = [
    const LatLng(21.481979, 39.181153),
    const LatLng(21.500737, 39.184508),
    const LatLng(21.521499, 39.181972),
    const LatLng(21.541393, 39.177118),
    const LatLng(21.560556, 39.172506),
    const LatLng(21.558749, 39.149869),
    const LatLng(21.551499, 39.134270),
  ];

  MapsRoutes route = MapsRoutes();
  DistanceCalculator distanceCalculator = DistanceCalculator();
  String googleApiKey = '';
  String totalDistance = 'No route';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: GoogleMap(
              zoomControlsEnabled: false,
              polylines: _extendedController._polylines,
              initialCameraPosition: const CameraPosition(
                zoom: 15.0,
                target: LatLng(21.481979, 39.181153),
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(totalDistance, style: const TextStyle(fontSize: 25.0)),
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Set<Polyline> polylines = await route.drawRoute(
            points,
            'Test routes',
            const Color.fromRGBO(130, 78, 210, 1.0),
            googleApiKey,
            travelMode: TravelModes.driving,
          );

          _extendedController.clearPolylines(); // Clear existing polylines
          _extendedController.addPolylines(polylines);

          setState(() {
            totalDistance = distanceCalculator.calculateRouteDistance(points, decimals: 1);
          });
        },
      ),
    );
  }
}
 */
