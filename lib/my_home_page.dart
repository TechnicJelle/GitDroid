import 'package:flutter/material.dart';
import 'package:gitdroid/globals.dart';
import 'package:gitdroid/repo_data.dart';
import 'package:gitdroid/repo_item.dart';
import 'package:github/github.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String thisAppName = "Application";
  List<RepoData> repos = [];

  @override
  void initState() {
    super.initState();
    setAppName();

    //TODO (med-prio): Load repos from app data

    //TODO (low-prio): Make this only happen once, on first launch
    if (repos.isEmpty) {
      addRepo("TechnicJelle", "GitDroid");
    }
  }

  void setAppName() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      thisAppName = packageInfo.appName;
    });
  }

  Future<void> addRepo(String owner, String name) async {
    RepositorySlug repoSlug = RepositorySlug(owner, name);
    RepoData repoData = RepoData(repoSlug);
    try {
      Repository? repo = await getRepository(repoSlug);
      //if didn't trigger an error, add repo to list
      repos.add(repoData);
      repoData.checkUpdate(setState: setState, reuseRepo: repo);
    } catch (e) {
      if (e.toString().contains(errorAPILimit)) {
        //API limit reached, just adding repo to list without checking it
        setState(() {
          repos.add(repoData);
        });
        return;
      }
      rethrow;
    }
  }

  void _addListItem() {
    TextEditingController textEditingController = TextEditingController();
    // ignore: avoid_init_to_null
    String? errorMessage = null; //starts off being valid, to not immediately show the red warning
    Key key = UniqueKey(); //create a unique key for the text field (used by the shaker)
    bool justShook = false; //used to prevent the shaker from clearing the error message if the repo didn't exist

    void validate(List<String> parts) {
      errorMessage = parts.length != 2 ? "Invalid GitHub URL" : null;
      if (textEditingController.text == "") errorMessage = "Cannot be empty"; //when the user presses Enter with no text, the dialog is not valid
    }

    Future<void> add(StateSetter setDialogState) async {
      List<String> input = RepoData.extractUserAndRepo(textEditingController.text);
      setDialogState(() {
        validate(input); //validate the url one more time, just to be 100% sure
      });

      //TODO (med-prio): check if repo is already in repos

      try {
        //if the url is valid
        if (errorMessage == null) {
          await addRepo(input[0], input[1]);

          //close the dialog
          if (!mounted) return;
          Navigator.of(context).pop();
        }
      } catch (e) {
        //the repo didn't exist
        setDialogState(() {
          if (e.toString().contains(errorRepoNotFound)) {
            errorMessage = "Repo does not exist";
          } else {
            errorMessage = "Error: ${e.toString()}";
          }
        });
      }

      //if the repo wasn't added, shake the text field
      setDialogState(() {
        key = UniqueKey(); //make the text field shake
        justShook = true;
      });
    }

    //show dialog with a text input
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add to list"),
              content: SizedBox(
                width: 600,
                child: ShakeWidget(
                  key: key,
                  duration: Duration(milliseconds: errorMessage == null ? 0 : 500),
                  child: TextField(
                    controller: textEditingController,
                    style: const TextStyle(fontSize: 18),
                    onChanged: (value) {
                      setDialogState(() {
                        if (!justShook) {
                          validate(RepoData.extractUserAndRepo(value));
                        }
                        justShook = false;
                      });
                    },
                    onEditingComplete: () {
                      add(setDialogState);
                    },
                    autofocus: true,
                    autofillHints: const [AutofillHints.url],
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: "https://github.com/user/repo",
                      errorText: errorMessage,
                    ),
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.url,
                    maxLines: 1,
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed: () => add(setDialogState),
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onLongPress(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete"),
          // content: Text("Are you sure you want to delete") + Text("${apps[index]}?"),
          content: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyText1?.color, //TODO (low-prio): Find a better solution for this (it fixes the dark/light theme)
              ),
              children: <TextSpan>[
                const TextSpan(text: "Are you sure you want to stop checking for updates for "),
                TextSpan(text: "${repos[index].prettyName}?", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "\n\n${repos[index].url.toString()}", style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () {
                setState(() {
                  repos.removeAt(index);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pullRefresh() async {
    for (RepoData repo in repos) {
      repo.checkUpdate(setState: setState);
    }

    setState(() {
      //sort the repos with the updates at the top (sort alphabetically for the rest)
      repos.sort((RepoData a, RepoData b) {
        if (a.updateAvailable && !b.updateAvailable) return -1;
        if (!a.updateAvailable && b.updateAvailable) return 1;
        return a.prettyName.compareTo(b.prettyName);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called

    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(thisAppName),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addListItem,
        tooltip: "Add new app",
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      body: RefreshIndicator(
        onRefresh: _pullRefresh,
        child: ListView.separated(
          itemCount: repos.length,
          separatorBuilder: (context, index) => const Divider(height: 0),
          itemBuilder: (context, index) => ListTile(
            title: RepoItem(data: repos[index]),
            onTap: () => setState(() {
              repos[index].expand();
            }),
            onLongPress: () => _onLongPress(index),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    );
  }
}
