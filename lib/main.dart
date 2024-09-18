import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/results_page.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/dataEntry.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  // Initialize the FFI
  sqfliteFfiInit();

  // Set the database factory
  databaseFactory = databaseFactoryFfi;

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One-Zero SMS',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: isDarkMode
            ? Color.fromARGB(255, 2, 47, 22)
            : Color.fromARGB(255, 45, 205, 114),
        secondaryHeaderColor: isDarkMode
            ? Color.fromRGBO(238, 108, 77, 1)
            : Color.fromRGBO(238, 108, 77, 1),
        scaffoldBackgroundColor:
            isDarkMode ? Colors.grey[850] : Colors.grey[200],
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        canvasColor: isDarkMode ? Colors.grey[850] : Colors.grey[200],
        primaryTextTheme: TextTheme(
          bodyMedium: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      home: MyHomePage(
        onThemeChanged: (bool value) {
          setState(() {
            isDarkMode = value;
          });
        },
        isDarkMode: isDarkMode,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  MyHomePage({required this.onThemeChanged, required this.isDarkMode});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int pageNumber = 0;
  int classCount = 0;
  bool expandMenu = false;
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> classes = [];
  List<List<String>> selectedSubjects = [];

  @override
  void initState() {
    super.initState();

    _loadClasess();
  }

  void _loadClasess() async {
    classes = await dbHelper.getClasses('class_table');

    setState(() {
      classes;
      classCount = classes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: expandMenu
              ? Icon(Icons.menu_open, color: Colors.white)
              : Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            setState(() {
              super.setState(() {
                expandMenu = !expandMenu;
              });
            });
          },
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                TextEditingController _textFieldController =
                    TextEditingController();
                _textFieldController.text =
                    "${DateTime.now().year}-${DateTime.now().year + 1}";
                await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Start New Acadamic Year'),
                      content: TextField(
                        controller: _textFieldController,
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(null); // Dismiss without input
                          },
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (await dbHelper
                                    .startNewYear(_textFieldController.text) ==
                                1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('New Acadamic Year Created'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Error Creating New Acadamic Year'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }

                            Navigator.of(context)
                                .pop(_textFieldController.text); // Return input
                          },
                          child: Text('Submit'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            width: expandMenu ? 200 : 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    CustomDrawerItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Home',
                      page: 0,
                      selectedPage: pageNumber,
                      onTap: () {
                        setState(() {
                          pageNumber = 0;
                        });
                      },
                      isMenuExpanded: expandMenu,
                    ),
                    CustomDrawerItem(
                      icon: Icons.rectangle_outlined,
                      selectedIcon: Icons.rectangle_outlined,
                      label: 'Class Rooms',
                      page: 1,
                      selectedPage: pageNumber,
                      onTap: () {
                        setState(() {
                          _loadClasess();
                          pageNumber = 1;
                        });
                      },
                      isMenuExpanded: expandMenu,
                    ),
                    CustomDrawerItem(
                      icon: Icons.group_add_outlined,
                      selectedIcon: Icons.group_add_rounded,
                      label: 'Add Students',
                      page: 4,
                      selectedPage: pageNumber,
                      onTap: () {
                        setState(() {
                          initializeStreamNames();
                          pageNumber = 4;
                        });
                      },
                      isMenuExpanded: expandMenu,
                    ),
                    CustomDrawerItem(
                      icon: Icons.analytics_outlined,
                      selectedIcon: Icons.analytics,
                      label: 'Reports',
                      page: 5,
                      selectedPage: pageNumber,
                      onTap: () {
                        setState(() {
                          pageNumber = 5;
                        });
                      },
                      isMenuExpanded: expandMenu,
                    ),
                    CustomDrawerItem(
                      icon: Icons.add_box_outlined,
                      selectedIcon: Icons.add_box,
                      label: 'Exam Entry',
                      page: 6,
                      selectedPage: pageNumber,
                      onTap: () {
                        setState(() {
                          pageNumber = 6;
                        });
                      },
                      isMenuExpanded: expandMenu,
                    ),
                  ],
                ),
                Column(
                  children: [
                    CustomDrawerItem(
                        icon: widget.isDarkMode
                            ? Icons.wb_sunny
                            : Icons.nightlight_round,
                        selectedIcon: Icons.wb_sunny,
                        label: widget.isDarkMode ? "Light" : "Dark",
                        page: -1,
                        selectedPage: pageNumber,
                        onTap: () {
                          setState(() {
                            widget.onThemeChanged(!widget.isDarkMode);
                          });
                        },
                        isMenuExpanded: expandMenu),
                    CustomDrawerItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Settings',
                      page: 7,
                      selectedPage: pageNumber,
                      onTap: () {
                        setState(() {
                          pageNumber = 0;
                        });
                      },
                      isMenuExpanded: expandMenu,
                    ),
                  ],
                ),
              ],
            ),

            // Add more ListTile widgets for other menu items
          ),
          Expanded(
              child: switch (pageNumber) {
            0 => _buildHome(context),
            1 => _buildClassRooms(context),
            2 => _buildEntrySection("class_table", UniqueKey()),
            3 =>
              _buildEntrySection("stream_table", UniqueKey()), // Stream Table

            4 => _buildEntrySection("student_table", UniqueKey()),
            5 => _buildClassPage(),
            6 => _addNewExam(context, setState),
            // 6 => _buildEntrySection("test_table", UniqueKey()),

            // TODO: Handle this case.
            int() => throw UnimplementedError(),
          }),
        ],
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card()
            // Number of cards in the grid)
          ],
        ),
      ),
    );
  }

  Widget _buildClassPage([int index = 0]) {
    return ClassDetailPage(
      className: classes[index]['class_name'],
      classIndex: index,
    );
  }

  Widget _buildEntrySection(String tableName, Key key) {
    return DataEntryPage(
      metadata: tableMetadataMap[tableName]!,
      key: key,
    );
  }

  Widget _buildClassRooms(BuildContext context) {
    _loadClasess();
    return Container(
      color: Theme.of(context).canvasColor,
      padding: const EdgeInsets.all(20.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Number of columns in the grid
          childAspectRatio: 3 / 2, // Width/height ratio of the cards
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: classCount, // Number of cards in the grid
        itemBuilder: (context, index) {
          return Card(
            color: Theme.of(context).cardColor,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  pageNumber = 5;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: cardBackgroundColors[
                                index % cardBackgroundColors.length],
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                                bottomLeft: Radius.circular(30)),
                            image: DecorationImage(
                              image: AssetImage(
                                  'assets/class-bg-${index % 2}.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Text(
                            classes[index]['class_name'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .black87, // Ensure text is visible over the image
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(height: 5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  DateTime _selectedDate = DateTime.now(); // Set today's date as the default

  _pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate, // Use the selected date or today's date by default
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  TextEditingController classNameController = TextEditingController();
  TextEditingController subjectNameController = TextEditingController();
  TextEditingController topicController = TextEditingController();
  TextEditingController maxiMarkController = TextEditingController();
  TextEditingController testIdController = TextEditingController();
  bool changeExist = true;
  List<Map<String, dynamic>> studentList = [];
  int testId = 0;
  List<String> subjectForSuggestions = [];
  int showAuto = 0;
  Container _addNewExam(BuildContext context, Function parentSetState) {
    List<FocusNode> focusNodes = List.generate(5, (_) => FocusNode());

    List<String>? subjectsOfClass = [];

    maxiMarkController.text = '100';

    return Container(
      color: Theme.of(context).canvasColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                  margin: const EdgeInsets.all(10),
                  height: 310,
                  width: 450,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            height: 70,
                            width: 200,
                            child: autoFill(
                              labelText: 'Class Name',
                              controller: classNameController,
                              focusNode: focusNodes[0],
                              nextFocusNode: focusNodes[1],
                              optionsList: classes
                                  .map((e) => e['class_name'].toString())
                                  .toList(),
                              onSubmitCallback: (value) async {
                                setState(() {
                                  changeExist = true;
                                });
                                if (value.isNotEmpty) {
                                  subjectsOfClass =
                                      await dbHelper.getClassSubjects(value);

                                  if (subjectsOfClass == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Class not found in the database'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      subjectForSuggestions =
                                          subjectsOfClass ?? [];
                                    });
                                  }

                                  return;
                                }
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            height: 70,
                            width: 200,
                            child: autoFill(
                              key: ValueKey(subjectForSuggestions.hashCode),
                              labelText: 'Subject',
                              controller: subjectNameController,
                              nextFocusNode: focusNodes[2],
                              optionsList: subjectForSuggestions,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(bottom: 10),
                            width: 200,
                            child: TextField(
                                focusNode: focusNodes[2],
                                controller: topicController,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Chapter/Topic'),
                                onSubmitted: (value) {
                                  setState(() {
                                    changeExist = true;
                                  });
                                  focusNodes[3].requestFocus();
                                }),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            width: 200,
                            child: TextField(
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              focusNode: focusNodes[3],
                              controller: maxiMarkController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Max Marks',
                              ),
                              onSubmitted: (value) {
                                setState(() {
                                  changeExist = true;
                                });

                                focusNodes[4].requestFocus();
                              },
                            ),
                          ),
                          const Row(
                            children: [],
                          ),
                        ],
                      ),

                      //second column --------
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _pickDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(22.0),
                              child: Row(
                                children: [
                                  Text(
                                    "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}  ", // Default to today's date
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                                focusNode: focusNodes[4],
                                onPressed: () async {
                                  if (classNameController.text.isEmpty ||
                                      subjectNameController.text.isEmpty ||
                                      topicController.text.isEmpty ||
                                      maxiMarkController.text.isEmpty) {
                                    // Show an error message if any field is empty

                                    print(
                                        "classname: ${classNameController.text} \nsubject: ${subjectNameController.text}\n topic: ${topicController.text}\n maxmark: ${maxiMarkController.text}");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please fill in all the fields.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    testId = 0;
                                    // All fields are filled, proceed with your logic
                                    Future<int> tempInt =
                                        dbHelper.getMaxId('test_table');

                                    int maxtestId = await tempInt;

                                    Map<String, dynamic> newTest = {
                                      'date': _selectedDate.toString(),
                                      'className': classNameController.text,
                                      'maxMark': maxiMarkController.text,
                                      'testId': maxtestId + 1,
                                      'topic': topicController.text,
                                      'subject_name':
                                          subjectNameController.text,
                                    };
                                    int subjectId = await dbHelper.getSubjectId(
                                        subjectNameController.text);

                                    if (subjectId == 0) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Subject not found in the database'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    Map<String, dynamic> test = {
                                      'id': newTest['test_id'],
                                      'subject_id': subjectId,
                                      'topic': newTest['topic'],
                                      'max_mark': int.parse(newTest['maxMark']),
                                      'test_date': newTest['date'],
                                    };
                                    if (await dbHelper.insertToTable(
                                            'test_table', test) !=
                                        0) {
                                      // Show a success message
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Test details saved successfully'),

                                          // Use the default theme color
                                        ),
                                      );
                                      testId = maxtestId + 1;

                                      studentList = await dbHelper
                                          .getStudentIdsAndNamesByTestId(
                                              testId);
                                      print(
                                          "studentList length: ${studentList.length}");

                                      setState(() {
                                        changeExist = false;
                                        classNameController.clear();
                                        subjectNameController.clear();
                                        topicController.clear();
                                        maxiMarkController.clear();
                                      });
                                    }

                                    // Proceed with further processing, like saving data to a database or sending it to a server
                                    // Example: saveDataToDatabase(studentName, stream, studentPhone, schoolName, parentName, parentPhone, photoPath);
                                  }
                                },
                                child: const Text('  Save  ')),
                          ),
                        ],
                      ),
                    ],
                  )),
            ],
          ),
          studentList.isNotEmpty && !changeExist
              ? Container(
                  child: Expanded(
                      child: ExamEntry(
                          test_id: testId,
                          ListOfStudents: studentList,
                          key: UniqueKey())),
                )
              : getLogo(40)
        ],
      ),
    );
  }
}
