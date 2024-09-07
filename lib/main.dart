import 'dart:math';

import 'package:flutter/material.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/results_page.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/dataEntry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stroke_text/stroke_text.dart';

void main() {
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

  int classCount = classNames.length;

  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> classes = [];

  List<String> subjects = [];
  final List<String> availableSubjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Geography',
    'Malayalam',
    'English',
    'Hindi',
    'IT'
  ];
  final List<List<String>> selectedSubjects = [];

  @override
  void initState() {
    super.initState();
  }

  void _loadClasess() async {
    List<Map<String, dynamic>> classList =
        await dbHelper.getClasses('class_table');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('class Count ${classList.length}')),
    );
    setState(() {
      classes = classList;
    });
  }

  void _insertClass() async {
    String classId = 'c2${Random().nextInt(1000)}';
    String className = 'cse b2';

    if (classId.isNotEmpty && className.isNotEmpty) {
      Map<String, dynamic> newClass = {
        'class_id': classId,
        'class_name': className,
      };

      await dbHelper.insertToTable('class_table', newClass);

      // Clear the text fields
      // _nameController.clear();
      // _ageController.clear();

      // Optionally, show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Student inserted successfully  ${classes.length}')),
      );

      // Optionally, navigate to another screen or refresh the data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid data  ${classes.length}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: StrokeText(
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
                    title: Text('Add New'),
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
                6 => _buildEntrySection("test_table", UniqueKey()),

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
      className: classNames[index],
      classIndex: index,
    );
  }

  Widget _buildEntrySection(String tableName, Key key) {
    if (tableName == 'test_table') {
      return ExamEntry(
        metadata: tableMetadataMap[tableName]!,
        key: key,
      );
    }
    return DataEntryPage(
      metadata: tableMetadataMap[tableName]!,
      key: key,
    );
  }

  Widget _buildClassRooms() {
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
                            classNames[index],
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

  void createClassPopup(BuildContext context) {
    final TextEditingController classNameController = TextEditingController();

    int maxWidth = 1400;
    int maxheight = 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Create New Class',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: maxWidth / 2,
                height: maxheight / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 300,
                          child: TextField(
                            controller: classNameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Class Name',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: classNameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Acadamic Year',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(
                        "Subjects",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // 4 columns
                          childAspectRatio: 3 /
                              1, // Adjust aspect ratio to ensure the tiles are not too small
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: subjects.length + 1, // +1 for the add button
                        itemBuilder: (context, index) {
                          if (index == subjects.length) {
                            return GestureDetector(
                              onTap: () {
                                _showAddTileDialog(context, setState);
                              },
                              child: Container(
                                height: 50, // Ensure the tile has a height
                                width: double.infinity, // Take full width
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Icon(Icons.add,
                                      size: 24, color: Colors.grey),
                                ),
                              ),
                            );
                          } else {
                            return Container(
                              height: 20, // Ensure the tile has a height
                              width: double.infinity, // Take full width
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(subjects[index],
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _loadClasess();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog

                createStreamPopup(context);
              },
              child: const Text('Save and Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTileDialog(BuildContext context, StateSetter parentSetState) {
    TextEditingController subjectNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Subject'),
          content: TextField(
            controller: subjectNameController,
            decoration: const InputDecoration(
              labelText: 'Subject Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (subjectNameController.text.isNotEmpty) {
                  parentSetState(() {
                    subjects.add(subjectNameController.text); // Add new subject
                  });
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void selectTextInTextField(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0, // Start index of the selection
      extentOffset: controller.text.length, // End index of the selection
    );
  }

  void createStreamPopup(BuildContext context) {
    List<TextEditingController> streamNameControllers = [];
    List<TextEditingController> subjectController = [];
    int streamCount = 0;
    int streamNumber = 0;
    streamNameControllers.add(TextEditingController());
    subjectController.add(TextEditingController());
    double maxWidth = 1400;
    double maxheight = 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Create Streams',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: maxWidth / 1.5,
                height: maxheight / 1.5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                        child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 4 columns
                        childAspectRatio: 0.80,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: streamCount + 1, // +1 for the add button
                      itemBuilder: (context, index) {
                        if (index == streamCount) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                streamNameControllers
                                    .add(TextEditingController());
                                streamCount++;
                                subjectController.add(TextEditingController());
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              height: double
                                  .infinity, // Ensure the tile has a height
                              width: double.infinity, // Take full width
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Icon(Icons.add,
                                    size: 24, color: Colors.grey),
                              ),
                            ),
                          );
                        } else {
                          return _showStreamArea(
                              context,
                              streamNameControllers[index],
                              subjectController[index],
                              setState,
                              index);
                        }
                      },
                    )),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _loadClasess();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _insertClass();
                //submit
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Container _showStreamArea(
      BuildContext context,
      TextEditingController streamNameController,
      TextEditingController subjectNameController,
      StateSetter parentSetState,
      int index) {
    selectedSubjects.add([]);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: streamNameController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'stream Name',
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: 200,
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return availableSubjects.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selectedSubject) {
                  parentSetState(() {
                    if (!selectedSubjects[index].contains(selectedSubject)) {
                      selectedSubjects[index].add(selectedSubject);
                      selectTextInTextField(subjectNameController);
                    }
                  });
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                  subjectNameController.text = controller.text;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'Add Subject',
                    ),
                    onEditingComplete: () {
                      onEditingComplete();
                      parentSetState(() {
                        subjectNameController.clear();
                        selectTextInTextField(subjectNameController);
                      });
                    },
                  );
                },
              ),
            ),
          ),
          Wrap(
            spacing: 0, // Space between tiles
            children: selectedSubjects[index].map((subject) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Chip(
                  label: Text(subject),
                  onDeleted: () {
                    parentSetState(() {
                      selectedSubjects[index].remove(subject);
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void addNewStudent(BuildContext context) {
    TextEditingController studentNameController = TextEditingController();
    TextEditingController streamController = TextEditingController();
    TextEditingController studentPhoneController = TextEditingController();
    TextEditingController schoolNameController = TextEditingController();
    TextEditingController parentNameController = TextEditingController();
    TextEditingController parentPhoneController = TextEditingController();
    TextEditingController photoPathController = TextEditingController();

    double maxWidth = 1400;
    double maxheight = 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'New Student',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                  width: maxWidth / 1.5,
                  height: maxheight / 1.5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            width: 300,
                            child: TextField(
                              controller: studentNameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Name',
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            width: 300,
                            child: TextField(
                              controller: schoolNameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'School Name',
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            width: 300,
                            child: TextField(
                              controller: parentNameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Parent Name',
                              ),
                            ),
                          ),
                        ],
                      ),
                      //second column --------
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            width: 200,
                            child: TextField(
                              controller: streamController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Class and Stream'),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            width: 300,
                            child: TextField(
                              controller: studentPhoneController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Student Phone'),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            width: 300,
                            child: TextField(
                              controller: parentPhoneController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Parent Phone',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              height: 150,
                              width: 116, // Take full width
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_add,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 50, left: 100),
                            child: ElevatedButton(
                                onPressed: () async {
                                  if (studentNameController.text.isEmpty ||
                                      streamController.text.isEmpty ||
                                      studentPhoneController.text.isEmpty ||
                                      schoolNameController.text.isEmpty ||
                                      parentNameController.text.isEmpty ||
                                      parentPhoneController.text.isEmpty ||
                                      photoPathController.text.isEmpty) {
                                    // Show an error message if any field is empty
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Please fill in all the fields.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    // All fields are filled, proceed with your logic
                                    Map<String, dynamic> newStudent = {
                                      'student_id':
                                          'some_generated_id', // Replace with actual logic to generate or assign an ID
                                      'student_name':
                                          studentNameController.text,
                                      'photo_id': photoPathController.text,
                                      'student_phone':
                                          studentPhoneController.text,
                                      'parent_name': parentNameController.text,
                                      'parent_phone':
                                          parentPhoneController.text,
                                      'school_name': schoolNameController.text,
                                      'stream_id': streamController.text,
                                    };
                                    await dbHelper.insertToTable(
                                        'student_table', newStudent);

                                    // Show a success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Data submitted successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    // Proceed with further processing, like saving data to a database or sending it to a server
                                    // Example: saveDataToDatabase(studentName, stream, studentPhone, schoolName, parentName, parentPhone, photoPath);
                                  }
                                },
                                child: const Text('  Save  ')),
                          ),
                        ],
                      )
                    ],
                  ));
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _loadClasess();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _insertClass();
                //submit
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Finish'),
            ),
          ],
        );
      },
    );
  }
}
