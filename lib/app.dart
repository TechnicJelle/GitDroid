import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gitdroid/stack_overflow_snippets.dart';

class RepoData {
  final Uri url;
  String name;
  String description;
  bool update;

  RepoData(this.url)
      :
        //TODO: Improve pretty name from url extraction
        name = url
            .toString()
            .split('/') //splice url on the slashes
            .last //gets the repo name by getting the last part
            .replaceAll(RegExp(r'[-_]'), ' ') //replaces all - and _ in name with spaces
            .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) /* finds camelCase/PascalCase... */ {
          return "${match.group(1)} ${match.group(2)}"; //...and puts a space in between
        }).toTitleCase() //capitalizes every word
        ,
        description = "",
        update = Random().nextBool();

  void checkUpdate() {
    update = Random().nextBool();
  }
}

class RepoItem extends StatefulWidget {
  const RepoItem({
    Key? key,
    required this.data,
  }) : super(key: key);

  final RepoData data;

  @override
  State createState() => _RepoItemState();
}

class _RepoItemState extends State<RepoItem> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.data.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              widget.data.url.toString(),
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            )
          ],
        ),
        const Spacer(),
        widget.data.update
            ? const Text(
                "v0.0.1 → v0.0.2",
                style: TextStyle(color: Colors.green),
              )
            : const Text("v0.0.1")
      ],
    );
  }
}
