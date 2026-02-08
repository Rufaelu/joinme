import 'package:flutter/material.dart';

class Login extends StatelessWidget{
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home:Scaffold(
        appBar: AppBar(
          title: Center(
            child: Image.asset('images/JoinMe.png',
            fit: BoxFit.contain,
            height: 74,
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