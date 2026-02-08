import 'package:flutter/material.dart';
import 'package:joinme/Map_screen.dart';
import 'package:joinme/Login.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {

  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:Login()
    );
  }
}

