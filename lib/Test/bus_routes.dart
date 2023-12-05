import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapRoutesScreen extends StatefulWidget {
  const MapRoutesScreen({Key? key}) : super(key: key);

  @override
  _MapRoutesScreenState createState() => _MapRoutesScreenState();
}

class FirebaseService {
  final CollectionReference _busRoutesCollection = FirebaseFirestore.instance.collection('busRoutes');

  Future<DocumentSnapshot<Object?>> getBusRouteDocument(String documentId) async {
    return await _busRoutesCollection.doc(documentId).get();
  }

  Future<void> addBusRoute(String documentId, double latitude, double longitude, String description) async {
    var routeDoc = await getBusRouteDocument(documentId);

    if (routeDoc.exists) {
      await _busRoutesCollection.doc(documentId).update({
        'waypoints': FieldValue.arrayUnion([
          {
            'latitude': latitude,
            'longitude': longitude,
            'description': description,
          }
        ])
      });
    } else {
      await _busRoutesCollection.doc(documentId).set({
        'waypoints': [
          {
            'latitude': latitude,
            'longitude': longitude,
            'description': description,
          }
        ]
      });
    }
  }
}

class _MapRoutesScreenState extends State<MapRoutesScreen> {
  final TextEditingController documentIdController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Waypoint'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: documentIdController,
              decoration: InputDecoration(labelText: 'Document ID'),
            ),
            TextField(
              controller: latitudeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Latitude'),
            ),
            TextField(
              controller: longitudeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Longitude'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String documentId = documentIdController.text;
                double latitude = double.parse(latitudeController.text);
                double longitude = double.parse(longitudeController.text);
                String description = descriptionController.text;

                _firebaseService.addBusRoute(documentId, latitude, longitude, description);
                _showSnackbar('Waypoint added to Firebase');
              },
              child: Text('Add Waypoint'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
