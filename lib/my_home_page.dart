import "package:flutter/material.dart";
import "package:gitdroid/app.dart";
import 'package:gitdroid/stack_overflow_snippets.dart';
import "package:package_info_plus/package_info_plus.dart";

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
  List<App> apps = [];

  @override
  void initState() {
    super.initState();
    setAppName();
  }

  void setAppName() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      thisAppName = packageInfo.appName;
    });
  }

  void _addListItem() {
    TextEditingController textEditingController = TextEditingController();
    String text = "";
    bool valid = true;
    Key key = UniqueKey();

    void add(StateSetter setDialogState) {
      if (text == "") valid = false;

      if (!valid) {
        setDialogState(() {
          key = UniqueKey();
          textEditingController.text = text;
        });
        return;
      }

      setState(() {
        apps.add(App(text));
      });
      Navigator.of(context).pop();
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
                  duration: Duration(milliseconds: valid ? 0 : 500),
                  child: TextField(
                    controller: textEditingController,
                    style: const TextStyle(fontSize: 18),
                    onChanged: (value) {
                      text = value;
                      setDialogState(() {
                        //TODO: Improve url validation
                        valid = text.contains("github.com/");
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
                      errorText: valid ? null : "Invalid GitHub URL",
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
              children: <TextSpan>[
                const TextSpan(text: "Are you sure you want to stop checking for updates for "),
                TextSpan(text: "${apps[index].name}?\n\n${apps[index].url}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  apps.removeAt(index);
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
    setState(() {
      for (int i = 0; i < apps.length; i++) {
        apps[i] = App(apps[i].url); //TODO: I find this very cursed, but in my hours of despair I couldn't find a better way to do this. Please help.
      }
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
        child: ListView.builder(
          itemCount: apps.length * 2,
          itemBuilder: (context, i) {
            //if i is odd, there's a divider with no padding
            if (i.isOdd) {
              return const Divider(
                height: 0,
              );
            }

            final index = i ~/ 2;

            return ListTile(
              title: apps[index],
              onLongPress: () => _onLongPress(index),
              // onTap: () => apps[index].checkUpdates(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            );
          },
        ),
      ),
    );
  }
}
