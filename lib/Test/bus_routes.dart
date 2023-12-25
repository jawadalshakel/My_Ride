import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:my_ride/UI/HomeMap.dart';

class MapRoutesScreen extends StatefulWidget {
  const MapRoutesScreen({Key? key}) : super(key: key);

  @override
  _MapRoutesScreenState createState() => _MapRoutesScreenState();
}

class FirebaseService {
  Future<List<String>> getAllBusRoutes() async {
    QuerySnapshot<Object?> querySnapshot = await _busRoutesCollection.get();
    List<String> routeIds = querySnapshot.docs.map((doc) => doc.id).toList();
    return routeIds;
  }

  final CollectionReference _busRoutesCollection = FirebaseFirestore.instance.collection('busRoutes');

  Future<DocumentSnapshot<Object?>> getBusRouteDocument(String documentId) async {
    return await _busRoutesCollection.doc(documentId).get();
  }

  Future<void> addBusRoute(String documentId, double latitude, double longitude, String description, Color color) async {
    var routeDoc = await getBusRouteDocument(documentId);

    if (routeDoc.exists) {
      await _busRoutesCollection.doc(documentId).update({
        'waypoints': FieldValue.arrayUnion([
          {
            'latitude': latitude,
            'longitude': longitude,
            'description': description,
          }
        ]),
        'color': '#${color.value.toRadixString(16)}',
      });
    } else {
      await _busRoutesCollection.doc(documentId).set({
        'waypoints': [
          {
            'latitude': latitude,
            'longitude': longitude,
            'description': description,
          }
        ],
        'color': '#${color.value.toRadixString(16)}',
      });
    }
  }

  Future<List<Waypoint>> getAllWaypoints() async {
    List<Waypoint> waypoints = [];

    try {
      QuerySnapshot<Map<String, dynamic>>? snapshot = (await _busRoutesCollection.get()) as QuerySnapshot<Map<String, dynamic>>?;
      for (QueryDocumentSnapshot<Map<String, dynamic>> document in snapshot!.docs) {
        List<dynamic> waypointData = document['waypoints'];
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
    } catch (e) {
      print('Error fetching waypoints: $e');
    }

    return waypoints;
  }

  Future<List<Waypoint>> getClosestBusStops(double userLat, double userLng) async {
    QuerySnapshot<Object?> querySnapshot = await _busRoutesCollection.get();
    List<Waypoint> allWaypoints = [];

    for (var document in querySnapshot.docs) {
      List<dynamic> waypoints = document['waypoints'];
      for (var waypoint in waypoints) {
        double latitude = waypoint['latitude'];
        double longitude = waypoint['longitude'];
        String description = waypoint['description'];
        allWaypoints.add(Waypoint(latitude, longitude, description));
      }
    }

    // Implement logic to find the three closest bus stops based on userLat and userLng
    List<Waypoint> closestBusStops = _findClosestBusStops(userLat, userLng, allWaypoints, 3);

    return closestBusStops;
  }

  List<Waypoint> _findClosestBusStops(double userLat, double userLng, List<Waypoint> waypoints, int count) {
    waypoints.sort((a, b) => _calculateHaversineDistance(userLat, userLng, a.latitude, a.longitude).compareTo(_calculateHaversineDistance(userLat, userLng, b.latitude, b.longitude)));

    return waypoints.take(count).toList();
  }

  Waypoint _findClosestBusStop(double userLat, double userLng, List<Waypoint> allWaypoints) {
    double minDistance = double.infinity;
    Waypoint closestBusStop = allWaypoints.first; // Assuming there is at least one waypoint

    for (var waypoint in allWaypoints) {
      double distance = _calculateHaversineDistance(userLat, userLng, waypoint.latitude, waypoint.longitude);

      if (distance < minDistance) {
        minDistance = distance;
        closestBusStop = waypoint;
      }
    }

    return closestBusStop;
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
}

class _MapRoutesScreenState extends State<MapRoutesScreen> {
  final TextEditingController documentIdController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Color selectedColor = Colors.blue;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Waypoint'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: documentIdController,
              decoration: const InputDecoration(labelText: 'Document ID'),
            ),
            TextField(
              controller: latitudeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            TextField(
              controller: longitudeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Document Color:'),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _openColorPicker();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: selectedColor,
                  ),
                  child: Text('Pick Color'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String documentId = documentIdController.text;
                double latitude = double.parse(latitudeController.text);
                double longitude = double.parse(longitudeController.text);
                String description = descriptionController.text;

                _firebaseService.addBusRoute(documentId, latitude, longitude, description, selectedColor);
                _showSnackbar('Waypoint added to Firebase');
              },
              child: const Text('Add Waypoint'),
            ),
          ],
        ),
      ),
    );
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
