import 'package:flutter/material.dart';

import 'package:one_zero/DataSyncMethods.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/examPage.dart';
import 'package:one_zero/appProviders.dart';
import 'package:one_zero/results_page.dart';
import 'package:one_zero/dataEntry.dart';
import 'package:one_zero/subpages.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stroke_text/stroke_text.dart';
import 'dart:async';

import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the FFI
  sqfliteFfiInit();

  // Set the database factory
  databaseFactory = databaseFactoryFfi;
  try {
    logToFile('App started');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserCoice()),
          ChangeNotifierProvider(create: (_) => ClassPageValues()),
        ],
        child: MyApp(),
      ),
    );
  } catch (e) {
    logToFile('Error starting app: $e');
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Set your design dimensions
      builder: (BuildContext context, Widget? child) {
        return Consumer<UserCoice>(builder: (context, userChoice, child) {
          return MaterialApp(
            title: 'Insight',
            theme: ThemeData(
              primarySwatch: Colors.green,
              primaryColor: userChoice.isDarkMode
                  ? const Color.fromRGBO(23, 33, 43, 1)
                  : const Color.fromRGBO(53, 104, 84, 1),
              secondaryHeaderColor: const Color.fromRGBO(238, 108, 77, 1),
              scaffoldBackgroundColor: userChoice.isDarkMode
                  ? const Color.fromRGBO(14, 22, 33, 1)
                  : const Color.fromRGBO(230, 230, 230, 1),
              brightness:
                  userChoice.isDarkMode ? Brightness.dark : Brightness.light,
              canvasColor: userChoice.isDarkMode
                  ? const Color.fromRGBO(36, 47, 61, 1)
                  : const Color.fromRGBO(241, 241, 241, 1),
              cardColor: userChoice.isDarkMode
                  ? const Color.fromRGBO(24, 37, 51, 1)
                  : const Color(0xFDFEFFFF),
              primaryTextTheme: TextTheme(
                bodyMedium: TextStyle(
                  color: userChoice.isDarkMode
                      ? Colors.grey[200] // Light grey for softer contrast
                      : Colors.grey[850],
                ),
              ),
            ),
            home: MyHomePage(
              onThemeChanged: (_) {
                if (mounted) {
                  setState(() {
                    userChoice.toggleDarkMode();
                  });
                }
              },
              isDarkMode: userChoice.isDarkMode,
            ),
          );
        });
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
  bool _isClassTablesInitialized = false;
  List<Map<String, dynamic>> _classes = [];
  List<String> _academicYears = [];
  // String _selectdAcadamicYear = '';
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
    super.initState();

    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Load shared preferences and start sync if enabled
    _initializePreferences();

    // Load academic years and classes
    _loadYears();
    _loadClasses();
  }

  void _initializePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final _autoSync = prefs.getBool('autoSync') ?? false;

    if (_autoSync) {
      _startSync();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _loadYears() async {
    _academicYears = await _dbHelper.getAcademicYears();

    if (mounted) {
      final myProvider = Provider.of<UserCoice>(context, listen: false);
      if (myProvider.selectedAcadamicYear.isEmpty) {
        myProvider.setselectedAcadamicYear(
          (_academicYears.isNotEmpty ? _academicYears.last : '-')!,
        );
      }
      setState(() {});
    }
  }

  void _loadClasses() async {
    if (_academicYears.isEmpty) {
      return;
    }

    _classes = await _dbHelper.getClasses(
      Provider.of<UserCoice>(context, listen: false).selectedAcadamicYear,
    );

    if (mounted) {
      setState(() {
        _classCount = _classes.length;
        _isClassTablesInitialized = _classCount > 0;
      });
    }
  }

  void newYearDialog() async {
    final myProvider = Provider.of<UserCoice>(context, listen: false);

    TextEditingController textFieldController = TextEditingController();
    textFieldController.text =
        "${DateTime.now().year}-${(DateTime.now().year + 1).toString().substring(2)}";
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Start New Acadamic Year'),
          content: TextField(
            controller: textFieldController,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Dismiss without input
              },
              child: const Text('Cancel'),
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

                    myProvider
                        .setselectedAcadamicYear(textFieldController.text);
                  });
                  _loadClasses();

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
              child: const Text('Submit'),
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
      _loadClasses();
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
    actions.add(const Spacer());

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
      padding: const EdgeInsets.only(right: 16.0),
      child: RotationTransition(
        turns: Tween<double>(
          begin: 1.0,
          end: 0.0, // 1.0 for a full clockwise rotation
        ).animate(_animationController),
        child: IconButton(
          icon: const Icon(
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
    final myProvider = Provider.of<UserCoice>(context, listen: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        value: myProvider.selectedAcadamicYear != null &&
                _academicYears.contains(myProvider.selectedAcadamicYear)
            ? myProvider.selectedAcadamicYear
            : null,
        items: _academicYears.map((year) {
          return DropdownMenuItem(
            value: year,
            child: Text(
              year,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Revue',
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            myProvider.setselectedAcadamicYear(value!);
            _loadClasses();
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
            offset: const Offset(2, 2),
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
    if (!_isClassTablesInitialized) _loadClasses();

    return Consumer(builder: (context, userChoice, child) {
      return Scaffold(
        key: _scaffoldKey,
        body: Consumer<UserCoice>(builder: (context, userChoice, child) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Theme.of(context).primaryColor,
                width: userChoice.isMenuExpandedTrue ? 200 : 60,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: userChoice.isMenuExpandedTrue
                                ? const Icon(Icons.menu_open,
                                    color: Colors.white)
                                : const Icon(Icons.menu, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                super.setState(() {
                                  userChoice.toggleMenu();

                                  // userChoice.isMenuExpandedTrue = !userChoice.isMenuExpandedTrue;
                                });
                              });
                            },
                          ),
                        ),
                        userChoice.isMenuExpandedTrue
                            ? Text(_selectedClass_name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold))
                            : const SizedBox()
                      ],
                    ),
                    // CustomDrawerItem(
                    //   icon: userChoice.isMenuExpandedTrue ? Icons.menu_open : Icons.menu,
                    //   selectedIcon: Icons.menu_open,
                    //   label: _selectedClass_name,
                    //   page: -1,
                    //   selectedPage: _pageNumber,
                    //   onTap: () {
                    //     setState(() {
                    //       super.setState(() {
                    //         userChoice.isMenuExpandedTrue = !userChoice.isMenuExpandedTrue;
                    //       });
                    //     });
                    //   },
                    //   isMenuExpanded: userChoice.isMenuExpandedTrue,
                    // ),
                    const SizedBox(
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
                      isMenuExpanded: userChoice.isMenuExpandedTrue,
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
                            isMenuExpanded: userChoice.isMenuExpandedTrue,
                          )
                        : const SizedBox(),
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
                            isMenuExpanded: userChoice.isMenuExpandedTrue,
                          )
                        : const SizedBox(),
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
                            isMenuExpanded: userChoice.isMenuExpandedTrue,
                          )
                        : const SizedBox(),
                    const Spacer(),
                    _pageNumber == 0
                        ? CustomDrawerItem(
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
                            isMenuExpanded: userChoice.isMenuExpandedTrue,
                          )
                        : const SizedBox(
                            height: 20,
                          ),
                    const SizedBox(
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
                        isMenuExpanded: userChoice.isMenuExpandedTrue,
                      ),
                    5 => SetiingsPage(
                        academic_year: userChoice.selectedAcadamicYear,
                      ),

                    // TODO: Handle this case.
                    int() => throw UnimplementedError(),
                  })
                ],
              )),
            ],
          );
        }),
      );
    });
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
            child: const Center(
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
            child: const Center(
              child: Text("No Class Data Found"),
            ),
          );
  }

  Widget _buildClassRooms(BuildContext context) {
    _loadClasses();
    final myProvider = Provider.of<UserCoice>(context, listen: false);

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
                      _loadClasses();
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
                                        strokeColor: const Color.fromRGBO(
                                            255, 255, 255, .5),
                                        strokeWidth: 1,
                                        text: _classes[index]['class_name']
                                                .toString()
                                                .contains(' ')
                                            ? _classes[index]['class_name']
                                                .substring(
                                                    0,
                                                    _classes[index]
                                                            ['class_name']
                                                        .lastIndexOf(' '))
                                            : _classes[index]['class_name'],
                                        textStyle: TextStyle(
                                          fontSize: 6.sp,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Revue',
                                          color: const Color.fromARGB(
                                              221, 59, 57, 57),
                                        ),
                                      )),
                                      TextSpan(
                                        text: _classes[index]['class_name']
                                                .toString()
                                                .contains(' ')
                                            ? '\n' +
                                                _classes[index]['class_name']
                                                    .substring(_classes[index]
                                                                ['class_name']
                                                            .lastIndexOf(' ') +
                                                        1)
                                            : '',
                                        style: TextStyle(
                                          fontSize: 4
                                              .sp, // Smaller font size for the second line

                                          fontFamily: 'Revue',
                                          color: const Color.fromARGB(
                                              221, 59, 57, 57),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4.sp,
                                left: 4.sp,
                                child: SizedBox(
                                  width: 50,
                                  height: 25,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.people_sharp,
                                        color: const Color.fromRGBO(
                                            59, 57, 57, .5),
                                        size: 6.sp,
                                      ),
                                      Text(
                                        ' ${_classes[index]['studentsCount']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 4
                                              .sp, // Smaller font size for the second line

                                          color: const Color.fromRGBO(
                                              59, 57, 57, .5),
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
                                  bottom: 2.sp,
                                  right: 12.sp,
                                  child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: StrokeText(
                                        text: myProvider.selectedAcadamicYear,
                                        strokeColor: const Color.fromRGBO(
                                            250, 250, 250, .2),
                                        strokeWidth: .2,
                                        textStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 4.sp,
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
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  "Create New Batch",
                  style: TextStyle(
                      fontFamily: 'revue', color: Colors.grey, fontSize: 30),
                )
              ],
            ),
          ));
  }
}
