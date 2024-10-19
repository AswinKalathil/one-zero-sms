import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/examPage.dart';
import 'package:one_zero/results_page.dart';
import 'package:one_zero/dataEntry.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stroke_text/stroke_text.dart';

void main() async {
  // Initialize the FFI
  // sqfliteFfiInit();

  // // Set the database factory
  // databaseFactory = databaseFactoryFfi;

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
                _isDarkMode ? Color.fromRGBO(24, 37, 51, 1) : Colors.white,
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

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DatabaseHelper _dbHelper = DatabaseHelper();
  int _pageNumber = 0;
  int _selectedClass_index = 0;
  int _selectdClass = 0;
  int _classCount = 0;
  bool _isMenuExpanded = false;
  bool _isClassTablesInitialized = false;
  List<String> appBarTitle = [
    'Class Rooms',
    'Class Details',
    'Add Students',
    'Reports',
    'Exam Entry',
    'Settings'
  ];

  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    _loadClasess();
    _selectdAcadamicYear =
        (_academicYears.isNotEmpty ? _academicYears.last : '2024-25')!;

    super.initState();
  }

  void _loadClasess() async {
    _academicYears = await _dbHelper.getAcademicYears();

    if (_academicYears.isEmpty) {
      return;
    }

    _classes = await _dbHelper.getClasses(_selectdAcadamicYear);

    _isClassTablesInitialized = _classCount == 0 ? false : true;

    setState(() {
      appBarTitle = [
        'Class Rooms',
        'Reports for ${_classes[_selectedClass_index]['class_name']}',
        'Add Students to ${_classes[_selectedClass_index]['class_name']}',
        'Settings',
        'Exam Entry for ${_classes[_selectedClass_index]['class_name']}',
      ];
      _classes;
      _classCount = _classes.length;
    });
    print("class count: $_classCount");
  }

  List<String> _academicYears = [];
  String _selectdAcadamicYear = '';
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
                    _dbHelper.setAcademicYear(_selectdAcadamicYear);
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
  Widget build(BuildContext context) {
    if (!_isClassTablesInitialized) _loadClasess();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          toolbarHeight: 70,
          leading: IconButton(
            iconSize: 40,
            icon: _pageNumber == 0
                ? Icon(Icons.home, color: Colors.white)
                : Icon(Icons.home_outlined, color: Colors.white),
            onPressed: () {
              setState(() {
                _pageNumber = 0;
              });
            },
          ),
          title: Text(appBarTitle[_pageNumber],
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Revue',
              )),
          backgroundColor: Theme.of(context).primaryColor,
          actions: switch (_pageNumber) {
            0 => [
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () {
                    setState(() {});
                  },
                ),
                Container(
                    color: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    width: 200,
                    height: 70,
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: Colors.grey.withOpacity(.4), width: 0.4),
                        ),
                        contentPadding: const EdgeInsets.all(15.0),
                      ),
                      value: _selectdAcadamicYear != null &&
                              _academicYears.contains(_selectdAcadamicYear)
                          ? _selectdAcadamicYear
                          : null,
                      items: List.generate(
                        _academicYears.length,
                        (index) => DropdownMenuItem(
                          child: Text(_academicYears[index],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Revue',
                              )),
                          value: _academicYears[index],
                        ),
                      ),
                      dropdownColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _selectdAcadamicYear = value!;
                          _dbHelper.setAcademicYear(_selectdAcadamicYear);

                          _loadClasess();
                          _pageNumber = 0;
                        });
                      },
                    )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: IconButton(
                      icon: const Icon(Icons.new_label, color: Colors.white),
                      tooltip: 'Start New Acadamic Year',
                      onPressed: () {
                        newYearDialog();
                      }),
                ),
              ],
            1 => [
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () {
                    setState(() {});
                  },
                ),
                SizedBox(
                  width: 200,
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _menuOptions.length,
                    itemBuilder: (context, index) {
                      // Debug print to check the index and list lengths
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
                              Container(
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
                                      _menuIcons[
                                          index], // This will be safe as the index is within bounds
                                      size: _menuOptions[index] == _appMode
                                          ? 25
                                          : 20,
                                      color: _menuOptions[index] == _appMode
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                    Text(
                                      _menuOptions[index],
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: _menuOptions[index] == _appMode
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            int() => [],
          }),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            width: _isMenuExpanded ? 200 : 60,
            height: MediaQuery.of(context).size.height - 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pageNumber == 0
                    ? Padding(
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
                      )
                    : SizedBox(),
                Container(
                  // color: Colors.amber,
                  height: MediaQuery.of(context).size.height - 126,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pageNumber > 0
                          ? SizedBox(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IconButton(
                                      icon: _isMenuExpanded
                                          ? Icon(Icons.menu_open,
                                              color: Colors.white)
                                          : Icon(Icons.menu,
                                              color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          super.setState(() {
                                            _isMenuExpanded = !_isMenuExpanded;
                                          });
                                        });
                                      },
                                    ),
                                  ),
                                  CustomDrawerItem(
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
                                  ),
                                  CustomDrawerItem(
                                    icon: Icons.group_add_outlined,
                                    selectedIcon: Icons.group_add_rounded,
                                    label: 'Add Students',
                                    page: 2,
                                    selectedPage: _pageNumber,
                                    onTap: () {
                                      setState(() {
                                        initializeStreamNames(_selectdClass);
                                        _pageNumber = 2;
                                      });
                                    },
                                    isMenuExpanded: _isMenuExpanded,
                                  ),
                                  CustomDrawerItem(
                                    icon: Icons.add_box_outlined,
                                    selectedIcon: Icons.add_box,
                                    label: 'Exam Entry',
                                    page: 4,
                                    selectedPage: _pageNumber,
                                    onTap: () {
                                      setState(() {
                                        _pageNumber = 4;
                                      });
                                    },
                                    isMenuExpanded: _isMenuExpanded,
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(
                              height: 0,
                            ),
                      SizedBox(
                        child: Column(
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
                                isMenuExpanded: _isMenuExpanded),
                            CustomDrawerItem(
                              icon: Icons.settings_outlined,
                              selectedIcon: Icons.settings,
                              label: 'Settings',
                              page: 5,
                              selectedPage: _pageNumber,
                              onTap: () {
                                setState(() {
                                  _pageNumber = 0;
                                });
                              },
                              isMenuExpanded: _isMenuExpanded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Add more ListTile widgets for other menu items
          ),
          Expanded(
              child: switch (_pageNumber) {
            0 => _buildClassRooms(context),
            1 => _buildClassPage(
                index: _selectedClass_index, isDedicatedPage: true),
            2 => _buildEntrySection(UniqueKey()),
            3 => _buildClassPage(
                index: _selectedClass_index, isDedicatedPage: false),
            4 => ExamScoreSheet(
                classId: _selectdClass,
                isClassTablesInitialized: _isClassTablesInitialized,
                classes: _classes,
                isMenuExpanded: _isMenuExpanded,
              ),
            // 6 => _addNewExam(context, setState),

            // TODO: Handle this case.
            int() => throw UnimplementedError(),
          }),
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
  // Widget _buildHome(BuildContext context) {
  //   return Center(
  //     child: Container(
  //       width: 500,
  //       height: 500,
  //       margin: EdgeInsets.all(20),
  //       child: Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.start,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Expanded(
  //               child: GridView.builder(
  //                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //                   crossAxisCount: 3, // Number of cards in a row
  //                   childAspectRatio:
  //                       1, // Width/height ratio of the cards (1 for square)
  //                   crossAxisSpacing: 20,
  //                   mainAxisSpacing: 20,
  //                 ),
  //                 itemCount: _menuOptions.length,
  //                 itemBuilder: (context, index) {
  //                   return Align(
  //                     alignment: Alignment.topLeft,
  //                     child: MouseRegion(
  //                       cursor: SystemMouseCursors.click,
  //                       child: GestureDetector(
  //                         onTap: () {
  //                           setState(() {
  //                             _appMode = _menuOptions[index];
  //                           });
  //                         },
  //                         child: Container(
  //                           decoration: BoxDecoration(
  //                             color: Theme.of(context).cardColor,
  //                             borderRadius: BorderRadius.circular(10),
  //                             border: Border.all(
  //                               color: Colors.grey.withOpacity(.5),
  //                               width: .5,
  //                             ),
  //                             boxShadow: [
  //                               BoxShadow(
  //                                 color: Colors.grey.withOpacity(.5),
  //                                 blurRadius: 5,
  //                                 offset: Offset(2, 2),
  //                               ),
  //                             ],
  //                           ),
  //                           child: Column(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             children: [
  //                               Icon(
  //                                 _menuIcons[index],
  //                                 size: 50,
  //                               ),
  //                               Center(
  //                                 child: Text(
  //                                   _menuOptions[index],
  //                                   style:
  //                                       TextStyle(fontWeight: FontWeight.bold),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildClassPage({int index = 0, bool isDedicatedPage = true}) {
    return (_isClassTablesInitialized)
        ? ClassDetailPage(
            className: _classes[index]['class_name'],
            classId: _selectdClass,
            isDedicatedPage: isDedicatedPage,
            key: UniqueKey(),
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
            classId: _selectdClass,
            key: key,
          )
        : Container(
            child: Center(
              child: Text("No Class Data Found"),
            ),
          );
  }

  Widget _buildClassRooms(BuildContext context) {
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
                        _selectdClass = _classes[index]['id'];
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
                              Positioned(
                                  bottom: 20,
                                  left: 20,
                                  child: Text(
                                    '\n ${_classes[index]['studentsCount']} Students',
                                    style: const TextStyle(
                                      fontSize:
                                          12, // Smaller font size for the second line

                                      color: Color.fromRGBO(59, 57, 57, .5),
                                    ),
                                  )),
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
