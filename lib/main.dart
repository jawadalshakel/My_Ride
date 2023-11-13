// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:my_ride/Test/Map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
      //IntroPage()
    );
  }
}
