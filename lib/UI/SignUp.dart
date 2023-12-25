// ignore_for_file: prefer_const_constructors, unnecessary_const

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_ride/UI/SignIn.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _errorText = '';
  bool _accountCreated = false;

  Future<void> _createAccount(String name, String email, String password, String confirmPassword) async {
    try {
      if (password != confirmPassword) {
        _setError('Passwords do not match.');
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.sendEmailVerification();

      // Save the user's name to Firebase
      await userCredential.user!.updateDisplayName(name);

      // Show a success message
      await _showSuccessMessage();

      setState(() {
        _accountCreated = true;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _setError('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        _setError('The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        _setError('Please write a correct email');
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setError(String error) {
    setState(() {
      _errorText = error;
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _errorText = '';
        });
      });
    });
  }

  Future<void> _showSuccessMessage() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Account Created'),
          content: Text('Please check your email to activate the account'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(SignInPage);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //logo
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          "assets/images/logo.png",
                          height: 200,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      // title
                      const Text(
                        "Create your account",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      // name text field
                      SizedBox(
                        width: double.infinity,
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      // email text field
                      SizedBox(
                        width: double.infinity,
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      // Password
                      SizedBox(
                        width: double.infinity,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      // Re-enter password text field
                      SizedBox(
                        width: double.infinity,
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Re-enter Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      // Error message
                      if (_errorText.isNotEmpty)
                        Text(
                          _errorText,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(
                        height: 8,
                      ),
                      // Success message
                      if (_accountCreated)
                        Text(
                          'Account created successfully!',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      const SizedBox(
                        height: 8,
                      ),
                      // create now button
                      GestureDetector(
                        onTap: () {
                          _createAccount(_nameController.text, _emailController.text, _passwordController.text, _confirmPasswordController.text);
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[900], // Change to your preferred color
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(15),
                          child: const Center(
                            child: const Text(
                              "Create now",
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
                        height: 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
