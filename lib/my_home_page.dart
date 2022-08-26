import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:path_provider/path_provider.dart';

import 'globals.dart';
import 'repo_data.dart';
import 'repo_item.dart';

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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  List<RepoData> repos = [];

  Future<void> saveRepos() async {
    print("Saving repos");
    Directory saveDir = await getApplicationDocumentsDirectory();
    print(saveDir.path);
    File saveFile = File("${saveDir.path}/repos.json");
    print(saveFile.path);
    List<String> repoStrings = repos.map((repo) => repo.repoSlug.toString()).toList();
    await saveFile.writeAsString(json.encode(repoStrings), mode: FileMode.write, flush: true);
    print("Saved repos");
  }

  Future<void> loadRepos() async {
    print("Loading repos");
    Directory saveDir = await getApplicationDocumentsDirectory();
    print(saveDir.path);
    File saveFile = File("${saveDir.path}/repos.json");
    print(saveFile.path);
    if (await saveFile.exists()) {
      String repoStrings = await saveFile.readAsString();
      print(repoStrings);
      List<dynamic> repoStringsList = json.decode(repoStrings);
      print(repoStringsList.runtimeType);
      List<RepoData> repoList = [];
      for (String repoString in repoStringsList) {
        print(repoString);
        String owner = repoString.split("/")[0];
        String name = repoString.split("/")[1];
        RepositorySlug repoSlug = RepositorySlug(owner, name);
        print(repoSlug.toString());
        repoList.add(RepoData(repoSlug));
      }
      setState(() {
        repos = repoList;
      });
      refreshList();
    } else {
      addRepoToList("TechnicJelle", "GitDroid");
    }
    print("Loaded repos");
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    loadRepos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      saveRepos();
    }
  }

  Future<void> addRepoToList(String owner, String name) async {
    RepositorySlug repoSlug = RepositorySlug(owner, name);
    RepoData repoData = RepoData(repoSlug);
    try {
      print("1");
      Repository? repo = await getRepository(repoSlug, setState: setState);
      print("2");
      //if didn't trigger an error, add repo to list
      repos.add(repoData);
      repoData.checkUpdate(setState: setState, reuseRepo: repo);
      print("3");
    } catch (e) {
      print("4  Error: $e");
      if (e.toString().contains(errorAPILimit)) {
        print("5");
        //API limit reached, just adding repo to list without checking it
        setState(() {
          print(repoData.repoSlug.toString());
          repos.add(repoData);
          print("6");
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
      errorMessage = parts.length != 2 ? invalidGitHubURL : null;
      if (textEditingController.text == "") errorMessage = cannotBeEmpty; //when the user presses Enter with no text, the dialog is not valid
    }

    Future<void> attemptAdd(StateSetter setDialogState) async {
      List<String> input = extractUserAndRepo(textEditingController.text);
      setDialogState(() {
        validate(input); //validate the url one more time, just to be 100% sure
      });

      //TODO (med-prio): check if repo is already in repos

      try {
        //if the url is valid
        if (errorMessage == null) {
          await addRepoToList(input[0], input[1]);
          print("7");

          //close the dialog
          if (!mounted) return;
          print("8");
          Navigator.of(context).pop();
          print("9");
        }
      } catch (e) {
        //the repo didn't exist
        // print(e.toString());
        setDialogState(() {
          if (e is RepositoryNotFound) {
            errorMessage = repoDoesNotExist;
          } else {
            errorMessage = "Error: ${e.toString()}"; //hopefully this will never happen
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
              title: const Text(addToList),
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
                          validate(extractUserAndRepo(value));
                        }
                        justShook = false;
                      });
                    },
                    onEditingComplete: () {
                      attemptAdd(setDialogState);
                    },
                    autofocus: true,
                    autofillHints: const [AutofillHints.url],
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: "https://github.com/user/repo",
                      errorText: errorMessage,
                      errorStyle: const TextStyle(fontSize: 13),
                    ),
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.url,
                    maxLines: 1,
                  ),
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
                  onPressed: () => attemptAdd(setDialogState),
                  child: const Text(add),
                ),
              ],
            );
          },
        );
      },
    ).then(
      (value) => {
        updateApiCalls(setState),
      },
    );
  }

  void _onLongPress(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(delete),
          // content: Text("Are you sure you want to delete") + Text("${apps[index]}?"),
          content: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyText1?.color, //TODO (low-prio): Find a better solution for this (it fixes the dark/light theme)
              ),
              children: <TextSpan>[
                const TextSpan(text: areYouSureDelete),
                TextSpan(text: "${repos[index].prettyName}?", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "\n\n${repos[index].url.toString()}", style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
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
              child: const Text(delete),
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

  Future<void> refreshList() async {
    for (RepoData repo in repos) {
      repo.checkUpdate(setState: setState);
    }

    //TODO: (low-prio): wait for all repos to finish checking before reordering the list
    // currently, the list is reordered once all the threads have been started, but not when they're all done, which can take a while
    // this can cause the list to not be in the order it should be in
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
        title: const Text("Git-Droid"),
        actions: [
          IconButton(
            onPressed: () {
              updateApiCalls(setState);
              apiDialog();
            },
            icon: Text(remainingApiCalls == null ? "" : remainingApiCalls.toString()),
            tooltip: apiCallsRemainingDesc,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addListItem,
        tooltip: addFabTooltip,
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      body: RefreshIndicator(
        onRefresh: refreshList,
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
