import 'package:flutter/material.dart';
import 'package:joinme/src/Screens/Map_screen.dart';


void main() {
  runApp(const MyApp());
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.yellow[700],
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 221, 0),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.yellow[700],
        scaffoldBackgroundColor:  Colors.transparent,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
        ),
      ),
      themeMode: _themeMode,
      home: Scaffold(
        // No AppBar, use Stack for top widgets
        body: Stack(
          children: [
            // Main map screen
            MapScreen(isDark: isDark),
           
            // Floating theme toggle button at top right
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'themeToggle',
                mini: true,
                backgroundColor: isDark ? Colors.yellow : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                onPressed: _toggleTheme,
                child: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Toggle Theme',
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          height: 62,
          width: 62,
          margin: const EdgeInsets.only(bottom: 1),
          child: FloatingActionButton(
            heroTag: 'mainAdd',
            onPressed: () {},
            shape: const CircleBorder(),
            backgroundColor: isDark ? Colors.yellow[700] : Colors.black,
            foregroundColor: isDark ? Colors.black : Colors.white,
            elevation: 6,
            child: const Icon(Icons.add, size: 32),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          color: Colors.transparent,
          elevation: 0,
          notchMargin: 4.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.map),
                color: isDark ? Colors.yellow[300] : Colors.yellow[800],
                hoverColor: isDark ? Colors.yellow[700] : Colors.blue,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.message_sharp),
                color: isDark ? Colors.white : Colors.black,
                hoverColor: isDark ? Colors.yellow[700] : Colors.blue,
              ),
              const SizedBox(width: 20.0),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications),
                color: isDark ? Colors.white : Colors.black,
                hoverColor: isDark ? Colors.yellow[700] : Colors.blue,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.person_2_rounded),
                color: isDark ? Colors.white : Colors.black,
                hoverColor: isDark ? Colors.yellow[700] : Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



 
 