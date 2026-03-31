import 'package:flutter/material.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: Text("Common Widget"),
          leading: IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.search_outlined)),
            IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_outlined)),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(24.0),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const ContainerBoxDecor(),
                  //const Divider(color: Colors.black), //for column
                  const Padding(padding: EdgeInsets.all(15.0)),
                  const ContainerBoxDecor(),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () {},
                    child: Icon(Icons.airplanemode_on),
                  ),

                  PopUpMenuB(),
                  const Divider(color: Colors.black, height: 10), //for column
                  Image.asset(
                    'assets/images/logo.jpeg',
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),

                  const Divider(color: Colors.black, height: 10), //for column
                  Image.network(
                    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8c2NlbmljfGVufDB8fDB8fHww&w=1000&q=80',
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),

                  const Divider(color: Colors.black, height: 10), //for column
                  TextField(
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 18.0, color: Colors.grey),
                    decoration: InputDecoration(
                      labelText: "UserNAme",
                      hintText: 'Enter Your Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Enter YOur"),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color.fromARGB(255, 54, 243, 196),
          shape: CircleBorder(),
          child: Icon(Icons.file_copy),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          color: const Color.fromARGB(255, 47, 162, 255),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(onPressed: () {}, icon: Icon(Icons.pause)),
              IconButton(onPressed: () {}, icon: Icon(Icons.play_arrow)),
              SizedBox(width: 40.0),
              IconButton(onPressed: () {}, icon: Icon(Icons.stop)),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.access_alarm_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ContainerBoxDecor extends StatelessWidget {
  const ContainerBoxDecor({super.key});
  @override
  Widget build(BuildContext c) {
    // return Placeholder();
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.lightBlue,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(color: Colors.cyan, blurRadius: 2.0, offset: Offset(0, 5)),
        ],
      ),

      child: Center(
        child:
            // Text(
            //   "sup lorem    lorem",
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontSize: 18.0,
            //     fontWeight: FontWeight.w900,
            //     decoration: TextDecoration.overline,
            //     decorationColor: const Color.fromARGB(255, 174, 255, 0),
            //     fontStyle: FontStyle.italic,
            //     letterSpacing: 2.0,
            //     wordSpacing: 3.0,
            //   ),
            //   textAlign: TextAlign.justify,
            // ),
            RichText(
              text: TextSpan(
                text: "sup lorem    lorem",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color.fromARGB(255, 174, 255, 0),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 2.0,
                  wordSpacing: 3.0,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Decoration',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 25, 245, 190),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class ToDoMenuItem {
  late final String title;
  late final Icon icon;
  ToDoMenuItem({required this.title, required this.icon});
}

class PopUpMenuB extends StatelessWidget {
  PopUpMenuB({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: PopupMenuButton<ToDoMenuItem>(
          icon: Icon(Icons.view_list),
          onSelected: ((valueSelected) {
            print('Value Selected: ${valueSelected}');
          }),
          itemBuilder: (BuildContext context) {
            return todo.map((ToDoMenuItem todoitem) {
              return PopupMenuItem<ToDoMenuItem>(
                value: todoitem,
                child: Row(
                  children: [
                    todoitem.icon,
                    SizedBox(width: 10.0),
                    Text(todoitem.title),
                  ],
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

List<ToDoMenuItem> todo = [
  ToDoMenuItem(title: "food", icon: Icon(Icons.fastfood)),
  ToDoMenuItem(title: "Travel", icon: Icon(Icons.travel_explore)),
  ToDoMenuItem(title: "Work", icon: Icon(Icons.work_outline)),
  ToDoMenuItem(title: "Music", icon: Icon(Icons.audiotrack)),
];
