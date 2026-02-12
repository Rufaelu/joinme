import 'package:flutter/material.dart';

class Login extends StatelessWidget{
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
            debugShowCheckedModeBanner: false,

      home:Scaffold(
        
        appBar: AppBar(
          toolbarHeight: 200,
          // backgroundColor: Colors.red,
          title: Center(
            child: Image.asset('images/JoinMe.png',
            // colorBlendMode: BlendMode.difference,
            fit: BoxFit.contain,
            height: 144,
            width: 137,
            ),
            )

          ),
          body: Placeholder(
            color: const Color.fromARGB(255, 126, 81, 81),),

            
        )
      );
    
  }
}




