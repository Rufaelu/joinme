import 'package:flutter/material.dart';
import 'package:joinme/src/Screens/Map_screen.dart';
import 'package:joinme/src/Screens/Login.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {

  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // home:LoginScreen()
      home:MapScreen()
    );
  }
}

