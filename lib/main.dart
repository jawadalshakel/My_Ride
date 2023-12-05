// ignore_for_file: prefer_const_constructors
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_ride/Test/Map.dart';
import 'package:my_ride/Test/bus_routes.dart';
import 'package:my_ride/Test/mapRoute.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: //MapRoutesScreen(),
          //mapRoute(),
          MapScreen(),

      //IntroPage()
    );
  }
}
