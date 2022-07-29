import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class RepoData {
  //Inputs
  final String ownerName;
  final String repoName;

  //Calculated in constructor
  Uri url;
  String prettyName;

  //Updated
  Uri iconUrl;
  String description;
  bool updateAvailable;

  String releaseMarkdown;
  int releaseApkAssetCount;
  List<String> releaseApkAssets;

  //UI State
  bool expanded = false;

  RepoData(this.ownerName, this.repoName)
      : url = Uri(scheme: "https", host: "github.com", pathSegments: [ownerName, repoName]),
        prettyName = repoName //TODO (low-prio): Improve pretty name from url extraction
            .replaceAll(RegExp(r'[-_]'), ' ') //replace underscores and dashes with spaces
            .replaceAll(RegExp(r'\s+'), ' ') //remove multiple spaces
            .trim(), //trim whitespace
        description = "",
        updateAvailable = false,
        iconUrl = Uri(),
        releaseMarkdown = "Loading...",
        releaseApkAssetCount = 0,
        releaseApkAssets = [] {
    checkUpdate();
  }

  void checkUpdate() {
    //TODO: Get all of this information from the GitHub API
    iconUrl = Uri.https("avatars.githubusercontent.com", "/u/22576047", {'v': "4"});
    description = "This is a description of the repo";
    updateAvailable = Random().nextBool();

    if (updateAvailable) {
      // Release Markdown -->
      set(inp) {
        releaseMarkdown = inp;
      }

      HttpClient()
          .getUrl(Uri.parse("https://raw.githubusercontent.com/TechnicJelle/GitDroid/main/README.md"))
          // .getUrl(Uri.parse("https://raw.githubusercontent.com/TechnicJelle/TechnicJelle/main/README.md"))
          .then((HttpClientRequest request) => request.close())
          .then((HttpClientResponse response) => response.transform(const Utf8Decoder()).listen(set));
      // <-- Release Markdown

      // Apk Assets -->
      releaseApkAssetCount = Random().nextInt(3) + 0;

      releaseApkAssets.clear();
      for (int i = 0; i < releaseApkAssetCount; i++) {
        releaseApkAssets.add("app.apk");
      }
      // <-- Apk Assets
    }
  }

  void expand() {
    expanded = !expanded;
  }

  static List<String> extractUserAndRepo(String url) {
    url = url.trim(); //ignore whitespace before and after
    if (url.contains(" ")) return []; //if the url contains a space, it's not a valid url

    //Check if the url is a valid url
    try {
      Uri.parse(url);
    } on FormatException {
      return [];
    }

    List<String> parts = url.split("/"); //split test string on forward slashes
    int githubIndex = parts.indexWhere((part) => part.contains("github.com")); //find the index of the part that contains github.com
    if (githubIndex == -1) return []; //if github.com is not found, the url is not valid
    parts.removeRange(0, githubIndex); //remove all the parts before github.com, we don't care about those
    if (parts.length <= 2) return []; //if there are more than 2 parts, the url is not yet valid
    String ownerName = parts[1]; //get the owner name from the url
    if (ownerName.isEmpty || ownerName.length > 40) return []; //if the owner name is empty or too long, the url is not valid
    String repoName = parts[2]; //get the repo name from the url
    if (repoName.isEmpty || repoName.length > 100) return []; //if the repo name is empty or too long, the url is not valid

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
  void _showRelease() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).backgroundColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Flexible(
                    child: SingleChildScrollView(
                      child: MarkdownBody(
                        data: widget.data.releaseMarkdown,
                      ),
                    ),
                  ),
                ),
                const Divider(),
                const Text("Downloads", style: TextStyle(fontSize: 24)),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.data.releaseApkAssetCount,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(widget.data.releaseApkAssets[index]),
                      trailing: Opacity(
                        opacity: 0.7,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(NumberFormat.compact().format(Random().nextInt(10000))),
                            const Icon(Icons.file_download),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        widget.data.expanded //
            ? const Icon(Icons.arrow_drop_down)
            : const Icon(Icons.arrow_drop_up),
        CircleAvatar(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              widget.data.iconUrl.toString(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator();
              },
              errorBuilder: (context, error, stackTrace) {
                return const Image(image: AssetImage("assets/github.png"));
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DefaultTextStyle(
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyText1?.color, //TODO (low-prio): Find a better solution for this (it fixes the dark/light theme)
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
            ? ElevatedButton(
                style: TextButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _showRelease,
                onLongPress: () {}, //just here so it doesn't pop the delete dialog when the button is long pressed
                child: const Text("v0.0.1 ➔ v0.0.2"),
              )
            : const Text("v0.0.1"),
      ],
    );
  }
}
