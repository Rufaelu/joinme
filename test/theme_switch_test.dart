import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:joinme/theme/app_theme.dart';

class _Switcher extends StatefulWidget {
  const _Switcher();

  @override
  State<_Switcher> createState() => _SwitcherState();
}

class _SwitcherState extends State<_Switcher> {
  bool dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(context),
      darkTheme: AppTheme.dark(context),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => setState(() => dark = !dark),
            child: Text('toggle', style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('switching light ↔ dark animates without errors', (tester) async {
    await tester.pumpWidget(const _Switcher());
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('toggle'));
      // Step through the theme animation frame by frame.
      for (var f = 0; f < 15; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      }
    }
  });
}
