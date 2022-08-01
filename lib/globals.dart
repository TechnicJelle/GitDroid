import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher.dart';

GitHub github = GitHub();
const String errorAPILimit = "API rate limit exceeded";
const String errorRepoNotFound = "Not Found";

Future<Repository?> getRepository(RepositorySlug repoSlug) async {
  try {
    if (github.rateLimitRemaining == 0) {
      throw Exception(errorAPILimit);
    }
    return await github.repositories.getRepository(repoSlug);
  } catch (e) {
    print(e.toString());
    if (e.toString().contains(errorAPILimit)) {
      //TODO: Show this to the user via a snack bar
      //TODO (low-prio): Ask user for API key
      print("API limit reached!! Try again on ${github.rateLimitReset}");
      rethrow;
    }
    if (e.toString().contains(errorRepoNotFound)) {
      rethrow;
    }
  }
  return null;
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
