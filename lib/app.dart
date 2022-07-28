import 'dart:math';

import 'package:flutter/material.dart';

class RepoData {
  final String ownerName;
  final String repoName;
  Uri url;
  String prettyName;
  String description;
  bool updateAvailable;
  bool expanded = false;

  RepoData(this.ownerName, this.repoName)
      : url = Uri.https('github.com', '/$ownerName/$repoName'),
        prettyName = repoName //TODO: Improve pretty name from url extraction
            .replaceAll(RegExp(r'[-_]'), ' ') //replace underscores and dashes with spaces
        ,
        updateAvailable = Random().nextBool(),
        description = "This is a description of the repo";

  void checkUpdate() {
    updateAvailable = Random().nextBool();
  }

  void expand() {
    expanded = !expanded;
  }

  static List<String> extractUserAndRepo(String url) {
    if (url.contains(" ")) return []; //if the url contains a space, it's not a valid url

    //Check if the url is a valid url
    try {
      Uri.parse(url);
    } on FormatException {
      return [];
    }

    List<String> parts = url.split("/"); //split test string on forward slashes
    print(parts);
    int githubIndex = parts.indexWhere((part) => part.contains("github.com")); //find the index of the part that contains github.com
    print(githubIndex);
    if (githubIndex == -1) return []; //if github.com is not found, the url is not valid
    parts.removeRange(0, githubIndex); //remove all the parts before github.com, we don't care about those
    print(parts);
    if (parts.length <= 2) return []; //if there are more than 2 parts, the url is not yet valid
    String ownerName = parts[1]; //get the owner name from the url
    if (ownerName.isEmpty || ownerName.length > 40) return []; //if the owner name is empty or too long, the url is not valid
    String repoName = parts[2]; //get the repo name from the url
    if (repoName.isEmpty || repoName.length > 100) return []; //if the repo name is empty or too long, the url is not valid

    print("$ownerName/$repoName");
    return [ownerName, repoName]; //return true and ownerName and repoName
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
        widget.data.expanded //
            ? const Icon(Icons.arrow_drop_down)
            : const Icon(Icons.arrow_drop_up),
        Expanded(
          child: DefaultTextStyle(
            style: TextStyle(
              overflow: widget.data.expanded ? TextOverflow.visible : TextOverflow.fade,
            ),
            softWrap: widget.data.expanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.prettyName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.data.url.toString(),
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                widget.data.expanded
                    ? Column(
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            widget.data.description,
                            style: const TextStyle(fontSize: 13),
                          )
                        ],
                      )
                    : const SizedBox(width: 0, height: 0),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        widget.data.updateAvailable
            ? const Text(
                "v0.0.1 → v0.0.2",
                style: TextStyle(color: Colors.green),
              )
            : const Text("v0.0.1"),
      ],
    );
  }
}
