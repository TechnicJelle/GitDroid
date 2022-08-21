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
  String ownerName; //also updated

  //Updated
  Repository? _repo; //private, do not access outside of this class
  Release? _release; //private, do not access outside of this class
  Uri iconUrl;
  String description;
  bool updateAvailable;

  String? releaseTag;
  String releaseTitle;
  String releaseMarkdown;
  List<ReleaseAPK> releaseApkAssets;

  //UI State
  bool expanded = false;

  RepoData(this.repoSlug)
      : url = Uri(scheme: "https", host: "github.com", pathSegments: [repoSlug.owner, repoSlug.name]),
        releasesUrl = Uri(scheme: "https", host: "github.com", pathSegments: [repoSlug.owner, repoSlug.name, "releases"]),
        prettyName = namePrettier(repoSlug.name),
        ownerName = repoSlug.owner,
        iconUrl = Uri(),
        description = "",
        updateAvailable = false,
        releaseTag = null,
        releaseTitle = releaseNotes,
        releaseMarkdown = loadingReleaseMarkdown,
        releaseApkAssets = [];

  Future<void> checkUpdate({StateSetter? setState, Repository? reuseRepo}) async {
    try {
      //did not get a reuseRepo passed in, so we're getting a new one
      if (reuseRepo == null) {
        _repo = await getRepository(repoSlug, setState: setState);
      } else {
        _repo = reuseRepo;
      }

      if (_repo == null) {
        //Don't reset values if there is no repo to get the values from
        throw RepositoryNotFound;
      }

      setState!(() {
        url = Uri.parse(_repo?.htmlUrl ?? url.toString());
        prettyName = namePrettier(_repo?.name ?? repoSlug.name);
        ownerName = _repo?.owner?.login ?? repoSlug.owner;

        iconUrl = Uri.parse(_repo?.owner?.avatarUrl ?? "");
        description = _repo?.description ?? "";
      });

      try {
        _release = await getLatestRelease(repoSlug, setState: setState);

        if (_release == null) {
          throw ReleaseNotFound;
        }

        releaseTag = _release?.tagName ?? noReleaseNotes;
        releaseTitle = _release?.name ?? releaseNotes;
        releaseMarkdown = _release?.body ?? noReleaseNotes;

        // Apk Assets -->
        releaseApkAssets.clear();
        _release?.assets?.forEach((ReleaseAsset asset) {
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
