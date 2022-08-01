import 'package:flutter/material.dart';
import 'package:gitdroid/globals.dart';
import 'package:github/github.dart';

class ReleaseAsset {
  final String name;
  final int size;
  final int downloadCount;
  final String browserDownloadUrl;

  ReleaseAsset({required this.name, required this.size, required this.downloadCount, required this.browserDownloadUrl});
}

class RepoData {
  //Inputs
  final RepositorySlug repoSlug;

  //Calculated in constructor
  Uri url;
  String prettyName;

  //Updated
  Repository? repo;
  Uri iconUrl;
  String description;
  bool updateAvailable;

  String releaseMarkdown;
  int releaseApkAssetCount;
  List<ReleaseAsset> releaseApkAssets;

  //UI State
  bool expanded = false;

  RepoData(this.repoSlug)
      : url = Uri(scheme: "https", host: "github.com", pathSegments: [repoSlug.owner, repoSlug.name]),
        prettyName = repoSlug.name //TODO (low-prio): Improve pretty name-ification
            .replaceAll(RegExp(r'[-_]'), ' ') //replace underscores and dashes with spaces
            .replaceAll(RegExp(r'\s+'), ' ') //remove multiple spaces
            .trim(), //trim whitespace
        iconUrl = Uri(),
        description = "",
        updateAvailable = false,
        releaseMarkdown = "Loading...",
        releaseApkAssetCount = 0,
        releaseApkAssets = [];

  Future<void> checkUpdate({StateSetter? setState, Repository? reuseRepo}) async {
    try {
      //did not get a reuseRepo passed in, so we're getting a new one
      if (reuseRepo == null) {
        repo = await getRepository(repoSlug);
      } else {
        repo = reuseRepo;
      }

      setState!(() {
        iconUrl = Uri.parse(repo?.owner?.avatarUrl ?? "");
        description = repo?.description ?? "";
        updateAvailable = true; //TODO (med-prio): actually check if update is available
      });

      //TODO (high-prio): Turn this back on and fix it up, integrate fully with API
      // github.repositories.listReleases(repoSlug).last.then((release) {
      //   print("$prettyName | ${release.tagName}");
      //
      //   // Release Markdown -->
      //   releaseMarkdown = release.body ?? "No release notes";
      //   // <-- Release Markdown
      //
      //   // Apk Assets -->
      //   releaseApkAssetCount = Random().nextInt(3) + 0;
      //
      //   releaseApkAssets.clear();
      //   for (int i = 0; i < releaseApkAssetCount; i++) {
      //     releaseApkAssets.add(ReleaseAsset(
      //       name: "app.apk",
      //       size: Random().nextInt(10000),
      //       downloadCount: Random().nextInt(10000),
      //       browserDownloadUrl: "",
      //     ));
      //   }
      //   // <-- Apk Assets
      // });
    } catch (e) {
      print(e.toString());
    }
  }

  void expand() {
    expanded = !expanded;
  }

  static List<String> extractUserAndRepo(String url) {
    url = url.trim().toLowerCase(); //ignore whitespace before and after and ignore the casing
    if (url.contains(" ")) return []; //if the url contains a space, it's not a valid url

    //if the url contains only one slash and not github.com, it's a quick user/repo url
    if ("/".allMatches(url).length == 1 && !url.contains("github.com")) {
      List<String> parts = url.split("/");
      if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return parts;
      }
    }

    //check if the url is a valid url
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
