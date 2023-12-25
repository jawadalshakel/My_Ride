// ignore: file_names
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_ride/UI/Home.dart';
import 'package:my_ride/UI/ResetPassword.dart';
import 'package:my_ride/UI/SignUp.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the user's email is verified
      if (userCredential.user?.emailVerified == true) {
        // Navigate to the home screen on successful sign-in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: userCredential.user!), // Pass the user to HomeScreen
          ),
        );
      } else {
        // If email is not verified, show a message
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Email Not Verified'),
              content: const Text('Please verify your email before signing in.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        // Handle invalid email or password
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sign In Failed'),
              content: const Text('Invalid email or password.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Handle other errors
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sign In Failed'),
              content: const Text('Invalid email or password.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _handleContinueWithoutSignIn() async {
    // Navigate to the home screen with the user (either anonymous or the signed-in user)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen(user: null)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //logo
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    "assets/images/logo.png",
                    height: 240,
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                // title
                const Text(
                  "Welcome",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                // sub title
                const Text(
                  "Sign in to your account",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      // Implement your logic for handling "Forgot Password"
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
                      );
                    },
                    child: const Text(
                      'I forgot my password',
                      style: TextStyle(
                        color: Color.fromARGB(255, 25, 93, 148),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                // email text field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                // password text field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                // sign in button
                GestureDetector(
                  onTap: () {
                    _signIn();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900], // Change to your preferred color
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(15),
                    child: const Center(
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                // clickable text for continuing without signing in
                GestureDetector(
                  onTap: () async {
                    // Navigate to the home screen without signing in
                    await _handleContinueWithoutSignIn();
                  },
                  child: const Text(
                    'Continue without signing in',
                    style: TextStyle(
                      color: Color.fromARGB(255, 25, 93, 148),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Don't have an account? Sign up
                RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: const TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.none,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'SignUp',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 25, 93, 148),
                          decoration: TextDecoration.none,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            // Navigate to the sign-up page
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUpPage()),
                            );
                            // Handle the case where the user continues without signing in
                            await _handleContinueWithoutSignIn();
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
