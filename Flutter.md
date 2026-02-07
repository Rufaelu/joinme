

# 🚀 Flutter Cheat Sheet (Practical)

Flutter = Dart + Widgets

Everything in Flutter is a **widget**.  
UI is built by **nesting widgets inside widgets**.

---

## 🏁 App Entry

```dart
void main() {
  runApp(MyApp());
}
```

---

## 🧱 Basic App Structure

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}
```

---

## 🏠 Scaffold (App Screen Layout)

```dart
Scaffold(
  appBar: AppBar(title: Text("Title")),
  body: Center(child: Text("Hello")),
);
```

Scaffold gives:

* AppBar
* Body
* Floating button
* Drawer
* Bottom nav

---

## 🧩 Most Used Widgets

| Widget        | Purpose             |
| ------------- | ------------------- |
| `Text()`      | Display text        |
| `Container()` | Box with styling    |
| `Row()`       | Horizontal layout   |
| `Column()`    | Vertical layout     |
| `Stack()`     | Overlapping widgets |
| `Center()`    | Center child        |
| `Padding()`   | Space around        |
| `SizedBox()`  | Space / fixed size  |
| `Image()`     | Display image       |
| `ListView()`  | Scrollable list     |
| `GridView()`  | Grid layout         |

---

## 📦 Container Styling

```dart
Container(
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.all(10),
  width: 200,
  height: 100,
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(12),
  ),
);
```

---

## 📏 Row & Column

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text("A"),
    Text("B"),
  ],
);
```

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text("Top"),
    Text("Bottom"),
  ],
);
```

---

## 🧭 Expanded & Flexible

Fill available space.

```dart
Row(
  children: [
    Expanded(child: Container(color: Colors.red)),
    Expanded(child: Container(color: Colors.blue)),
  ],
);
```

---

## 🖼️ Images

```dart
Image.network("https://...");
Image.asset("assets/image.png");
```

---

## 📝 Buttons

```dart
ElevatedButton(
  onPressed: () {},
  child: Text("Click"),
);
```

---

## 🧠 Stateless vs Stateful

### Stateless (no change)

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text("Static");
  }
}
```

### Stateful (changes)

```dart
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("$count"),
        ElevatedButton(
          onPressed: () {
            setState(() {
              count++;
            });
          },
          child: Text("Add"),
        )
      ],
    );
  }
}
```

`setState()` rebuilds UI.

---

## 📜 ListView (dynamic list)

```dart
ListView.builder(
  itemCount: 10,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text("Item $index"),
    );
  },
);
```

---

## 🧭 Navigation

Go to new page:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SecondPage()),
);
```

Go back:

```dart
Navigator.pop(context);
```

---

## 📥 Receiving Data

```dart
class SecondPage extends StatelessWidget {
  final String name;

  SecondPage({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(name);
  }
}
```

---

## 🧾 TextField (Input)

```dart
TextField(
  decoration: InputDecoration(
    labelText: "Enter name",
    border: OutlineInputBorder(),
  ),
);
```

Controller:

```dart
TextEditingController controller = TextEditingController();
```

---

## ⏳ FutureBuilder (Async UI)

```dart
FutureBuilder(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text(snapshot.data.toString());
    } else {
      return CircularProgressIndicator();
    }
  },
);
```

---

## 🎨 Themes

```dart
MaterialApp(
  theme: ThemeData.dark(),
);
```

---

## 🧩 Common Layout Pattern

```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      Text("Title"),
      SizedBox(height: 20),
      ElevatedButton(onPressed: () {}, child: Text("Go")),
    ],
  ),
);
```

---

## 🧠 Flutter Mental Model

You are always doing:

```
Widget(
  property: value,
  child: Widget(
    child: Widget()
  )
)
```

Nested widgets = UI.

---

## ✅ If you understand this file

You can build:

* Login screen
* List screen
* Detail screen
* Navigation
* API data display

You are officially dangerous with Flutter.

```

---

If you want, next I can give you:

**“Build your first Flutter app” step-by-step using ONLY what’s in this sheet** so it locks in permanently.
```
