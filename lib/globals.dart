import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher.dart';

GitHub github = GitHub();
int? remainingApiCalls;
const String errorAPILimit = "API rate limit exceeded";
bool shownFlushbar = false;

const String invalidGitHubURL = "Not a GitHub Repository";
const String cannotBeEmpty = "Cannot be empty";
const String repoDoesNotExist = "Repo does not exist";
const String addToList = "Add to list";
const String cancel = "Cancel";
const String add = "Add";
const String delete = "Delete";
const String closeDialog = "Close";
const String areYouSureDelete = "Are you sure you want to stop checking for updates for ";
const String apiCallsRemainingDesc = "GitHub API calls remaining this hour";
const String apiWarning = "GitHub API limit reached!";
const String addFabTooltip = "Add new app";
const String copiedURLToClipboard = "Copied URL to clipboard";

const String releaseNotes = "Release notes";
const String noReleases = "No releases";
const String noReleaseNotes = "No release notes available";
const String loadingReleaseMarkdown = "Loading release notes...";
const String noDownloads = "No downloads";
const String downloads = "Downloads";
const String noReleaseTag = "";

//From https://stackoverflow.com/a/69299440/8109619
class GlobalContext {
  static GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}

Future<Repository?> getRepository(RepositorySlug repoSlug, {StateSetter? setState}) async {
  try {
    if (canCallApi()) {
      Repository repo = await github.repositories.getRepository(repoSlug);
      updateApiCalls(setState!); //if successful API call, update the number...
      return repo;
    } else {
      throw Exception(errorAPILimit);
    }
  } catch (e) {
    // print(e.toString());
    updateApiCalls(setState!); //...but also when the API call failed, we need to update the number, because it did happen
    if (e.toString().contains(errorAPILimit)) {
      outOfApiCallsWarning();
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
    if (canCallApi()) {
      Release rel = await github.repositories.getLatestRelease(repoSlug);
      updateApiCalls(setState!); //if successful API call, update the number...
      return rel;
    } else {
      throw Exception(errorAPILimit);
    }
  } catch (e) {
    // print(e.toString());
    updateApiCalls(setState!); //...but also when the API call failed, we need to update the number, because it did happen
    if (e.toString().contains(errorAPILimit)) {
      outOfApiCallsWarning();
      rethrow;
    }
    if (e is ReleaseNotFound) {
      rethrow;
    }
  }
  return null;
}

int diff() {
  return github.rateLimitReset!.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
}

bool canCallApi() {
  return github.rateLimitRemaining == null || github.rateLimitRemaining! > 0 || diff() <= 0;
}

void outOfApiCallsWarning() {
  if (github.rateLimitReset != null) {
    Duration timeLeft = Duration(milliseconds: diff());
    if (!shownFlushbar) {
      shownFlushbar = true;
      Flushbar(
        //TODO (high-prio): make global const
        title: apiWarning,
        message: "Try again in ${(timeLeft.inMinutes % 60).toString().padLeft(2, "0")} minutes"
            "\nYou can use an API key to increase the number of API calls you can make per hour.", //TODO (low-prio): Shorten this text (move it into the dialog)
        icon: const Icon(
          Icons.timelapse_rounded,
          size: 28.0,
          color: Colors.orange,
        ),
        duration: const Duration(seconds: 7), //TODO (low-prio): This is too long, but it's just enough for people to read the whole text, so reduce this
        flushbarPosition: FlushbarPosition.TOP,
        animationDuration: const Duration(milliseconds: 300),
        mainButton: ElevatedButton(
          onPressed: () {
            apiDialog();
          },
          child: const Text("API Key"), //TODO (high-prio): make global const
        ),
        isDismissible: false,
        onStatusChanged: (status) {
          if (status == FlushbarStatus.IS_HIDING) {
            shownFlushbar = false;
          }
        },
      ).show(GlobalContext.key.currentContext!);
    }
  }
}

void apiDialog() {
  //TODO (med-prio): Make this dialog look better
  // - Information about what this does
  // - Improve the TextField (error handling, shake, etc)
  // - Add a link to a guide on how to get an API key
  // - Make all the used strings here global const
  TextEditingController textEditingController = TextEditingController();

  Future<void> attemptSubmit() async {
    try {
      print(textEditingController.text);
      GitHub newGitHub = github = GitHub(auth: Authentication.withToken(textEditingController.text));
      Repository repo = await newGitHub.repositories.getRepository(RepositorySlug("TechnicJelle", "GitDroid"));
      print(repo.description);
      print(newGitHub.rateLimitRemaining);
      github = newGitHub;
      //TODO: Update the API calls number in the UI
    } catch (e) {
      print(e.toString());
    }
  }

  showDialog(
    context: GlobalContext.key.currentContext!,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Fill in API key"),
            content: SizedBox(
              width: 600,
              child: TextField(
                controller: textEditingController,
                style: const TextStyle(fontSize: 18),
                onChanged: (value) {
                  print(value);
                },
                onEditingComplete: () {
                  attemptSubmit();
                },
                autofocus: true,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: "api key",
                  errorStyle: TextStyle(fontSize: 13),
                ),
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.text,
                maxLines: 1,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(cancel),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                onPressed: () => attemptSubmit(),
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );
    },
  ).then(
    (value) => {},
  );
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
