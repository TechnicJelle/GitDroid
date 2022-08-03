import 'package:flutter/material.dart';
import 'package:github/github.dart';

import 'globals.dart';

class ReleaseAPK {
  final String name;
  final int size;
  final int downloadCount;
  final String browserDownloadUrl;

  ReleaseAPK({required this.name, required this.size, required this.downloadCount, required this.browserDownloadUrl});
}

class RepoData {
  //Inputs
  final RepositorySlug repoSlug;

  //Calculated in constructor
  Uri url; //also updated
  Uri releasesUrl;
  String prettyName; //also updated

  //Updated
  Repository? repo;
  Release? release;
  Uri iconUrl;
  String description;
  bool updateAvailable;

  String? releaseTag;
  String releaseMarkdown;
  List<ReleaseAPK> releaseApkAssets;

  //UI State
  bool expanded = false;

  RepoData(this.repoSlug)
      : url = Uri(scheme: "https", host: "github.com", pathSegments: [repoSlug.owner, repoSlug.name]),
        releasesUrl = Uri(scheme: "https", host: "github.com", pathSegments: [repoSlug.owner, repoSlug.name, "releases"]),
        prettyName = namePrettier(repoSlug.name),
        iconUrl = Uri(),
        description = "",
        updateAvailable = false,
        releaseTag = null,
        releaseMarkdown = loadingReleaseMarkdown,
        releaseApkAssets = [];

  Future<void> checkUpdate({StateSetter? setState, Repository? reuseRepo}) async {
    try {
      //did not get a reuseRepo passed in, so we're getting a new one
      if (reuseRepo == null) {
        repo = await getRepository(repoSlug, setState: setState);
      } else {
        repo = reuseRepo;
      }

      if (repo == null) {
        //Don't reset values if there is no repo to get the values from
        throw RepositoryNotFound;
      }

      setState!(() {
        url = Uri.parse(repo?.htmlUrl ?? url.toString());
        prettyName = namePrettier(repo?.name ?? repoSlug.name);

        iconUrl = Uri.parse(repo?.owner?.avatarUrl ?? "");
        description = repo?.description ?? "";
      });

      try {
        release = await getLatestRelease(repoSlug, setState: setState);

        if (release == null) {
          throw ReleaseNotFound;
        }

        releaseMarkdown = release?.body ?? noReleaseNotes;
        releaseTag = release?.tagName ?? noReleaseNotes;

        // Apk Assets -->
        releaseApkAssets.clear();
        release?.assets?.forEach((ReleaseAsset asset) {
          if (asset.name!.endsWith(".apk")) {
            releaseApkAssets.add(ReleaseAPK(
              name: asset.name ?? "",
              size: asset.size ?? 0,
              downloadCount: asset.downloadCount ?? 0,
              browserDownloadUrl: asset.browserDownloadUrl ?? "",
            ));
          }
        });
        // <-- Apk Assets

        //TODO (med-prio): check if updated release is newer than currently installed version
        setState(() {
          updateAvailable = true;
        });
      } catch (e) {
        if (e is ReleaseNotFound) {
          setState(() {
            updateAvailable = false;
          });
          releaseMarkdown = noReleaseNotes;
          releaseTag = null;
        }
      }
    } catch (e) {
      // print(e.toString());
    }
  }

  void expand() {
    expanded = !expanded;
  }
}
