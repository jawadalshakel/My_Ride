/* import 'package:flutter/material.dart';
import 'package:my_ride/UI/Home.dart';
import 'package:permission_handler/permission_handler.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  int currentPage = 0; // Track the current page

  // Define data for each page
  final List<Map<String, String>> pages = [
    {
      'image': 'assets/images/logo.png',
      'title': 'Welcome',
      'subtitle': 'Embark on a new era of stress-free travel in Jeddah. Here is your go-to solution for seamless public transportation.',
    },
    {
      'image': 'assets/images/location.png', // Change the image path
      'title': 'Location Permission',
      'subtitle': 'Grant location permission to enhance your commuting experience.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Image
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  pages[currentPage]['image']!,
                  height: 240, // Adjust the height for the first image
                ),
              ),
              const SizedBox(
                height: 48,
              ),
              // Title
              Text(
                pages[currentPage]['title']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              // Subtitle
              Text(
                pages[currentPage]['subtitle']!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 24,
              ),
              // Next button
              GestureDetector(
                onTap: () {
                  _handleNextButton();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(25),
                  child: Center(
                    child: Text(
                      currentPage == pages.length - 1 ? 'Allow' : 'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Function to handle the "Next" button press
  void _handleNextButton() {
    setState(() {
      if (currentPage < pages.length - 1) {
        currentPage++;
      } else {
        // Request location permission when pressing "Finish"
        requestLocationPermissionAndNavigate();
      }
    });
  }

  // Function to request location permission
  Future<void> requestLocationPermissionAndNavigate() async {
    var status = await Permission.location.request();

    if (status == PermissionStatus.granted) {
      // Location permission granted, navigate to HomeScreen or perform other actions
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // Handle the case where permission is denied
      // You may want to show a message to the user or handle it accordingly
      print('Location permission denied');
    }
  }
}
 */