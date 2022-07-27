import 'package:flutter/material.dart';

import 'my_home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.light()
            .copyWith(primary: Colors.blue, secondary: Colors.lightBlueAccent),
      ),
      darkTheme: ThemeData(
          colorScheme: const ColorScheme.dark().copyWith(
              primary: Colors.blue, secondary: Colors.lightBlueAccent),
          appBarTheme: const AppBarTheme(
            color: Colors.blue,
          )),
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

