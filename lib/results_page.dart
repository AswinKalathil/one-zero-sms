import 'dart:io';

import 'package:flutter/material.dart';
import 'package:one_zero/appProviders.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/gradeCard.dart';
import 'package:flutter/gestures.dart';
import 'package:one_zero/testAnalytics.dart';
import 'package:provider/provider.dart';

class ClassDetailPage extends StatefulWidget {
  final String className;
  final String classId;
  final bool isDedicatedPage;

  const ClassDetailPage(
      {required this.className,
      required this.classId,
      required this.isDedicatedPage,
      Key? key});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  String? _selectedcriteria = 'Student';
  List<String> _criteriaOptions = [];
  // Default criteria

  String _studentId = '';

  String searchText = '';
  String searchTextfinal = '';
  FocusNode serchButtonFocusNode = FocusNode();
  List<Map<String, dynamic>> _studentsOfNameList = [];
  List<Map<String, dynamic>> _studentsOfClassList = [];
  List<Map<String, dynamic>> _studentsOfSubjectList = [];
  String _resultTitle = '';

  final ScrollController _scrollController = ScrollController();
  int resultBoardIndex = 0;
  // bool showGradeCard = false;
  List<String> _classSubjects = [];

  List<Map<String, dynamic>> _allSubjects = [];
  Map<String, int> _subjectTestCount = {};

  List<List<Map<String, dynamic>>> _testResults = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _selectedcriteria = 'Student';
    _criteriaOptions = ['Student', 'Class'];
    setAllSubjects();
    setTestCount();

    if (widget.isDedicatedPage) {
      resultBoardIndex = 4;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSubmittedSerch(context, 'class');
      });
    }
  }

  void setAllSubjects() async {
    _classSubjects = (await _dbHelper.getClassSubjects(widget.classId))!;
  }

  void _onSelected(String criteria) {
    setState(() {
      _selectedcriteria = criteria;
      switch (criteria) {
        case 'Student':
          resultBoardIndex = 0;
          Provider.of<ClassPageValues>(context, listen: false)
              .setShowGradeCard(false);

          break;
        case 'Class':
          resultBoardIndex = 1;
          Provider.of<ClassPageValues>(context, listen: false)
              .setShowGradeCard(false);

          break;
        case 'Subject':
          resultBoardIndex = 2;
          Provider.of<ClassPageValues>(context, listen: false)
              .setShowGradeCard(false);

          break;
      }
    });
  }

  DatabaseHelper _dbHelper = DatabaseHelper();
  void onSubmittedSerch(BuildContext context, String value) async {
    final classPageValues = context.read<ClassPageValues>();

    value = value.trim();
    List<Map<String, dynamic>> fetchedStudentsList = [];

    if (!widget.isDedicatedPage && value.isNotEmpty) {
      if (_selectedcriteria == 'Student') {
        // fetchedStudentsList = await _dbHelper.getStudentsOfName(value, 0);
        _resultTitle = "search results with  '$value' ";
      } else if (_selectedcriteria == 'Class') {
        fetchedStudentsList = await _dbHelper.getStudentsOfClass(value);
        _resultTitle = 'students of class $value';
      } else if (_selectedcriteria == 'Subject') {
        fetchedStudentsList = await _dbHelper.getStudentsOfSubject(value);
        _resultTitle = "students of '$value'";
      }

      setState(() {
        searchText = value;
        _studentsOfNameList =
            _selectedcriteria == 'Student' ? fetchedStudentsList : [];
        _studentsOfClassList =
            _selectedcriteria == 'Class' ? fetchedStudentsList : [];
        _studentsOfSubjectList =
            _selectedcriteria == 'Subject' ? fetchedStudentsList : [];
        resultBoardIndex = _selectedcriteria == 'Student'
            ? 3
            : _selectedcriteria == 'Class'
                ? 4
                : 5;
      });
    }

    if (widget.isDedicatedPage && value == 'class') {
      fetchedStudentsList = await _dbHelper.getStudentsOfClass(widget.classId);

      resultBoardIndex = 4;
      searchText = widget.className;
      _resultTitle = "students of class '${widget.className}'";
    } else if (_selectedcriteria == 'Student' && value.isNotEmpty) {
      fetchedStudentsList =
          await _dbHelper.getStudentsOfNameAndClass(value, widget.classId);

      _resultTitle = "search results with  '$value' ";

      resultBoardIndex = 3;
      searchText = value;
    }
    classPageValues.setStudentsListToShow(fetchedStudentsList);
    setState(() {});
  }

  double _screenWidth = 0;
  double _screenHeight = 0;

  List<Map<String, dynamic>> _totalTest = [];

  void setTestCount() async {
    _totalTest = await _dbHelper.getTestHistory(widget.classId);

    int testCount = 0;

    for (var index = 0; index < _classSubjects.length; index++) {
      testCount = 0;
      for (var test in _totalTest) {
        if (test['subject_name'] == _classSubjects[index]) {
          testCount++;
        }
      }
      _subjectTestCount[_classSubjects[index]] = testCount;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child:
          Consumer<ClassPageValues>(builder: (context, classPageValues, child) {
        return Container(
          padding: const EdgeInsets.all(10),
          height: _screenWidth > 1200
              ? _screenHeight * 2 +
                  (((_allSubjects.length + 1) / 2).ceil() * 520)
              : _screenHeight * 2 + ((_allSubjects.length + 1) * 600),
          child: Column(
            children: [
              Listener(
                onPointerSignal: (pointerSignal) {
                  // Handle horizontal scrolling with mouse wheel
                  if (pointerSignal is PointerScrollEvent) {
                    _scrollController.position.moveTo(
                      _scrollController.offset +
                          pointerSignal.scrollDelta
                              .dy, // Adjusts scrolling to horizontal
                    );
                  }
                },
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      margin: const EdgeInsets.only(right: 50),
                      height: 700,
                      width: 1350,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text(
                                    "Subjects",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                  width: 500,
                                  height: 500,
                                  child: GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 1.5),
                                    itemCount: _classSubjects.length,
                                    itemBuilder: (context, index) {
                                      Color indexColor =
                                          SUBJECT_OBJECT[_classSubjects[index]]
                                                  ?.color ??
                                              DEFAULT_SUBJECT.color;
                                      String imagePath =
                                          SUBJECT_OBJECT[_classSubjects[index]]
                                                  ?.image ??
                                              DEFAULT_SUBJECT.image;

                                      int testCount = _subjectTestCount[
                                              _classSubjects[index]] ??
                                          0;

                                      bool showSubjectcard = true;
                                      if (_allSubjects.isNotEmpty) {
                                        showSubjectcard = _allSubjects.any(
                                            (element) =>
                                                element['subject_name'] ==
                                                _classSubjects[index]);
                                      }

                                      return Opacity(
                                        opacity: showSubjectcard ? 1 : .3,
                                        child: Container(
                                          margin: EdgeInsets.all(
                                              showSubjectcard ? 0 : 5),
                                          padding: const EdgeInsets.only(
                                              top: 8, left: 8, right: 4),
                                          decoration: BoxDecoration(
                                            color: indexColor,

                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(8)),
                                            // image: DecorationImage(
                                            //   alignment: Alignment.bottomRight,
                                            //   opacity: .3,
                                            //   image: AssetImage(imagePath),
                                            //   fit: BoxFit.none,
                                            // ),
                                          ),
                                          child: Stack(children: [
                                            Positioned(
                                              bottom: 5,
                                              right: 2,
                                              child: SizedBox(
                                                height: 50,
                                                width: 50,
                                                child: Opacity(
                                                  opacity: .35,
                                                  child: Image.asset(
                                                    imagePath,
                                                    fit: BoxFit
                                                        .contain, // Keeps aspect ratio within the specified size
                                                    alignment:
                                                        Alignment.bottomRight,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  FittedBox(
                                                    child: Text(
                                                      _classSubjects[index],
                                                      style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(.9),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20),
                                                    ),
                                                  ),
                                                  Text('${testCount} Exams',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white
                                                              .withOpacity(.9),
                                                          fontSize: 12)),
                                                ]),
                                          ]),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 550,
                            child: searchText.isNotEmpty
                                ? Container(
                                    // decoration: BoxDecoration(
                                    //   borderRadius: BorderRadius.circular(10),
                                    //   border: Border.all(
                                    //     color: Colors.grey.withOpacity(.5),
                                    //     width: .5,
                                    //   ),
                                    // ),
                                    margin: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 300,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: TextField(
                                              cursorColor: Colors.grey,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Search by $_selectedcriteria',
                                                prefixIcon:
                                                    const Icon(Icons.search),
                                                filled: true,
                                                fillColor: Theme.of(context)
                                                    .canvasColor,
                                                focusColor: Theme.of(context)
                                                    .canvasColor,
                                                contentPadding:
                                                    const EdgeInsets.all(15.0),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey
                                                          .withOpacity(.4),
                                                      width: 0.4),
                                                ),
                                              ),
                                              onChanged: (value) {
                                                classPageValues
                                                    .setShowGradeCard(false);

                                                setState(() {
                                                  searchTextfinal =
                                                      value.trim();
                                                });
                                              },
                                              onSubmitted: (value) {
                                                setState(() {
                                                  searchTextfinal =
                                                      value.trim();
                                                });
                                                onSubmittedSerch(
                                                    context, searchTextfinal);
                                              },
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                            _resultTitle,
                                            style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          // child: switch (resultBoardIndex) {
                                          //   3 => Text(
                                          //       "search results with  '$searchText'",
                                          //       style: const TextStyle(
                                          //         fontSize: 20,
                                          //       )),
                                          //   4 => Text(
                                          //       "students of class $searchText",
                                          //       style: const TextStyle(
                                          //         fontSize: 20,
                                          //       )),
                                          //   5 => Text("students of $searchText",
                                          //       style: const TextStyle(
                                          //         fontSize: 20,
                                          //       )),
                                          //   _ => const Text(""),
                                          // },
                                        ),
                                        classPageValues.studentsListToShow == []
                                            ? const CircleAvatar() //need updation
                                            : studentsListView(classPageValues
                                                .studentsListToShow),
                                      ],
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              classPageValues.showGradeCard
                  ? ColoredBox(
                      color: Theme.of(context).cardColor.withOpacity(.4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 100,
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Report Card',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 800,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GradeCard(
                                key: UniqueKey(),
                                studentId: _studentId,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
              _testResults.isNotEmpty &&
                      _allSubjects.isNotEmpty &&
                      classPageValues.showGradeCard
                  ? Expanded(
                      child: TestAnalytics(
                        allSubjects: _allSubjects
                            .map((e) => e['subject_name'] as String)
                            .toList(),
                        testResults: _testResults,
                        key: ValueKey(_testResults.hashCode),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        );
      }),
    );
  }

  void setAnalyticsStudentId(String studentId) async {
    // Clear the previous test results
    _testResults.clear();

    // Fetch subjects for the student
    _allSubjects = await _dbHelper.getSubjectsOfStudentID(studentId);

    for (var subject in _allSubjects) {
      var subjectId = subject['subject_id'];
      var testHistory = await _dbHelper.getTestHistoryForSubjectOfStudentID(
          studentId, subjectId);
      // print(" $studentId : :\n -------------------------\n$testHistory\n\n");

      // Add the test history to the results
      _testResults.add(testHistory);
    }

    // Update the state to rebuild the widget with new data
    setState(() {
      // Use a unique key for the TestAnalytics widget to trigger a rebuild
      _testResults =
          _testResults; // This is a redundant assignment, just for clarity
    });
  }

  Widget _criteriaDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide:
              BorderSide(color: Colors.grey.withOpacity(.4), width: 0.4),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        focusColor: Colors.grey,
        contentPadding: const EdgeInsets.all(15.0),
      ),
      value: _selectedcriteria,
      items: _criteriaOptions.map((String criteria) {
        return DropdownMenuItem<String>(
          value: criteria,
          child: Text(criteria),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedcriteria = newValue;
          });
        }
      },
      isExpanded: true,
      hint: const Text('Select Criteria'),
    );
  }

  Widget studentsListView(List<Map<String, dynamic>> students) {
    double _screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: 550,
      width: double.infinity,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.vertical,
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.all(4.0),
                    width: _studentId == student['id'] ? 500 : 480,
                    height: 70,
                    padding: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8.0),
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        _studentId == student['id']
                            ? BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              )
                            : BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                spreadRadius: 0,
                                blurRadius: 0,
                                offset: const Offset(0, 3),
                              ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,

                          decoration: BoxDecoration(
                            shape:
                                BoxShape.circle, // Make the container circular
                            border: Border.all(color: Colors.grey),
                          ),
                          clipBehavior: Clip
                              .hardEdge, // Ensures the image is clipped to the circular shape

                          child: student['photo_path'] != null &&
                                  student['photo_path']! != '-'
                              ? Image.file(
                                  File(student[
                                      'photo_path']!), // Display the image without adding it as an asset
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  (student['gender'] == 'F'
                                      ? 'assets/fl.jpg'
                                      : 'assets/ml.jpg'),
                                  fit: BoxFit
                                      .cover, // Fills the circular container
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student['student_name'] as String,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Text(student['stream_name'] as String),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _studentId = student['id'];
                      Provider.of<ClassPageValues>(context, listen: false)
                          .setShowGradeCard(true);
                    });
                    setAnalyticsStudentId(_studentId);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget profileCard() {
    return Container(
        width: 400,
        height: 500,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8.0),
          color: Theme.of(context).cardColor,
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center align
            children: [
              // CircleAvatar(
              //   radius: 75,
              //   backgroundImage: NetworkImage(
              //       'https://example.com/profile.jpg'), // Replace with student's profile image URL
              // ),
              const SizedBox(height: 10),
              const Text(
                'Student Name',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Class: Plus Two STATE',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Academic Year: 2024',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Section: HSS',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // Implement edit functionality here
                          print(
                              'Edit button pressed'); // Placeholder for editing action
                        },
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        ));
  }
}
