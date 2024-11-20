import 'package:flutter/material.dart';
import 'package:one_zero/appProviders.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SetiingsPage extends StatefulWidget {
  final String academic_year;
  const SetiingsPage({Key? key, required this.academic_year}) : super(key: key);

  @override
  _SetiingsPageState createState() => _SetiingsPageState();
}

class _SetiingsPageState extends State<SetiingsPage> {
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final FocusNode subjectFocusNode = FocusNode();
  bool _autoSync = false;
  bool _isDarkMode = false;

  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _autoSync = prefs.getBool('autoSync') ?? false;
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      setState(() {});
    });
    // Request focus when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (classNameController.text.isNotEmpty) {
        subjectFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    classNameController.dispose();
    subjectController.dispose();
    // subjectFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildSettings(context);
  }

  Widget buildSettings(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Consumer<UserCoice>(builder: (context, userChoice, child) {
          return Container(
            width: MediaQuery.of(context).size.width * .9,
            child: Center(
              child: Container(
                width: 650,
                height: 1000,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 35, vertical: 8),
                        child: Text(
                          "Appearance",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                    ),
                    Container(
                      width: 600,
                      height: 100,
                      // decoration: BoxDecoration(
                      //   color: Theme.of(context).cardColor,
                      //   border: Border.all(color: Colors.grey, width: 1),
                      //   borderRadius: BorderRadius.all(Radius.circular(4)),
                      // ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: IconButton(
                                  icon: _isDarkMode
                                      ? const Icon(Icons.wb_sunny)
                                      : const Icon(Icons.nightlight_round),
                                  tooltip: _isDarkMode ? "Light" : "Dark",
                                  onPressed: () {
                                    setState(() {
                                      _isDarkMode = !_isDarkMode;
                                      SharedPreferences.getInstance()
                                          .then((prefs) {
                                        prefs.setBool(
                                            'isDarkMode', _isDarkMode);
                                      });
                                      userChoice.toggleDarkMode();
                                    });
                                  },
                                ),
                              ),
                              Text(_isDarkMode ? "Light Mode" : "Dark Mode",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(
                      color: Colors.grey,
                      thickness: 5,
                    ),
                    // Second Section: New Class
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 35, vertical: 8),
                        child: Text(
                          "New Class",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                    ),
                    createClassPopup(context),
                    const SizedBox(height: 20),
                    const Divider(
                      color: Colors.grey,
                      thickness: 5,
                    ),

                    // Third Section: Backup
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 35, vertical: 8),
                        child: Text(
                          "Backup",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                    ),
                    Container(
                      width: 600,
                      height: 100,
                      // decoration: BoxDecoration(
                      //   color: Theme.of(context).cardColor,
                      //   border: Border.all(color: Colors.grey, width: 1),
                      //   borderRadius: BorderRadius.all(Radius.circular(4)),
                      // ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Switch(
                                  // This bool value toggles the switch.
                                  value: _autoSync,
                                  activeColor: Colors.green,
                                  onChanged: (bool value) {
                                    // This is called when the user toggles the switch.
                                    setState(() {
                                      _autoSync = value;
                                      SharedPreferences.getInstance()
                                          .then((prefs) {
                                        prefs.setBool('autoSync', value);
                                      });
                                    });
                                  },
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("Auto Sync"),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget createClassPopup(BuildContext context) {
    return Container(
      width: 600,
      height: 430,
      padding: const EdgeInsets.all(20),
      // decoration: BoxDecoration(
      //   color: Theme.of(context).cardColor,
      //   border: Border.all(color: Colors.grey, width: 1),
      //   borderRadius: const BorderRadius.all(Radius.circular(4)),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            width: 250,
            child: TextField(
              controller: classNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Class Name',
              ),
              onSubmitted: (value) => subjectFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "Subjects",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 columns
                childAspectRatio: 3 / 1, // Adjust aspect ratio for tile size
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _subjects.length + 1, // +1 for the text input
              itemBuilder: (context, index) {
                if (index < _subjects.length) {
                  // Regular subject tiles
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          _subjects[index],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                } else {
                  // TextField input tile
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: subjectController,
                      focusNode: subjectFocusNode,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'New',
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                        border: InputBorder.none,
                      ),
                      canRequestFocus: true,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _subjects.add(value);
                            subjectController.clear();
                            subjectFocusNode.requestFocus();
                          });
                          // Retain focus on TextField
                        }
                      },
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomButton(
                text: 'Save',
                onPressed: () {
                  if (classNameController.text.isEmpty || _subjects.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Class name cannot be empty ${classNameController.text}  ${_subjects.length}   '),
                      ),
                    );
                    return;
                  } else {
                    saveClass(classNameController.text, widget.academic_year,
                        _subjects);
                  }
                },
                width: 100,
                height: 40,
                textColor: Colors.white,
              )
            ],
          ),
        ],
      ),
    );
  }

  void saveClass(
      String className, String academic_year, List<String> newSubjects) async {
    var dbHelper = DatabaseHelper();
    String newClassID = const Uuid().v4();
    int check1 = 0;
    int check2 = 0;
    int check3 = 0;
    int check4 = 0;

    Map<String, dynamic> classData = {
      'id': newClassID,
      'class_name': className,
      'academic_year': academic_year,
      'section': 'New',
    };

    check1 = await dbHelper.insertToTable('class_table', classData);

    String streamID = const Uuid().v4();
    Map<String, dynamic> streamData = {
      'id': streamID,
      'stream_name': className,
      'class_id': newClassID,
    };
    check3 = await dbHelper.insertToTable('stream_table', streamData);
    for (var subject in newSubjects) {
      String subjectID = const Uuid().v4();
      Map<String, dynamic> subjectData = {
        'id': subjectID,
        'subject_name': subject,
        'class_id': newClassID,
      };

      check2 = await dbHelper.insertToTable('subject_table', subjectData);

      if (check2 != 0) {
        Map<String, dynamic> StreamSubjectData = {
          'id': subjectID,
          'stream_id': streamID,
          'subject_id': subjectID,
        };

        check4 = await dbHelper.insertToTable(
            'stream_subjects_table', StreamSubjectData);
      }
    }

    if (check1 != 0 && check2 != 0 && check3 != 0 && check4 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Class created successfully'),
        ),
      );
      classNameController.clear();
      _subjects.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to create class'),
        ),
      );
    }
  }
}
