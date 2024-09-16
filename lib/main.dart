import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/results_page.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/dataEntry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

void main() {
  // Initialize the FFI
  sqfliteFfiInit();

  // Set the database factory
  databaseFactory = databaseFactoryFfi;
  initializeStreamNames();
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
          primarySwatch: Colors.blue,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
          canvasColor: isDarkMode ? Colors.grey[850] : Colors.grey[200]),
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
        backgroundColor: Colors.blue,
        title: const StrokeText(
          text: "ONE ZERO",
          textStyle:
              TextStyle(fontSize: 30, fontFamily: 'Revue', color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {},
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Row(
                children: [
                  Icon(Icons.nightlight_round,
                      color: widget.isDarkMode ? Colors.white : Colors.black),
                  Switch(
                    value: widget.isDarkMode,
                    onChanged: widget.onThemeChanged,
                    activeColor: Colors.white,
                  ),
                ],
              )),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Material(
              elevation: 5,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      setState(() {
                        pageNumber = 0;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.rectangle_outlined),
                    title: const Text('Class Rooms'),
                    onTap: () {
                      setState(() {
                        pageNumber = 1;
                      });
                    },
                  ),
                  ExpansionTile(
                    leading: const Icon(Icons.add_box),
                    title: const Text('Add New'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: ListTile(
                          leading: const Icon(Icons.add_box_outlined),
                          title: const Text('Class'),
                          onTap: () {
                            setState(() {
                              pageNumber = 1;
                            });
                            setState(() {
                              pageNumber = 2;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: ListTile(
                          leading: const Icon(Icons.add_box_outlined),
                          title: const Text('Stream'),
                          onTap: () {
                            setState(() {
                              pageNumber = 3;
                            });
                            // createStreamPopup(context);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: ListTile(
                          leading: const Icon(Icons.add_box_outlined),
                          title: const Text('Student'),
                          onTap: () {
                            setState(() {
                              pageNumber = 1;
                            });
                            setState(() {
                              pageNumber = 4;
                              print(4);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Results'),
                    onTap: () {
                      setState(() {
                        pageNumber = 5;
                      });
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.add_box),
                    title: const Text('New Exam'),
                    onTap: () {
                      setState(() {
                        pageNumber = 6;
                      });
                    },
                  ),

                  // Add more ListTile widgets for other menu items
                ],
              ),
            ),
          ),
          Expanded(
              flex: 8,
              child: switch (pageNumber) {
                0 => _buildHome(),
                1 => _buildClassRooms(),
                2 => _buildEntrySection("class_table", UniqueKey()),
                3 => _buildEntrySection(
                    "stream_table", UniqueKey()), // Stream Table

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

  Widget _buildHome() {
    return Container();
  }

  Widget _buildClassPage([int index = 0]) {
    return ClassDetailPage(
      className: classes[index]['class_name'],
      classIndex: index,
    );
  }

  Widget _buildEntrySection(String tableName, Key key) {
    if (tableName == 'test_table') {
      return ExamEntry(
        test_id: 100,
        key: key,
      );
    }
    return DataEntryPage(
      metadata: tableMetadataMap[tableName]!,
      key: key,
    );
  }

  Widget _buildClassRooms() {
    _loadClasess();
    return Padding(
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
            color: Colors.white,
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
  int testId = 0;
  List<String> subjectForSuggestions = [];
  int showAuto = 0;
  Row _addNewExam(BuildContext context, Function parentSetState) {
    List<FocusNode> focusNodes = List.generate(5, (_) => FocusNode());

    List<String>? subjectsOfClass = [];

    maxiMarkController.text = '100';
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                margin: const EdgeInsets.all(10),
                height: 500,
                width: 450,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
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
                                }
                                parentSetState(() {
                                  subjectForSuggestions = subjectsOfClass ?? [];
                                });
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
                            labelText: 'Subject',
                            controller: subjectNameController,
                            nextFocusNode: focusNodes[2],
                            optionsList: subjectForSuggestions,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          width: 200,
                          child: TextField(
                              focusNode: focusNodes[2],
                              controller: topicController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Chapter/Topic'),
                              onSubmitted: (value) {
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
                                    'subject_name': subjectNameController.text,
                                  };
                                  int subjectId = await dbHelper
                                      .getSubjectId(subjectNameController.text);

                                  if (subjectId == 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                  await dbHelper.insertToTable(
                                      'test_table', test);
                                  setState(() {
                                    testId = maxtestId + 1;
                                  });
                                  // Show a success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Data submitted successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  setState(() {
                                    classNameController.clear();
                                    subjectNameController.clear();
                                    topicController.clear();
                                    maxiMarkController.clear();
                                  });

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
        if (testId != 0)
          Container(
            child:
                Expanded(child: ExamEntry(test_id: testId, key: UniqueKey())),
          ),
      ],
    );
  }
}
