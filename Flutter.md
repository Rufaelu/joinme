# 🚀 Flutter Cheat Sheet (Practical + Explanations)

Flutter = Dart + Widgets

Everything in Flutter is a widget. UI is built by nesting widgets. Parent widgets configure layout/behavior; children render content.

---

## 🏁 App Entry

```dart
void main() {
  runApp(MyApp()); // Attaches the root widget to the screen
}
```
- main is the Dart entry point.
- runApp takes any Widget (usually a MaterialApp or CupertinoApp tree) and inflates it.

---

## 🧱 Basic App Structure

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Provides Material Design defaults: themes, routing, text styles
      debugShowCheckedModeBanner: false,
      home: HomePage(), // First screen in the app
    );
  }
}
```
- StatelessWidget: immutable configuration; build depends only on inputs.
- MaterialApp: top-level app configuration (theme, routes, locale, etc.).

Tips:
- For iOS look/feel, use Cupertino widgets, but Material works cross‑platform.
- Use routes for structured navigation in non-trivial apps.

---

## 🏠 Scaffold (App Screen Layout)

```dart
Scaffold(
  appBar: AppBar(title: Text("Title")),
  body: Center(child: Text("Hello")),
  floatingActionButton: FloatingActionButton(onPressed: () {}),
  drawer: Drawer(child: Text('Menu')),
  bottomNavigationBar: BottomNavigationBar(items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ]),
);
```
Scaffold provides:
- AppBar: top toolbar.
- Body: main content area.
- FloatingActionButton: circular action button.
- Drawer: slide-in side menu.
- BottomNavigationBar: tabbed navigation.

Tip: Only one Scaffold per “page/screen”. Nesting Scaffolds leads to layout issues.

---

## 🧩 Most Used Widgets (What/Why)

- Text: display a string. Use style for fonts.
- Container: box model (padding, margin, size, decoration). Great for backgrounds/borders.
- Row: horizontal layout; respects mainAxis/crossAxis alignment.
- Column: vertical layout; same alignment concepts as Row.
- Stack: overlap children; position with Positioned.
- Center: centers its child.
- Padding: adds internal spacing around a child.
- SizedBox: adds fixed space or constrains size.
- Image: display assets/network images.
- ListView: scrollable column; efficient for long lists via builder.
- GridView: grid layout, fixed or dynamic extents.

Rule of thumb: if you need spacing, use Padding/SizedBox; if you need decoration/sizing, use Container.

---

## 🧩 Widget Types (with clear examples)

Single-child layout widgets (one direct child):
```dart
// Padding, Align, Center, SizedBox, AspectRatio
Container(
  color: Colors.grey.shade200,
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 120,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(child: Text('16:9 box')),
        ),
      ),
    ),
  ),
)
```
Notes:
- Single-child layout widgets are great for spacing, alignment, or sizing a single element.

Multi-child layout widgets (multiple children):
```dart
// Row & Column
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: const [Text('Left'), Text('Right')],
);

// Wrap (auto-wraps to next line)
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: List.generate(6, (i) => Chip(label: Text('Chip $i'))),
);

// Stack (overlap) + Positioned
Stack(children: [
  Container(height: 120, color: Colors.blue),
  const Positioned(right: 8, bottom: 8, child: Text('Badge')),
]);
```
Notes:
- Use Wrap for tags/chips that need to flow.
- Use Stack when you need to overlay widgets (e.g., a badge over an image).

Display/content widgets:
```dart
// Text, Icon, Image
const Text('Hello', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600));
const Icon(Icons.star, color: Colors.amber, size: 28);
Image.network('https://picsum.photos/200', height: 120, fit: BoxFit.cover);
```

Input + gestures:
```dart
// SwitchListTile (input) + GestureDetector/InkWell (gestures)
bool enabled = true; // inside a State

SwitchListTile(
  title: const Text('Enable feature'),
  value: enabled,
  onChanged: (v) => setState(() => enabled = v),
);

GestureDetector(
  onDoubleTap: () => debugPrint('double tapped'),
  child: const Text('Double tap me'),
);

InkWell(
  onTap: () {},
  borderRadius: BorderRadius.circular(8),
  child: const Padding(
    padding: EdgeInsets.all(12),
    child: Text('Ink ripple on tap'),
  ),
);
```

Feedback/overlays:
```dart
// SnackBar
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Saved')),
);

// Dialog
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Confirm'),
    content: const Text('Proceed?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
    ],
  ),
);
```

Slivers (advanced scrolling):
```dart
CustomScrollView(
  slivers: [
    const SliverAppBar(
      floating: true,
      snap: true,
      title: Text('Feed'),
    ),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ListTile(title: Text('Item $index')),
        childCount: 30,
      ),
    ),
  ],
)
```
Notes:
- Use slivers for fancy/performant scroll effects (pinned headers, grids, etc.).

Context providers (InheritedWidget) — share data down the tree:
```dart
// Minimal InheritedWidget example
class CounterProvider extends InheritedWidget {
  final int count;
  final VoidCallback increment;
  const CounterProvider({
    super.key,
    required this.count,
    required this.increment,
    required super.child,
  });

  static CounterProvider of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CounterProvider>()!;

  @override
  bool updateShouldNotify(CounterProvider old) => old.count != count;
}

class CounterHost extends StatefulWidget {
  const CounterHost({super.key});
  @override
  State<CounterHost> createState() => _CounterHostState();
}

class _CounterHostState extends State<CounterHost> {
  int count = 0;
  @override
  Widget build(BuildContext context) {
    return CounterProvider(
      count: count,
      increment: () => setState(() => count++),
      child: const CounterView(),
    );
  }
}

class CounterView extends StatelessWidget {
  const CounterView({super.key});
  @override
  Widget build(BuildContext context) {
    final p = CounterProvider.of(context);
    return Row(
      children: [
        Text('Count: ${p.count}'),
        const SizedBox(width: 12),
        ElevatedButton(onPressed: p.increment, child: const Text('Add')),
      ],
    );
  }
}
```
Tips:
- In production, prefer Provider/Riverpod for ergonomics; InheritedWidget underpins those patterns.

---

## 📦 Container Styling

```dart
Container(
  padding: EdgeInsets.all(16), // inside the box
  margin: EdgeInsets.all(10),  // outside the box
  width: 200,
  height: 100,
  alignment: Alignment.center, // positions child inside the box
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
  ),
  child: Text('Styled'),
);
```
- Prefer constraints (e.g., Expanded/Flexible) over hard-coded widths when possible.

---

## 📏 Row & Column (Layout Fundamentals)

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween, // along row (horizontal)
  crossAxisAlignment: CrossAxisAlignment.center,     // across row (vertical)
  children: [
    Text("A"),
    Text("B"),
  ],
);
```

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.start, // along column (vertical)
  crossAxisAlignment: CrossAxisAlignment.start, // across column (horizontal)
  children: [
    Text("Top"),
    Text("Bottom"),
  ],
);
```
Notes:
- Row/Column are unconstrained in their main axis by default; they try to be as big as their content unless wrapped with Expanded/Flexible or given constraints from parent.
- Use MainAxisSize.min to size them to their children.

---

## 🧭 Expanded & Flexible (Using Space)

Fill or share available space in Row/Column.

```dart
Row(
  children: [
    Expanded(flex: 1, child: Container(color: Colors.red)),
    Expanded(flex: 2, child: Container(color: Colors.blue)),
  ],
);
```
- Expanded: child gets all remaining space proportionally by flex.
- Flexible: similar, but lets child size itself within the flexed space.
- Don’t use Expanded inside unbounded parents (e.g., inside ListView without constraints) without wrapping with SizedBox or setting shrinkWrap.

---

## 🖼️ Images

```dart
Image.network(
  "https://...",
  fit: BoxFit.cover, // how image fits the box
  loadingBuilder: (c, child, progress) => progress == null
      ? child
      : Center(child: CircularProgressIndicator()),
);

Image.asset(
  "assets/image.png",
  width: 120,
  height: 120,
  fit: BoxFit.contain,
);
```
- Declare assets in pubspec.yaml under flutter -> assets.
- Use caching via CachedNetworkImage for large lists.

---

## 📝 Buttons (Material 3 preferred)

```dart
ElevatedButton(
  onPressed: () {},
  child: Text("Click"),
);

TextButton(onPressed: () {}, child: Text('Text'));
OutlinedButton(onPressed: () {}, child: Text('Outline'));
IconButton(onPressed: () {}, icon: Icon(Icons.favorite));
```
- Disable a button by setting onPressed to null.
- Style via ButtonStyle or theme.

---

## 🧠 Stateless vs Stateful

Stateless (no internal state):
```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text("Static");
  }
}
```

Stateful (holds state that changes UI):
```dart
class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count'),
        ElevatedButton(
          onPressed: () => setState(() => count++), // triggers rebuild
          child: Text('Add'),
        ),
      ],
    );
  }
}
```
- setState marks this State as dirty; Flutter schedules a rebuild of just this subtree.
- Keep build methods fast and pure (no async calls, no heavy work).

---

## 📜 ListView (Dynamic/Scrollable Lists)

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ListTile(
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      onTap: () {},
    );
  },
);
```
- builder lazily builds only visible items.
- For small, fixed lists, use ListView(children: [...]).
- For separators, use ListView.separated.

---

## 🧭 Navigation (Imperative and Named)

Push a new page:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SecondPage()),
);
```
Pop current page:
```dart
Navigator.pop(context);
```
Named routes (recommended for medium+ apps):
```dart
MaterialApp(
  initialRoute: '/',
  routes: {
    '/': (context) => HomePage(),
    '/detail': (context) => DetailPage(),
  },
);

Navigator.pushNamed(context, '/detail');
```
- Pass data via constructors or route arguments.
- On Flutter 3+, consider go_router for declarative routing and deep links.

---

## 📥 Passing/Receiving Data Between Screens

Constructor-based:
```dart
class SecondPage extends StatelessWidget {
  final String name;
  const SecondPage({Key? key, required this.name}) : super(key: key);
  @override
  Widget build(BuildContext context) => Text(name);
}
```

Named route arguments:
```dart
Navigator.pushNamed(
  context,
  '/detail',
  arguments: {'id': 42},
);

// In DetailPage
final args = ModalRoute.of(context)!.settings.arguments as Map;
```

---

## 🧾 TextField (Input)

```dart
final controller = TextEditingController();

TextField(
  controller: controller,
  decoration: InputDecoration(
    labelText: 'Enter name',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.person),
  ),
  keyboardType: TextInputType.text,
  textInputAction: TextInputAction.done,
  onSubmitted: (value) { /* handle */ },
);
```
- Always dispose controllers in State.dispose to prevent leaks.
- For forms/validation, wrap fields with Form and use TextFormField.

---

## ⏳ FutureBuilder and StreamBuilder (Async UI)

Future (one-shot):
```dart
FutureBuilder<String>(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else if (snapshot.hasData) {
      return Text(snapshot.data!);
    } else {
      return SizedBox.shrink();
    }
  },
);
```

Stream (multiple values over time):
```dart
StreamBuilder<int>(
  stream: counterStream(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return Text('Count: ${snapshot.data}');
  },
);
```
Tips:
- Keep async side-effects out of build; trigger them in initState or via callbacks.

---

## 🎨 Themes

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    useMaterial3: true,
    textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16)),
  ),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system, // light/dark based on OS
);
```
- Access theme: Theme.of(context).textTheme, colorScheme, etc.
- Prefer ColorScheme for cohesive colors.

---

## 🧩 Common Layout Pattern

```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, // make children full width
    children: [
      Text('Title', style: Theme.of(context).textTheme.titleLarge),
      SizedBox(height: 20),
      ElevatedButton(onPressed: () {}, child: Text('Go')),
    ],
  ),
);
```
- crossAxisAlignment.stretch helps buttons/inputs fill width in forms.

---

## 🔄 State Management (Starter Options)

- setState: simplest for local widget state.
- InheritedWidget/InheritedModel: pass data down the tree.
- Provider (package:provider): pragmatic, easy, good for medium apps.
- Riverpod/Bloc/Cubit: scalable, testable patterns for larger apps.

Rule: start simple (setState), extract to Provider/Riverpod as state crosses multiple widgets.

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
- The build method is a pure function of state + props -> widget tree.
- Rendering is fast because widgets are lightweight; Flutter diffs configuration and updates render objects efficiently.

---

## 🧰 Productivity Tips

- Hot Reload (r): updates code without losing state; good for UI tweaks.
- Hot Restart (Shift+R): restarts app and state.
- Use const constructors where possible for minor perf gains and fewer rebuilds.
- Wrap text in Flexible/Expanded in rows to prevent overflow.
- Use MediaQuery or LayoutBuilder to adapt to screen size.

---

## ✅ With this you can build

- Login screen (TextFields + Buttons + validation)
- List screen (ListView.builder + async data)
- Detail screen (passing arguments)
- Navigation (Navigator / named routes)
- Themed UI (ThemeData + ColorScheme)

You are officially dangerous with Flutter.
