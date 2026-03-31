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
      
      home:Scaffold(
       
        body:MapScreen(),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(onPressed: (){},
        shape: CircleBorder(),
         child:Icon(Icons.add)),
        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          color: Colors.black,
          child:Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        IconButton(onPressed: (){}, icon: Icon(Icons.map), color:Color.fromARGB(255, 255, 211, 17), hoverColor: Colors.blue,),
        IconButton(onPressed: (){}, icon: Icon(Icons.message_sharp), color:Colors.white,
                hoverColor: Colors.blue,
              ),

        SizedBox(width: 20.0,),
        IconButton(onPressed: (){}, icon: Icon(Icons.notifications),
                color: Colors.white, hoverColor: Colors.blue,
              ),
        IconButton(onPressed: (){}, icon: Icon(Icons.person_2_rounded),
                color: Colors.white,
                hoverColor: Colors.blue,
              ),
        ],) 
        ),
      )
      // home:MapScreen(),
      
    );
  }
} 



 
 