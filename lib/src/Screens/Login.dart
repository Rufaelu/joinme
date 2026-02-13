import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen> {
  // @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 255, 255, 255),

      body: Container(
        margin: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Image.asset(
              'images/JoinMe.png',
              width: 100,
              colorBlendMode: BlendMode.colorBurn,
            ),
            Text('LogIn', style: TextStyle(fontSize: 50, color: Colors.white)),
            textField(),
            passwordField(),
            submitButton(),
          ],
        ),
      ),
    );
  }
}

Widget textField() {
  return TextFormField(
    style: TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: 'Email',
      labelStyle: TextStyle(color: Colors.white),
      hintText: "rufael@gmail.com",
      hintStyle: TextStyle(color: Colors.blueAccent),
    ),
  );
}

Widget passwordField() {
  return Container(
    margin: EdgeInsets.only(bottom: 30),
    child: TextFormField(
      style: TextStyle(color: Colors.white),
      obscureText: true,
      obscuringCharacter: '*',

      decoration: InputDecoration(
        labelStyle: TextStyle(color: Colors.white),

        labelText: 'Password',
      ),
    ),
  );
}

Widget submitButton() {
  return ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // onHover:,
    child: Text('Submit'),
  );
}
