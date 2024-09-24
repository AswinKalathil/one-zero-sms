import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/examPage.dart';
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
  int _selectdClass = 0;
  int _classCount = 0;
  bool _expandMenu = false;
  bool _isClassTablesInitialized = false;

  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    _loadClasess();

    super.initState();
  }

  void _loadClasess() async {
    _classes = await _dbHelper.getClasses('class_table');
    _isClassTablesInitialized = _classCount == 0 ? false : true;
    setState(() {
      _classes;
      _classCount = _classes.length;
    });
    print("class count: $_classCount");
  }

  @override
  Widget build(BuildContext context) {
    if (!_isClassTablesInitialized) _loadClasess();

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
            2 => _buildClassPage(index: _selectdClass, isDedicatedPage: true),
            4 => _buildEntrySection("student_table", UniqueKey()),
            5 => _buildClassPage(isDedicatedPage: false),
            6 => ExamScoreSheet(
                isClassTablesInitialized: _isClassTablesInitialized,
                classes: _classes,
              ),
            // 6 => _addNewExam(context, setState),

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

  Widget _buildClassPage({int index = 0, bool isDedicatedPage = true}) {
    return (_isClassTablesInitialized)
        ? ClassDetailPage(
            className: _classes[index]['class_name'],
            classIndex: index,
            isDedicatedPage: isDedicatedPage,
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
                        _selectdClass = index;
                        _pageNumber = 2;
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
}
