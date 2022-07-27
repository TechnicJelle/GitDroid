import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gitdroid/stack_overflow_snippets.dart';

class App extends StatefulWidget {
  const App(this.url, {super.key});

  final String url;
  //TODO: Improve pretty name from url extraction
  String get name => url
          .split('/') //splice url on the slashes
          .last //gets the repo name by getting the last part
          .replaceAll(RegExp(r'[-_]'), ' ') //replaces all - and _ in name with spaces
          .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) /* finds camelCase/PascalCase... */ {
        return "${match.group(1)} ${match.group(2)}"; //...and puts a space in between
      }).toTitleCase() //capitalizes every word
      ;

  @override
  State createState() => _AppState();
}

class _AppState extends State<App> {
  bool update = false;

  @override
  void initState() {
    super.initState();
    checkUpdates();
    // print("initState");
  }

  @override
  void didUpdateWidget(App oldWidget) {
    super.didUpdateWidget(oldWidget);
    checkUpdates();
    // print("didUpdateWidget");
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              widget.url,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            )
          ],
        ),
        const Spacer(),
        update
            ? const Text(
                "v0.0.1 → v0.0.2",
                style: TextStyle(color: Colors.green),
              )
            : const Text("v0.0.1")
      ],
    );
  }

  void checkUpdates() {
    setState(() {
      update = Random().nextBool();
      print(update);
    });
  }
}
