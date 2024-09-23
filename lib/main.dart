import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/results_page.dart';
import 'package:one_zero/dataEntry.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stroke_text/stroke_text.dart';

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
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One-Zero SMS',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: _isDarkMode
            ? Color.fromRGBO(23, 33, 43, 1)
            : Color.fromRGBO(35, 144, 198, 1),
        secondaryHeaderColor: _isDarkMode
            ? Color.fromRGBO(238, 108, 77, 1)
            : Color.fromRGBO(238, 108, 77, 1),
        scaffoldBackgroundColor: _isDarkMode
            ? Color.fromRGBO(14, 22, 33, 1)
            : Color.fromRGBO(240, 240, 240, 1),
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        canvasColor: _isDarkMode
            ? Color.fromRGBO(36, 47, 61, 1)
            : Color.fromRGBO(241, 241, 241, 1),
        cardColor: _isDarkMode ? Color.fromRGBO(43, 82, 120, 1) : Colors.white,
        primaryTextTheme: TextTheme(
          bodyMedium: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      home: MyHomePage(
        onThemeChanged: (bool value) {
          setState(() {
            _isDarkMode = value;
          });
        },
        isDarkMode: _isDarkMode,
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
  DatabaseHelper _dbHelper = DatabaseHelper();
  int _pageNumber = 0;
  int _classCount = 0;
  bool _expandMenu = false;
  bool _isClassTablesInitialized = false;

  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();

    _loadClasess();
    synchTestHistory();
  }

  void _loadClasess() async {
    _classes = await _dbHelper.getClasses('class_table');
    _isClassTablesInitialized = _classCount == 0 ? false : true;
    setState(() {
      _classes;
      _classCount = _classes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: _expandMenu
              ? Icon(Icons.menu_open, color: Colors.white)
              : Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            setState(() {
              super.setState(() {
                _expandMenu = !_expandMenu;
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
                TextEditingController textFieldController =
                    TextEditingController();
                textFieldController.text =
                    "${DateTime.now().year}-${DateTime.now().year + 1}";
                await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Start New Acadamic Year'),
                      content: TextField(
                        controller: textFieldController,
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
                            if (await _dbHelper
                                    .startNewYear(textFieldController.text) ==
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
                                .pop(textFieldController.text); // Return input
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
            width: _expandMenu ? 200 : 60,
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
                      selectedPage: _pageNumber,
                      onTap: () {
                        setState(() {
                          _pageNumber = 0;
                        });
                      },
                      isMenuExpanded: _expandMenu,
                    ),
                    CustomDrawerItem(
                      icon: Icons.rectangle_outlined,
                      selectedIcon: Icons.rectangle_outlined,
                      label: 'Class Rooms',
                      page: 1,
                      selectedPage: _pageNumber,
                      onTap: () {
                        setState(() {
                          _loadClasess();
                          _pageNumber = 1;
                        });
                      },
                      isMenuExpanded: _expandMenu,
                    ),
                    CustomDrawerItem(
                      icon: Icons.group_add_outlined,
                      selectedIcon: Icons.group_add_rounded,
                      label: 'Add Students',
                      page: 4,
                      selectedPage: _pageNumber,
                      onTap: () {
                        setState(() {
                          initializeStreamNames();
                          _pageNumber = 4;
                        });
                      },
                      isMenuExpanded: _expandMenu,
                    ),
                    CustomDrawerItem(
                      icon: Icons.analytics_outlined,
                      selectedIcon: Icons.analytics,
                      label: 'Reports',
                      page: 5,
                      selectedPage: _pageNumber,
                      onTap: () {
                        setState(() {
                          _pageNumber = 5;
                        });
                      },
                      isMenuExpanded: _expandMenu,
                    ),
                    CustomDrawerItem(
                      icon: Icons.add_box_outlined,
                      selectedIcon: Icons.add_box,
                      label: 'Exam Entry',
                      page: 6,
                      selectedPage: _pageNumber,
                      onTap: () {
                        setState(() {
                          _pageNumber = 6;
                        });
                      },
                      isMenuExpanded: _expandMenu,
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
                        selectedPage: _pageNumber,
                        onTap: () {
                          setState(() {
                            widget.onThemeChanged(!widget.isDarkMode);
                          });
                        },
                        isMenuExpanded: _expandMenu),
                    CustomDrawerItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Settings',
                      page: 7,
                      selectedPage: _pageNumber,
                      onTap: () {
                        setState(() {
                          _pageNumber = 0;
                        });
                      },
                      isMenuExpanded: _expandMenu,
                    ),
                  ],
                ),
              ],
            ),

            // Add more ListTile widgets for other menu items
          ),
          Expanded(
              child: switch (_pageNumber) {
            0 => _buildHome(context),
            1 => _buildClassRooms(context),
            // Stream Table

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
    return Center(
      child: Container(
        width: 500,
        height: 500,
        margin: EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Number of cards in a row
                    childAspectRatio:
                        1, // Width/height ratio of the cards (1 for square)
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: 100,
                        height: 100,
                        color: Colors.blueGrey,
                        child: Center(
                          child: Text('Home Page'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassPage([int index = 0]) {
    return (_isClassTablesInitialized)
        ? ClassDetailPage(
            className: _classes[index]['class_name'],
            classIndex: index,
          )
        : Container(
            child: Center(
              child: Text("No Class Data Found"),
            ),
          );
  }

  Widget _buildEntrySection(String tableName, Key key) {
    return (_isClassTablesInitialized)
        ? DataEntryPage(
            metadata: tableMetadataMap[tableName]!,
            key: key,
          )
        : Container(
            child: Center(
              child: Text("No Class Data Found"),
            ),
          );
  }

  Widget _buildClassRooms(BuildContext context) {
    _loadClasess();
    int crossAxisCount = (MediaQuery.of(context).size.width / 350).floor();
    return _isClassTablesInitialized
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 20),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    crossAxisCount, //responsive number of cards in a row
                childAspectRatio: 3 / 2, // Width/height ratio of the cards
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: _classCount, // Number of cards in the grid
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
                        _pageNumber = 5;
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
                                        'assets/class-bg-${index % 3}.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      WidgetSpan(
                                          child: StrokeText(
                                        strokeColor:
                                            Color.fromRGBO(255, 255, 255, .5),
                                        strokeWidth: 1,
                                        text: _classes[index]['class_name']
                                            .substring(
                                                0,
                                                _classes[index]['class_name']
                                                    .lastIndexOf(' ')),
                                        textStyle: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Revue',
                                          color:
                                              Color.fromARGB(221, 59, 57, 57),
                                        ),
                                      )),
                                      TextSpan(
                                        text: '\n' +
                                            _classes[index]['class_name']
                                                .substring(_classes[index]
                                                            ['class_name']
                                                        .lastIndexOf(' ') +
                                                    1),
                                        style: const TextStyle(
                                          fontSize:
                                              16, // Smaller font size for the second line

                                          fontFamily: 'Revue',
                                          color:
                                              Color.fromARGB(221, 59, 57, 57),
                                        ),
                                      ),
                                    ],
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
          )
        : Container(
            child: Center(
              child: Text("No Class Data Found\n Please add class data"),
            ),
          );
  }

  String FormatTwoLine(String text) {
    int lastSpaceIndex = text.lastIndexOf(' ');
    if (lastSpaceIndex == -1) {
      return text; // No space found, return the original text
    }
    return text.substring(0, lastSpaceIndex) +
        '\n' +
        text.substring(lastSpaceIndex + 1);
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

  TextEditingController _classNameController = TextEditingController();
  TextEditingController _subjectNameController = TextEditingController();
  TextEditingController _topicController = TextEditingController();
  TextEditingController _maxiMarkController = TextEditingController();

  bool _changeExist = true;
  bool reset = false;
  List<Map<String, dynamic>> _studentList = [];
  int _testId = 0;
  List<String> _subjectForSuggestions = [];
  int _selectedClassid = 0;
  List<Map<String, dynamic>> _testHistory = [];
  void synchTestHistory() async {
    _testHistory = await _dbHelper.getTestHistory();

    setState(() {});
  }

  Widget showTestHistory() {
    return Container(
      width: 600,
      height: 310,
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey.withOpacity(.5),
          width: .5,
        ),
      ),
      child: ListView.builder(
        itemCount: _testHistory.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: Colors.grey.withOpacity(1), width: 0.4)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _testHistory[index]['subject_name'] ?? "--",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _testHistory[index]['topic'] ?? "_",
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        )),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(
                                _testHistory[index]['test_date']
                                    .replaceAll(' ', 'T'))) ??
                            "--/--/--",
                        style: TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        _testHistory[index]['class_name'] ?? "--",
                        style: TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Spacer(),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Test ID: ${_testHistory[index]['test_id']}" ?? "_",
                          style: TextStyle(
                            fontSize: 8,
                          ),
                        )),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  saveExam() async {
    if (_classNameController.text.isEmpty ||
        _subjectNameController.text.isEmpty ||
        _topicController.text.isEmpty ||
        _maxiMarkController.text.isEmpty) {
      // Show an error message if any field is empty

      // print(
      //     "classname: ${_classNameController.text} \nsubject: ${_subjectNameController.text}\n topic: ${_topicController.text}\n maxmark: ${_maxiMarkController.text}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all the fields.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // All fields are filled, proceed with your logic

      int maxtestId = await _dbHelper.getMaxId('test_table');

      Map<String, dynamic> newTest = {
        'testId': maxtestId + 1,
        'date': _selectedDate.toString(),
        'className': _classNameController.text,
        'maxMark': _maxiMarkController.text,
        'topic': _topicController.text,
        'subject_name': _subjectNameController.text,
      };
      // print(
      //     "class id at subject fetch: $_selectedClassid");
      int subjectId = await _dbHelper.getSubjectId(
          _subjectNameController.text, _selectedClassid);

      if (subjectId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject not found in the database'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      Map<String, dynamic> test = {
        'id': newTest['testId'],
        'subject_id': subjectId,
        'topic': newTest['topic'],
        'max_mark': int.parse(newTest['maxMark']),
        'test_date': newTest['date'],
      };
      print(test);
      if (await _dbHelper.insertToTable('test_table', test) != 0) {
        // Show a success message
        synchTestHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test details saved successfully'),

            // Use the default theme color
          ),
        );
        _testId = maxtestId + 1;

        _studentList = await _dbHelper.getStudentIdsAndNamesByTestId(_testId);

        setState(() {
          _changeExist = false;
        });
        print(
            "studentList length: ${_studentList.length}  ,  ${!_changeExist}");
      }

      // Proceed with further processing, like saving data to a database or sending it to a server
      // Example: saveDataToDatabase(studentName, stream, studentPhone, schoolName, parentName, parentPhone, photoPath);
    }
  }

  Widget _addNewExam(BuildContext context, Function parentSetState) {
    List<FocusNode> focusNodes = List.generate(5, (_) => FocusNode());

    List<String>? subjectsOfClass = [];
    return (_isClassTablesInitialized)
        ? SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.all(5),
                  child: SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 10, right: 10, top: 10),
                              padding: const EdgeInsets.all(20),
                              width: 600,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(.5),
                                  width: .5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Add New Exam',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Spacer(),
                                  ElevatedButton(
                                    focusNode: focusNodes[4],
                                    onPressed: () {
                                      saveExam();
                                    },
                                    child: const Text('  Save  '),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                                margin: const EdgeInsets.only(
                                    left: 10, right: 10, bottom: 10),
                                padding: const EdgeInsets.all(20),
                                height: 310,
                                width: 600,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(.5),
                                    width: .5,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 5),
                                          height: 70,
                                          width: 200,
                                          child: autoFill(
                                            key: ValueKey(_classes.hashCode),
                                            labelText: 'Class Name',
                                            controller: _classNameController,
                                            focusNode: focusNodes[0],
                                            nextFocusNode: focusNodes[1],
                                            optionsList: _classes
                                                .map((e) =>
                                                    e['class_name'].toString())
                                                .toList(),
                                            onSubmitCallback: (value) async {
                                              if (value.isNotEmpty) {
                                                subjectsOfClass =
                                                    await _dbHelper
                                                        .getClassSubjects(
                                                            value);

                                                _selectedClassid = _classes
                                                    .firstWhere((element) =>
                                                        element['class_name'] ==
                                                        value)['id'];
                                                // print(_classes);
                                                // print("selected value: $value");
                                                // print(
                                                //     "selectedClassid: $_selectedClassid");

                                                if (subjectsOfClass == null) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Class not found in the database'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                } else {
                                                  setState(() {
                                                    _subjectForSuggestions =
                                                        subjectsOfClass ?? [];
                                                  });
                                                }

                                                return;
                                              }
                                            },
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 5),
                                          height: 70,
                                          width: 200,
                                          child: autoFill(
                                            key: ValueKey(_subjectForSuggestions
                                                .hashCode),
                                            labelText: 'Subject',
                                            controller: _subjectNameController,
                                            nextFocusNode: focusNodes[2],
                                            optionsList: _subjectForSuggestions,
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          width: 200,
                                          child: TextField(
                                              focusNode: focusNodes[2],
                                              controller: _topicController,
                                              //new decoration
                                              decoration: InputDecoration(
                                                label: const Text(
                                                    ' Chapter/Topic'),
                                                filled: true,
                                                fillColor: Theme.of(context)
                                                    .canvasColor,
                                                focusColor: Colors.grey,
                                                contentPadding:
                                                    const EdgeInsets.all(15.0),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4.0),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey
                                                          .withOpacity(.2),
                                                      width: 0.4),
                                                ),
                                              ),
                                              onSubmitted: (value) {
                                                setState(() {
                                                  _changeExist = true;
                                                });
                                                focusNodes[3].requestFocus();
                                              }),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          width: 200,
                                          child: TextField(
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly
                                            ],
                                            focusNode: focusNodes[3],
                                            controller: _maxiMarkController,
                                            decoration: InputDecoration(
                                              label: const Text('Max Mark'),
                                              filled: true,
                                              fillColor:
                                                  Theme.of(context).canvasColor,
                                              focusColor: Colors.grey,
                                              contentPadding:
                                                  const EdgeInsets.all(15.0),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                borderSide: BorderSide(
                                                    color: Colors.grey
                                                        .withOpacity(.2),
                                                    width: 0.4),
                                              ),
                                            ),
                                            onSubmitted: (value) {
                                              focusNodes[4].requestFocus();

                                              setState(() {
                                                _changeExist = true;
                                              });
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const Icon(
                                                    Icons.calendar_today),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 10, right: 10, top: 10),
                              padding: const EdgeInsets.all(20),
                              width: 600,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(.5),
                                  width: .5,
                                ),
                              ),
                              child: Text(
                                'Recent Tests ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            showTestHistory(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                !_changeExist
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: 730,
                          height: _studentList.length * 50.0 + 300,
                          child: ExamEntry(
                              test_id: _testId, key: ValueKey(_testId)),
                        ),
                      )
                    : SizedBox(height: 400, child: getLogo(40)),
              ],
            ),
          )
        : Container(
            child: Center(
              child: Text("No Class Data Found"),
            ),
          );
  }
}
