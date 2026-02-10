import 'package:flutter/material.dart';

class Login extends StatelessWidget{
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
            debugShowCheckedModeBanner: false,

      home:Scaffold(
        
        appBar: AppBar(
          title: Center(
            child: Image.asset('images/JoinMe.png',
            fit: BoxFit.contain,
            height: 54,
            width: 67,
            ),

            )


          )
        )
      );
    
  }
}

class LoginForm extends StatelessWidget{
@override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container();
  }
}