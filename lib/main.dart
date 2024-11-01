import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_zero/DataSyncMethods.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/examPage.dart';
import 'package:one_zero/results_page.dart';
import 'package:one_zero/dataEntry.dart';
import 'package:one_zero/subpages.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stroke_text/stroke_text.dart';
import 'dart:async';

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
    return ScreenUtilInit(
      designSize: Size(360, 690), // Set your design dimensions
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'One-Zero SMS',
          theme: ThemeData(
            primarySwatch: Colors.green,
            primaryColor: _isDarkMode
                ? Color.fromRGBO(23, 33, 43, 1)
                : Color.fromRGBO(53, 104, 84, 1),
            secondaryHeaderColor: Color.fromRGBO(238, 108, 77, 1),
            scaffoldBackgroundColor: _isDarkMode
                ? Color.fromRGBO(14, 22, 33, 1)
                : Color.fromRGBO(240, 240, 240, 1),
            brightness: _isDarkMode ? Brightness.dark : Brightness.light,
            canvasColor: _isDarkMode
                ? Color.fromRGBO(36, 47, 61, 1)
                : Color.fromRGBO(241, 241, 241, 1),
            cardColor:
                _isDarkMode ? Color.fromRGBO(24, 37, 51, 1) : Color(0xFDFEFFFF),
            primaryTextTheme: TextTheme(
              bodyMedium: TextStyle(
                color: _isDarkMode
                    ? Colors.grey[200] // Light grey for softer contrast
                    : Colors.grey[850],
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
      },
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

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DatabaseHelper _dbHelper = DatabaseHelper();
  int _pageNumber = 0;
  int _selectedClass_index = 0;
  String _selectdClassID = '';
  String _selectedClass_name = '';
  int _classCount = 0;
  bool _isMenuExpanded = false;
  bool _isClassTablesInitialized = false;
  List<Map<String, dynamic>> _classes = [];
  List<String> _academicYears = [];
  String _selectdAcadamicYear = '';
  late AnimationController _animationController;
  bool _isSyncing = false;
  List<String> appBarTitle = [
    'Class Rooms',
    'Reports',
    'Enroll',
    'not used',
    'Exams',
    'Settings',
  ];

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2), // Duration for one complete rotation
    );
    _startSync();
    _loadYears();
    _loadClasess();
    super.initState();
  }

  void _loadYears() async {
    _academicYears = await _dbHelper.getAcademicYears();
    _selectdAcadamicYear =
        (_academicYears.isNotEmpty ? _academicYears.last : '-')!;
    setState(() {
      _selectdAcadamicYear;
      _academicYears;
    });
  }

  void _loadClasess() async {
    if (_academicYears.isEmpty) {
      return;
    }

    _classes = await _dbHelper.getClasses(_selectdAcadamicYear);

    _isClassTablesInitialized = _classCount == 0 ? false : true;

    setState(() {
      _classes;
      _classCount = _classes.length;
    });
  }

  void newYearDialog() async {
    TextEditingController textFieldController = TextEditingController();
    textFieldController.text =
        "${DateTime.now().year}-${(DateTime.now().year + 1).toString().substring(2)}";
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
                Navigator.of(context).pop(null); // Dismiss without input
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_academicYears.contains(textFieldController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Acadamic Year Already Exists'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (await _dbHelper.startNewYear(textFieldController.text) ==
                    1) {
                  print(_academicYears);
                  setState(() {
                    _academicYears.add(textFieldController.text);
                    _academicYears = _academicYears.toSet().toList();

                    _selectdAcadamicYear =
                        textFieldController.text; // Set new year as selected
                  });
                  _loadClasess();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New Acadamic Year Created'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error Creating New Acadamic Year'),
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startSync() async {
    setState(() {
      _isSyncing = true;
    });

    _animationController.repeat(); // Start the spinning animation

    try {
      // Simulate a sync operation (replace this with actual sync logic)
      // await Future.delayed(Duration(seconds: 3));

      Database db = await _dbHelper.database;
      await syncDatabase(db); // Await the syncDatabase call
    } catch (e) {
      // Handle any errors that might occur during sync
      print('Error during sync: $e');
    } finally {
      _loadYears();
      _loadClasess();
      _animationController.stop();
      // Stop the animation
      setState(() {
        _isSyncing = false; // Set to false after sync completes
      });
    }
  }

  List<Widget> TopBarActions() {
    List<Widget> actions = [];

    // Add title
    actions.add(
      Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(appBarTitle[_pageNumber],
            style: TextStyle(
              fontSize: 36,
              color: Colors.grey.shade800,
            )),
      ),
    );

    // Add spacer
    actions.add(Spacer());

    // Add sync button

    // Handle page-specific actions
    switch (_pageNumber) {
      case 0:
        actions.add(_buildSyncButton());
        actions.add(_buildAcademicYearDropdown());
        actions.add(_buildNewYearButton());
        break;
      case 1:
        actions.add(_buildSyncButton());
        actions.add(_buildMenuOptionsList());
        break;
      default:
        break;
    }

    return actions;
  }

// Sync button widget
  Widget _buildSyncButton() {
    return Padding(
      padding: EdgeInsets.only(right: 16.0),
      child: RotationTransition(
        turns: Tween<double>(
          begin: 1.0,
          end: 0.0, // 1.0 for a full clockwise rotation
        ).animate(_animationController),
        child: IconButton(
          icon: Icon(
            Icons.sync_rounded,
          ),
          onPressed: _isSyncing ? null : _startSync,
          tooltip: 'Sync data',
        ),
      ),
    );
  }

// Dropdown for selecting academic year

  Widget _buildAcademicYearDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: 200,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButtonFormField(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide:
                BorderSide(color: Colors.grey.withOpacity(.4), width: 0.4),
          ),
          contentPadding: const EdgeInsets.all(15.0),
        ),
        value: _selectdAcadamicYear != null &&
                _academicYears.contains(_selectdAcadamicYear)
            ? _selectdAcadamicYear
            : null,
        items: _academicYears.map((year) {
          return DropdownMenuItem(
            value: year,
            child: Text(
              year,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Revue',
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectdAcadamicYear = value!;
            _loadClasess();
            _pageNumber = 0;
          });
        },
      ),
    );
  }

// Button for starting a new academic year
  Widget _buildNewYearButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IconButton(
        icon: const Icon(
          Icons.new_label,
        ),
        tooltip: 'Start New Academic Year',
        onPressed: () {
          newYearDialog();
        },
      ),
    );
  }

// Menu options list for page 1
  Widget _buildMenuOptionsList() {
    return SizedBox(
      width: 200,
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _menuOptions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _appMode = _menuOptions[index];
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildMenuOptionItem(index),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// Menu option item builder
  Widget _buildMenuOptionItem(int index) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.grey.withOpacity(.5),
          width: .5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.5),
            blurRadius: 5,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _menuIcons[index],
            size: _menuOptions[index] == _appMode ? 25 : 20,
            color: _menuOptions[index] == _appMode ? Colors.black : Colors.grey,
          ),
          Text(
            _menuOptions[index],
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color:
                  _menuOptions[index] == _appMode ? Colors.black : Colors.grey,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isClassTablesInitialized) _loadClasess();

    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            width: _isMenuExpanded ? 200 : 60,
            height: MediaQuery.of(context).size.height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: _isMenuExpanded
                            ? Icon(Icons.menu_open, color: Colors.white)
                            : Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            super.setState(() {
                              _isMenuExpanded = !_isMenuExpanded;
                            });
                          });
                        },
                      ),
                    ),
                    _isMenuExpanded
                        ? Text(_selectedClass_name,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold))
                        : SizedBox()
                  ],
                ),
                // CustomDrawerItem(
                //   icon: _isMenuExpanded ? Icons.menu_open : Icons.menu,
                //   selectedIcon: Icons.menu_open,
                //   label: _selectedClass_name,
                //   page: -1,
                //   selectedPage: _pageNumber,
                //   onTap: () {
                //     setState(() {
                //       super.setState(() {
                //         _isMenuExpanded = !_isMenuExpanded;
                //       });
                //     });
                //   },
                //   isMenuExpanded: _isMenuExpanded,
                // ),
                SizedBox(
                  height: 20,
                ),
                CustomDrawerItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  page: 0,
                  selectedPage: _pageNumber,
                  onTap: () {
                    setState(() {
                      _pageNumber = 0;
                      _selectedClass_name = '';
                    });
                  },
                  isMenuExpanded: _isMenuExpanded,
                ),
                _pageNumber != 0 && _pageNumber != 5
                    ? CustomDrawerItem(
                        icon: Icons.analytics_outlined,
                        selectedIcon: Icons.analytics,
                        label: 'Reports',
                        page: 1,
                        selectedPage: _pageNumber,
                        onTap: () {
                          setState(() {
                            _pageNumber = 1;
                          });
                        },
                        isMenuExpanded: _isMenuExpanded,
                      )
                    : SizedBox(),
                _pageNumber != 0 && _pageNumber != 5
                    ? CustomDrawerItem(
                        icon: Icons.group_add_outlined,
                        selectedIcon: Icons.group_add_rounded,
                        label: 'Enroll',
                        page: 2,
                        selectedPage: _pageNumber,
                        onTap: () {
                          setState(() {
                            initializeStreamNames(_selectdClassID);
                            _pageNumber = 2;
                          });
                        },
                        isMenuExpanded: _isMenuExpanded,
                      )
                    : SizedBox(),
                _pageNumber != 0 && _pageNumber != 5
                    ? CustomDrawerItem(
                        icon: Icons.add_box_outlined,
                        selectedIcon: Icons.add_box,
                        label: 'Exams',
                        page: 4,
                        selectedPage: _pageNumber,
                        onTap: () {
                          setState(() {
                            _pageNumber = 4;
                          });
                        },
                        isMenuExpanded: _isMenuExpanded,
                      )
                    : SizedBox(),
                Spacer(),
                CustomDrawerItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  page: 5,
                  selectedPage: _pageNumber,
                  onTap: () {
                    setState(() {
                      _pageNumber = 5;
                      _selectedClass_name = '';
                    });
                  },
                  isMenuExpanded: _isMenuExpanded,
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
          Expanded(
              child: Column(
            children: [
              Row(children: TopBarActions()),
              Expanded(
                  child: switch (_pageNumber) {
                0 => _buildClassRooms(context),
                1 => _buildClassPage(
                    index: _selectedClass_index, isDedicatedPage: true),
                2 => _buildEntrySection(UniqueKey()),
                3 => _buildClassPage(
                    index: _selectedClass_index, isDedicatedPage: false),
                4 => ExamScoreSheet(
                    classId: _selectdClassID,
                    isClassTablesInitialized: _isClassTablesInitialized,
                    classes: _classes,
                    isMenuExpanded: _isMenuExpanded,
                  ),
                5 => SetiingsPage(
                    onThemeChange: widget.onThemeChanged,
                    academic_year: _selectdAcadamicYear,
                  ),

                // TODO: Handle this case.
                int() => throw UnimplementedError(),
              })
            ],
          )),
        ],
      ),
    );
  }

  final List<String> _menuOptions = [
    'Acadamics',
    'Attendance',
    'Fees',
  ];
  final List<IconData> _menuIcons = [
    Icons.school,
    Icons.check_circle,
    Icons.currency_rupee_rounded,
  ];
  String _appMode = 'Acadamics';

  Widget _buildClassPage({int index = 0, bool isDedicatedPage = true}) {
    return (_isClassTablesInitialized)
        ? ClassDetailPage(
            className: _classes[index]['class_name'],
            classId: _selectdClassID,
            isDedicatedPage: isDedicatedPage,
            key: ValueKey(_isSyncing.hashCode),
          )
        : Container(
            child: Center(
              child: Text("No Class Data Found"),
            ),
          );
  }

  Widget _buildEntrySection(Key key) {
    return (_isClassTablesInitialized)
        ? DataEntryPage(
            metadata: tableMetadataMap['student_table']!,
            classId: _selectdClassID,
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    int crossAxisCount = (MediaQuery.of(context).size.width / 400).floor() + 1;
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
                      super.setState(() {
                        _selectdClassID = _classes[index]['id'];
                        _selectedClass_name = _classes[index]['class_name'];
                        _selectedClass_index = index;
                        _pageNumber = 1;
                      });
                      _loadClasess();
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
                                          index % cardBackgroundColors.length]
                                      .withOpacity(isDarkMode ? .8 : 1),
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
                              Positioned(
                                bottom: 20,
                                left: 20,
                                child: SizedBox(
                                  width: 50,
                                  height: 25,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.people_sharp,
                                        color: Color.fromRGBO(59, 57, 57, .5),
                                      ),
                                      Text(
                                        ' ${_classes[index]['studentsCount']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              14, // Smaller font size for the second line

                                          color: Color.fromRGBO(59, 57, 57, .5),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                // child: Text(
                                //   '\n ${_classes[index]['studentsCount']} Students',
                                //   style: const TextStyle(
                                //     fontSize:
                                //         12, // Smaller font size for the second line

                                //     color: Color.fromRGBO(59, 57, 57, .5),
                                //   ),
                                // ),
                              ),
                              Positioned(
                                  bottom: 10,
                                  right: 60,
                                  child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: StrokeText(
                                        text: _selectdAcadamicYear,
                                        strokeColor:
                                            Color.fromRGBO(250, 250, 250, .2),
                                        strokeWidth: .2,
                                        textStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.grey.shade700
                                              .withOpacity(.2),
                                        ),
                                      )))
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    newYearDialog();
                  },
                  child: Image.asset(
                    'assets/no-data-vector.png', // Asset image path
                    width: 300,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Text(
                  "Create New Batch",
                  style: TextStyle(
                      fontFamily: 'revue', color: Colors.grey, fontSize: 30),
                )
              ],
            ),
          ));
  }
}
