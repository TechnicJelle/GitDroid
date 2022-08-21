import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;

import 'globals.dart';
import 'repo_item.dart';

void showRelease(BuildContext context, RepoItem widget) {
  ScrollController scrollController = ScrollController(); //needed for the scrollbar in the assets list

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
              Text(widget.data.releaseTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      child: Stack(
                        children: [
                          const Divider(height: 0, color: Colors.transparent), //just there to make the MarkdownBody the full width of the dialog
                          MarkdownBody(
                            data: widget.data.releaseMarkdown,
                            selectable: true,
                            extensionSet: md.ExtensionSet(md.ExtensionSet.gitHubWeb.blockSyntaxes, md.ExtensionSet.gitHubWeb.inlineSyntaxes),
                            softLineBreak: true,
                            imageBuilder: (uri, title, alt) {
                              return Image.network(
                                uri.toString(),
                                //I tried making it load the image as an SVG, but it didn't work,
                                // so I guess some images just won't be able to load.
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded),
                              );
                            },
                            onTapLink: launchURL,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).textTheme.bodyText1?.color, //TODO (low-prio): Find a better solution for this (it fixes the dark/light theme)
                ),
                child: widget.data.releaseApkAssets.isEmpty //if there are no apk assets, don't show the download button
                    ? const Text(noDownloads)
                    : const Text(downloads),
              ),
              Flexible(
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true, //always show the scrollbar, to hint that there are more items in the list than currently in view
                  child: ListView.separated(
                    controller: scrollController,
                    shrinkWrap: true,
                    itemCount: widget.data.releaseApkAssets.length,
                    separatorBuilder: (context, index) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(widget.data.releaseApkAssets[index].name),
                        trailing: Opacity(
                          opacity: 0.7,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(filesize(widget.data.releaseApkAssets[index].size)),
                              Text.rich(
                                TextSpan(
                                  children: <InlineSpan>[
                                    TextSpan(text: NumberFormat.compact().format(widget.data.releaseApkAssets[index].downloadCount)),
                                    const WidgetSpan(
                                      child: Icon(Icons.download),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text(closeDialog),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
