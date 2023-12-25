import 'package:flutter/material.dart';
import 'package:my_ride/Test/bus_routes.dart';
import 'package:my_ride/UI/HomeMap.dart';

class AllBusRoutesScreen extends StatefulWidget {
  const AllBusRoutesScreen({Key? key}) : super(key: key);

  @override
  _AllBusRoutesScreenState createState() => _AllBusRoutesScreenState();
}

class _AllBusRoutesScreenState extends State<AllBusRoutesScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Bus Routes'),
      ),
      body: FutureBuilder(
        future: _firebaseService.getAllWaypoints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            List<Waypoint>? waypoints = snapshot.data;
            return ListView.builder(
              itemCount: waypoints!.length,
              itemBuilder: (context, index) {
                Waypoint waypoint = waypoints[index];
                return ListTile(
                  title: Text(waypoint.description),
                  subtitle: Text('Latitude: ${waypoint.latitude}, Longitude: ${waypoint.longitude}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
