import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import HomeScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Nourish',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomeScreen(), // Set HomeScreen as the home of the app
    );
  }
}
