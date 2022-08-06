import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gitdroid/globals.dart';

import 'release_dialog.dart';
import 'repo_data.dart';

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
        CircleAvatar(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              widget.data.iconUrl.toString(), //if url is wrong, it'll error, making the errorBuilder activate instead, to load a fallback GitHub image
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
                GestureDetector(
                  onLongPress: widget.data.expanded
                      ? () async => {
                            await Clipboard.setData(ClipboardData(text: widget.data.url.toString())),
                            Flushbar(
                              message: copiedURLToClipboard,
                              icon: const Icon(
                                Icons.copy,
                                size: 28.0,
                                color: Colors.blue,
                              ),
                              duration: const Duration(seconds: 3),
                              flushbarPosition: FlushbarPosition.TOP,
                              animationDuration: const Duration(milliseconds: 300),
                            )..show(context),
                          }
                      : null,
                  child: Text(
                    widget.data.expanded ? widget.data.url.toString() : widget.data.ownerName,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
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
                onPressed: () {
                  showRelease(context, widget);
                },
                onLongPress: () {
                  launchURL("", widget.data.releasesUrl.toString(), "");
                }, //just here so it doesn't pop the delete dialog when the button is long pressed
                child: Text(widget.data.releaseTag ?? ""),
              )
            : OutlinedButton(
                onPressed: widget.data.releaseTag == null
                    ? null
                    : () {
                        showRelease(context, widget);
                      },
                onLongPress: () {
                  launchURL("", widget.data.releasesUrl.toString(), "");
                }, //just here so it doesn't pop the delete dialog when the button is long pressed
                child: DefaultTextStyle(
                  //muted colour:
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color), //TODO (low-prio): Find a better solution for this (it fixes the dark/light theme)
                  child: widget.data.releaseTag == null ? const Text(noReleases) : Text(widget.data.releaseTag ?? "this cannot ever happen"),
                ),
              ),
      ],
    );
  }
}
