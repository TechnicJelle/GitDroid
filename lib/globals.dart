import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher.dart';

GitHub github = GitHub();
int? remainingApiCalls;
const String errorAPILimit = "API rate limit exceeded";

const String invalidGitHubURL = "Invalid GitHub URL";
const String cannotBeEmpty = "Cannot be empty";
const String repoDoesNotExist = "Repo does not exist";
const String addToList = "Add to list";
const String cancel = "Cancel";
const String add = "Add";
const String delete = "Delete";
const String closeDialog = "Close";
const String areYouSureDelete = "Are you sure you want to stop checking for updates for ";
const String apiCallsRemainingDesc = "GitHub API calls remaining this hour";
const String addFabTooltip = "Add new app";

const String releaseNotes = "Release notes";
const String noReleases = "No releases";
const String noReleaseNotes = "No release notes available";
const String loadingReleaseMarkdown = "Loading release notes...";
const String noDownloads = "No downloads";
const String downloads = "Downloads";
const String noReleaseTag = "";

Future<Repository?> getRepository(RepositorySlug repoSlug, {StateSetter? setState}) async {
  try {
    //TODO (high-prio) when API rate limit exceeded, it gets stuck at the next line
    // possible fix: use the timer in outOfApiCalls() to check if the API rate limit is still exceeded, and if so, throw. if it's not, then proceed to call the API again.
    Repository repo = await github.repositories.getRepository(repoSlug);
    updateApiCalls(setState!);
    if (remainingApiCalls == 0) {
      //TODO (high-prio): upon last allowed API call, this also throws an error, because the API rate limit just was exceeded, while it did succeed
      //possible fix: due to the to do above, this should not be needed anymore
      throw Exception(errorAPILimit);
    }
    return repo;
  } catch (e) {
    // print(e.toString());
    if (e.toString().contains(errorAPILimit)) {
      outOfApiCalls();
      rethrow;
    }
    if (e is RepositoryNotFound) {
      rethrow;
    }
  }
  return null;
}

Future<Release?> getLatestRelease(RepositorySlug repoSlug, {StateSetter? setState}) async {
  try {
    Release rel = await github.repositories.getLatestRelease(repoSlug);
    updateApiCalls(setState!);
    if (remainingApiCalls == 0) {
      throw Exception(errorAPILimit);
    }
    return rel;
  } catch (e) {
    // print(e.toString());
    if (e.toString().contains(errorAPILimit)) {
      outOfApiCalls();
      rethrow;
    }
    if (e is ReleaseNotFound) {
      rethrow;
    }
  }
  return null;
}

Duration? outOfApiCalls() {
  //TODO (low-prio): Show this to the user via a snack bar
  //TODO (low-prio): Ask user for API key
  if (github.rateLimitReset != null) {
    Duration timeLeft = Duration(milliseconds: github.rateLimitReset!.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch);
    print("API limit reached! Try again in "
        "${timeLeft.inHours}:"
        "${(timeLeft.inMinutes % 60).toString().padLeft(2, "0")}:"
        "${(timeLeft.inSeconds % 60).toString().padLeft(2, "0")}");
    return timeLeft;
  }
  return null;
}

void updateApiCalls(StateSetter setState) {
  setState(() {
    remainingApiCalls = github.rateLimitRemaining;
  });
}

Future<void> launchURL(String text, String? href, String title) async {
  if (href == null) {
    return;
  }

  Uri url;
  try {
    url = Uri.parse(href);
  } on FormatException {
    return;
  }

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    return;
  }
}

String namePrettier(String name) {
  return name //TODO (low-prio): Improve pretty name-ification
      .replaceAll(RegExp(r'[-_]'), ' ') //replace underscores and dashes with spaces
      .replaceAll(RegExp(r'\s+'), ' ') //remove multiple spaces
      .trim(); //trim whitespace
}

List<String> extractUserAndRepo(String url) {
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

//From https://stackoverflow.com/a/62212730/8109619
@immutable
class ShakeWidget extends StatelessWidget {
  final Duration duration;
  final double deltaX;
  final Widget child;
  final Curve curve;

  const ShakeWidget({
    required Key key,
    this.duration = const Duration(milliseconds: 500),
    this.deltaX = 20,
    this.curve = Curves.bounceOut,
    required this.child,
  }) : super(key: key);

  /// convert 0-1 to 0-1-0
  double shake(double animation) => 2 * (0.5 - (0.5 - curve.transform(animation)).abs());

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, animation, child) => Transform.translate(
        offset: Offset(deltaX * shake(animation), 0),
        child: child,
      ),
      child: child,
    );
  }
}
