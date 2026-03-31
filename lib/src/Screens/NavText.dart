import 'package:flutter/material.dart';


class TopBar extends StatelessWidget{
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      
      // color: Colors.transparent,
      
      // padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      // alignment: Alignment.topCenter,
      child:Row(
        mainAxisAlignment: MainAxisAlignment.center,
        
                  children: [
                    const Icon(Icons.pin_drop_rounded, color: Color.fromARGB(255, 196, 113, 113)),
                    const SizedBox(width: 8),
                    Text("JoinMe", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, ),),                  ],
      ));
  }
}