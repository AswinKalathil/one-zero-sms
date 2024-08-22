import 'dart:math';

import 'package:flutter/material.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/database_helper.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:multilevel_drawer/multilevel_drawer.dart';

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

  void _loadStudents() async {
    List<Map<String, dynamic>> classList = await dbHelper.getClasses();
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

      await dbHelper.insertClass(newClass);

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
        title: const Text('One Zero SMS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                createStreamPopup(context);
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                // Handle the Home tap here
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add  Class'),
              onTap: () {
                Navigator.pop(context);
                // Handle tap here
                createClassPopup(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add  Stream'),
              onTap: () {
                Navigator.pop(context);
                // Handle tap here
                createStreamPopup(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add  Student'),
              onTap: () {
                Navigator.pop(context);
                // Handle tap here
                addNewStudent(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add  Exam'),
              onTap: () {
                Navigator.pop(context);
                // Handle tap here
                createClassPopup(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: const Text('Night Mode'),
              trailing: Switch(
                value: widget.isDarkMode,
                onChanged: (value) {
                  widget.onThemeChanged(value);
                },
              ),
            ),
            // Add more ListTile widgets for other menu items
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
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
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ClassDetailPage(
                        className: classNames[index],
                        classIndex: index,
                      ),
                      transitionDuration: Duration.zero,
                    ),
                  );
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
                _loadStudents();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog

                createStreamPopup(context);
              },
              child: const Text('Continue'),
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
                _loadStudents();
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
              child: const Text('Continue'),
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

  Future<dynamic> addNewStudent(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Add New Student'),
            content: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Student Name',
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Stream',
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Photo',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Add'),
              ),
            ],
          );
        });
  }
}

class ClassDetailPage extends StatelessWidget {
  final String className;
  final int classIndex;

  ClassDetailPage({required this.className, required this.classIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          className,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3, // 30% of the width
            child: Container(
              margin: EdgeInsets.all(10),
              color:
                  Colors.blueGrey[200], // Background color for identification
              child: Column(
                children: [SearchDropdown()],
              ),
            ),
          ),
          Expanded(
            flex: 7, // 80% of the width
            child: Container(
              margin: EdgeInsets.all(10),
              color: Color.fromARGB(
                  255, 221, 221, 221), // Background color for identification
              child: Column(
                children: [],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchDropdown extends StatefulWidget {
  @override
  _SearchDropdownState createState() => _SearchDropdownState();
}

class _SearchDropdownState extends State<SearchDropdown> {
  String _selectedSearchCriteria = 'Name';

  final List<String> _searchCriteria = ['Name', 'Class', 'Subject'];

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      initialSelection: _searchCriteria.first,
      onSelected: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          _selectedSearchCriteria = value!;
        });
      },
      dropdownMenuEntries:
          _searchCriteria.map<DropdownMenuEntry<String>>((String value) {
        return DropdownMenuEntry<String>(value: value, label: value);
      }).toList(),
    );
  }
}
