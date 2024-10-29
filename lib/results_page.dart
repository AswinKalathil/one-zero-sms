import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/pieChart.dart';
import 'package:one_zero/testAnalytics.dart';

class ClassDetailPage extends StatefulWidget {
  final String className;
  final String classId;
  final bool isDedicatedPage;

  ClassDetailPage(
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
  bool _orientation = true;

  String _studentNameForGrade = '';
  String searchText = '';
  String searchTextfinal = '';
  FocusNode serchButtonFocusNode = FocusNode();
  List<Map<String, dynamic>> _studentsOfNameList = [];
  List<Map<String, dynamic>> _studentsOfClassList = [];
  List<Map<String, dynamic>> _studentsOfSubjectList = [];
  String _resultTitle = '';
  final ScrollController _scrollController = ScrollController();
  int resultBoardIndex = 0;
  bool showGradeCard = false;

  List<Map<String, dynamic>> _allSubjects = [];
  List<List<Map<String, dynamic>>> _testResults = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _selectedcriteria = 'Student';
    _criteriaOptions = ['Student', 'Class'];

    if (widget.isDedicatedPage) {
      resultBoardIndex = 4;
      onSubmittedSerch('class');
    }
  }

  void _onSelected(String criteria) {
    setState(() {
      _selectedcriteria = criteria;
      switch (criteria) {
        case 'Student':
          resultBoardIndex = 0;
          showGradeCard = false;
          break;
        case 'Class':
          resultBoardIndex = 1;
          showGradeCard = false;

          break;
        case 'Subject':
          resultBoardIndex = 2;
          showGradeCard = false;

          break;
      }
    });
  }

  DatabaseHelper _dbHelper = DatabaseHelper();
  void onSubmittedSerch(String value) async {
    value = value.trim();
    List<Map<String, dynamic>> fetchedStudentsList = [];

    if (!widget.isDedicatedPage && value.isNotEmpty) {
      if (_selectedcriteria == 'Student') {
        // fetchedStudentsList = await _dbHelper.getStudentsOfName(value, 0);
        _resultTitle = 'search results with  $value';
      } else if (_selectedcriteria == 'Class') {
        fetchedStudentsList = await _dbHelper.getStudentsOfClass(value);
        _resultTitle = 'students of class $value';
      } else if (_selectedcriteria == 'Subject') {
        fetchedStudentsList = await _dbHelper.getStudentsOfSubject(value);
        _resultTitle = 'students of $value';
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
      _studentsOfClassList = fetchedStudentsList;
      resultBoardIndex = 4;
      searchText = widget.className;
      _resultTitle = 'students of class ${widget.className}';
      setState(() {});
    } else if (_selectedcriteria == 'Student' && value.isNotEmpty) {
      fetchedStudentsList =
          await _dbHelper.getStudentsOfNameAndClass(value, widget.classId);

      setState(() {
        _resultTitle = 'search results with  $value';
        _studentsOfNameList = fetchedStudentsList;
        resultBoardIndex = 3;
        searchText = value;
      });
    }
  }

  final List<String> _menuOptions = [
    'Acadamics',
    'Attendance',
    'Finance',
  ];
  final List<IconData> _menuIcons = [
    Icons.school,
    Icons.check_circle,
    Icons.currency_rupee_rounded,
  ];
  double _screenWidth = 0;
  double _screenHeight = 0;
  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        padding: const EdgeInsets.all(10),
        height: _screenWidth > 1400
            ? _screenHeight +
                800 +
                ((_allSubjects.length / 2).ceil() * 390) +
                1000
            : _screenHeight + 800 + (_allSubjects.length * 430) + 1000,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            !widget.isDedicatedPage
                                ? SizedBox(
                                    width: 200,
                                    child: _criteriaDropdown(),
                                  )
                                : const SizedBox(
                                    width: 40,
                                  ),
                            SizedBox(
                              width: 300,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  cursorColor: Colors.grey,
                                  decoration: InputDecoration(
                                    hintText: 'Search by $_selectedcriteria',
                                    prefixIcon: const Icon(Icons.search),
                                    filled: true,
                                    fillColor: Theme.of(context).canvasColor,
                                    focusColor: Theme.of(context).canvasColor,
                                    contentPadding: const EdgeInsets.all(15.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(.4),
                                          width: 0.4),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    showGradeCard = false;
                                    setState(() {
                                      searchTextfinal = value.trim();
                                    });
                                  },
                                  onSubmitted: (value) {
                                    setState(() {
                                      searchTextfinal = value.trim();
                                    });
                                    onSubmittedSerch(searchTextfinal);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Listener(
              onPointerSignal: (pointerSignal) {
                // Handle horizontal scrolling with mouse wheel
                if (pointerSignal is PointerScrollEvent) {
                  _scrollController.position.moveTo(
                    _scrollController.offset +
                        pointerSignal
                            .scrollDelta.dy, // Adjusts scrolling to horizontal
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
                    margin: EdgeInsets.only(right: 50),
                    height: 600,
                    width: 1350,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
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
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: switch (resultBoardIndex) {
                                          3 => Text(
                                              "search results with  '$searchText'",
                                              style: const TextStyle(
                                                fontSize: 20,
                                              )),
                                          4 => Text(
                                              "students of class $searchText",
                                              style: const TextStyle(
                                                fontSize: 20,
                                              )),
                                          5 => Text("students of $searchText",
                                              style: const TextStyle(
                                                fontSize: 20,
                                              )),
                                          _ => const Text(""),
                                        },
                                      ),
                                      switch (resultBoardIndex) {
                                        3 => _studentsOfNameList == []
                                            ? const CircleAvatar() //need updation
                                            : studentsListView(
                                                _studentsOfNameList),
                                        4 => studentsListView(
                                            _studentsOfClassList),
                                        5 => studentsListView(
                                            _studentsOfSubjectList),
                                        _ => Container(),
                                      },
                                    ],
                                  ),
                                )
                              : SizedBox(),
                        ),
                        SizedBox(
                          width: 500,
                          child: Container(
                            child: showGradeCard
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      profileCard(),
                                    ],
                                  )
                                : Center(
                                    child: getLogo(30, .05),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            showGradeCard
                ? ColoredBox(
                    color: Theme.of(context).cardColor.withOpacity(.4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.all(50.0),
                            child: SizedBox(
                              height: 50,
                              child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _orientation = !_orientation;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.print,
                                    size: 30,
                                  )),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: _screenWidth > 1200
                              ? (_orientation ? _screenWidth * .84 : 600)
                              : 600,
                          height: _screenWidth > 1200
                              ? (_orientation ? 680 : 760)
                              : 760,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GradeCard(
                                key: UniqueKey(),
                                studentId: _studentId,
                                orientation: _orientation),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(),
            _testResults.isNotEmpty && _allSubjects.isNotEmpty
                ? Expanded(
                    child: TestAnalytics(
                      allSubjects: _allSubjects
                          .map((e) => e['subject_name'] as String)
                          .toList(),
                      testResults: _testResults,
                      key: ValueKey(_testResults.hashCode),
                    ),
                  )
                : SizedBox(),
          ],
        ),
      ),
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
      hint: Text('Select Criteria'),
    );
  }

  Widget studentsListView(List<Map<String, dynamic>> students) {
    widget.isDedicatedPage;
    double _screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: 475,
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
                          child: Image.asset(
                            student['photo_path'] as String? ??
                                (student['gender'] == 'F'
                                    ? 'assets/fl.jpg'
                                    : 'assets/ml.jpg'),
                            fit: BoxFit.cover, // Fills the circular container
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

                      _studentNameForGrade = student['student_name'] as String;
                      showGradeCard = true;
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
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
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
              SizedBox(height: 10),
              Text(
                'Student Name',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50),
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
                  SizedBox(
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
                        icon: Icon(Icons.edit),
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

class GradeCard extends StatefulWidget {
  final String studentId;
  final bool orientation;

  GradeCard({Key? key, required this.studentId, required this.orientation})
      : super(key: key);
  @override
  _GradeCardState createState() => _GradeCardState();
}

class _GradeCardState extends State<GradeCard> {
  String studentName = '';
  String className = '';
  String studentAcadamicYeat = '';
  String currentMonth = DateTime.now().month.toString();
  String photoUrl = '';
  String schoolName = '';
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> _radarData = [];

  @override
  void initState() {
    super.initState();

    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    if (widget.studentId == 0) {
      print("Student id is 0");
      return;
    }
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> studentData =
        await dbHelper.getStudentData(widget.studentId);

    List<Map<String, dynamic>> resultsfromDb =
        await dbHelper.getGradeCard(widget.studentId);
    if (resultsfromDb.isEmpty) {
      throw Exception("No data found for student name: ${widget.studentId}");
    }
    // print("Results received from db: $resultsfromDb");
    List<Map<String, dynamic>> results = getLatestScores(resultsfromDb);

    if (studentData.isNotEmpty) {
      setState(() {
        studentName = studentData.first['student_name'] as String? ?? '-';
        className = studentData.first['class_name'] as String? ?? '-';
        schoolName = studentData.first['school_name'] as String? ?? '-';
        photoUrl = (studentData.first['gender'] == 'M'
            ? 'assets/ml.jpg'
            : 'assets/fl.jpg');
      });
    }

    if (results.isNotEmpty) {
      // Using a standard for loop to handle async operations correctly
      for (var element in results) {
        int marks;
        int maxMarks;

        if (element['score'] == '-') {
          marks = 0;
        } else {
          marks = element['score'] ?? 0;
        }
        if (element['max_mark'] == '-') {
          maxMarks = 0;
        } else {
          maxMarks = element['max_mark'] ?? 0;
        }

        // Fetch the average score for the current subject
        var avg = await dbHelper.getStudentSubjectAverage(
            widget.studentId, element['subject_id']);

        // Ensure avg is a double and handle null values
        double averageScore = (avg is double)
            ? avg
            : 0.0; // Default to 0.0 if avg is null or not a double
        double currentPercentage = (marks * 100 / maxMarks).isNaN ||
                (marks * 100 / maxMarks).isInfinite
            ? 0.0
            : (marks * 100 / maxMarks);
        // Update _radarData with the new average score
        _radarData.add({
          'subject': element['subject_name'],
          'marks': [averageScore, currentPercentage],
        });
      }

// Once the loop is done, you can safely print the data

      setState(() {
        subjects = results.map((row) {
          final subjectName = row['subject_name'] as String? ?? '-';

          final latestScore = (row['score'] != null && row['score'] != '-')
              ? (row['score'] is int
                  ? row['score']
                  : int.tryParse(row['score'] as String) ?? 0)
              : '-'; // Replaced with '-' if null or invalid

          final maxMark = (row['max_mark'] != null && row['max_mark'] != -1)
              ? (row['max_mark'] is int
                  ? row['max_mark']
                  : int.tryParse(row['max_mark'] as String) ?? '-')
              : '-'; // Replaced with '-' if null or invalid

          // Handle date parsing
          String dateFormatted = '';
          DateTime? date =
              DateTime.tryParse(row['test_date']?.toString() ?? '');

          // Check if the date is not null
          if (date != null) {
            // Format the date as 'dd-MM-yyyy'
            dateFormatted =
                '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
          } else {
            // Fallback for null dates
            dateFormatted = '-';
          }

          return {
            'subject': subjectName,
            'maxMarks': maxMark.toString(),
            'marks': latestScore == '' ? '-' : latestScore.toString(),
            'grade': _calculateGrade(latestScore == '-' ? -1 : latestScore,
                maxMark is String ? -1 : maxMark),
            'date': dateFormatted,
          };
        }).toList();
      });
    }

    setState(() {
      _radarData;
    });
  }

  List<Map<String, dynamic>> getLatestScores(List<Map<String, dynamic>> tests) {
    final Map<String, Map<String, dynamic>> latestScores = {};
    final Set<String> subjectsSet = {}; // Track all subjects encountered

    for (var test in tests) {
      String subject = test['subject_name'];
      String subjectId = test['subject_id'] ?? '';
      String testId = test['test_id'] ?? '';

      // Handle score as an int, either from int or parsed from string
      int? score = test['score'] is int
          ? test['score']
          : int.tryParse(test['score'] as String);

      // Handle max_mark, ensuring it's treated as an int or remains null
      int? maxMark = test['max_mark'] is int ? test['max_mark'] : null;

      // Handle test_date
      DateTime? testDate;

      if (test['test_date'] != null) {
        // Check if the test_date is already a DateTime
        if (test['test_date'] is DateTime) {
          testDate = test['test_date']
              as DateTime; // Directly assign if it's already a DateTime
        } else if (test['test_date'] is String) {
          // If it's a String, parse it to DateTime
          testDate = DateTime.tryParse(test['test_date'] as String);
        } else {
          // Handle unexpected types
          print(
              'Unexpected type for test_date: ${test['test_date'].runtimeType}');
        }
      }

      // Mark the subject as processed
      subjectsSet.add(subject);

      // Check for valid test entry
      if (testDate != null && maxMark != null) {
        var existingEntry = latestScores[subject];

        DateTime? existingDate = existingEntry?['test_date'] != null
            ? DateTime.parse(existingEntry?['test_date'])
            : null;

        bool isAfterComparison =
            existingDate == null || testDate.isAfter(existingDate!);

        // Update the entry only if it doesn't exist or if the current testDate is more recent
        if (isAfterComparison == true) {
          latestScores[subject] = {
            'subject_name': subject,
            'subject_id': subjectId,
            'score': score, // Keep score as int
            'max_mark': maxMark, // Keep max_mark as int or null
            'test_date': testDate.toIso8601String(),
            'test_id': testId // Store as String for output
          };
        }
      }
    }

    // Ensure all subjects are represented, even if no tests were conducted
    for (String subject in subjectsSet) {
      if (!latestScores.containsKey(subject)) {
        latestScores[subject] = {
          // Placeholder for no test conducted
          'subject_name': subject,
          'subject_id': '-', // Indicate no test conducted
          'score': '-', // Indicate no test conducted
          'max_mark': '-', // Indicate no test conducted
          'test_date': null // No date available
        };
      }
    }

    // Convert latest scores map to a list
    return latestScores.values.toList();
  }

  String _calculateGrade(int score, int maxMark) {
    if (maxMark == -1) {
      return '-';
    } else if (score == -1) {
      return 'Absent';
    }

    // print('Score: $score, Max Mark: $maxMark');

    double percentage = (score / maxMark) * 100;

    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C+';
    if (percentage >= 40) return 'C';
    return 'F';
  }

  Widget verticalCard() {
    bool isFullApluss = false;
    int aplussCount = 0;

    for (var subject in subjects) {
      if (subject['grade'] == 'A+') {
        aplussCount++;
      }
    }
    isFullApluss = aplussCount == subjects.length && aplussCount > 0;

    return SizedBox(
      child: AspectRatio(
        aspectRatio: 1, // A4 aspect ratio (210mm x 297mm)
        // aspectRatio: 297 / 210,
        child: Container(
          padding: const EdgeInsets.all(30.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8.0),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    height: 100,
                    child: Image.asset(
                      photoUrl,
                      fit: BoxFit.fitHeight, // Fills the circular container
                      errorBuilder: (BuildContext context, Object error,
                          StackTrace? stackTrace) {
                        return Image.asset('assets/ml.jpg', fit: BoxFit.cover);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, bottom: 10),
                    child: SizedBox(
                      width: 200,
                      height: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$className',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            '$schoolName',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  isFullApluss
                      ? Padding(
                          padding: const EdgeInsets.only(left: 20, top: 20.0),
                          child: Image.asset(
                            'assets/apluss.png',
                            width: 90,
                            height: 90,
                          ),
                        )
                      : const SizedBox(),
                  Spacer(),
                  getLogoColored(10, .6),
                ],
              ),
              SizedBox(height: 16.0),
              const Text(
                'Latest Grades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              SizedBox(
                height: 50 + subjects.length * 30.0,
                child: Table(
                  border: TableBorder.all(color: Colors.grey),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Center(
                            child: FittedBox(
                              child: Text(
                                'Subject',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Center(
                            child: FittedBox(
                              child: Text(
                                'Marks',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Center(
                            child: FittedBox(
                              child: Text(
                                'Grade',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Center(
                            child: Text(
                              'Date',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...subjects.map(
                      (subject) => TableRow(
                        children: [
                          Container(
                            height: 30,
                            padding: const EdgeInsets.all(5.5),
                            child: FittedBox(
                                child: Text(subject['subject'] ?? '')),
                          ),
                          Container(
                            height: 30,
                            padding: const EdgeInsets.all(5.5),
                            child: FittedBox(
                              child: Text(
                                  "  ${subject['marks']} / ${subject['maxMarks']}" ??
                                      '-'),
                            ),
                          ),
                          Container(
                            height: 30,
                            padding: const EdgeInsets.all(5.5),
                            child:
                                FittedBox(child: Text(subject['grade'] ?? '')),
                          ),
                          Container(
                            height: 30,
                            padding: const EdgeInsets.all(5.5),
                            child:
                                FittedBox(child: Text(subject['date'] ?? '')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green, // Assign color
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Average'),
                  const SizedBox(width: 20),
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue, // Assign color
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Current'),
                  Spacer(),
                  Text(
                    'Consistancy: 80%',
                  ),
                ],
              ),
              Container(
                height: 225,
                width: 500,
                child: Center(
                  child: _radarData.length > 0
                      ? RadarChartWidget(
                          subjectsData: _radarData,
                        )
                      : const SizedBox(),
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ' ${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget horizontalCard() {
    return Container(
      // padding: const EdgeInsets.all(30.0),
      // decoration: BoxDecoration(
      //   border: Border.all(color: Colors.grey.withOpacity(1)),
      //   borderRadius: BorderRadius.circular(8.0),
      //   color: Theme.of(context).cardColor,
      // ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: _screenWidth * .4,
            height: 700,
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 100,
                      child: Image.asset(
                        photoUrl,
                        fit: BoxFit.fitHeight, // Fills the circular container
                        errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) {
                          return Image.asset('assets/ml.jpg',
                              fit: BoxFit.cover);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0, bottom: 10),
                      child: SizedBox(
                        width: 300,
                        height: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$className',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              '$schoolName',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Latest Grades',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                SizedBox(
                  height: 50 + subjects.length * 30.0,
                  child: Table(
                    border: TableBorder.all(color: Colors.grey),
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  'Subject',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  'Marks',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  'Grade',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Center(
                              child: Text(
                                'Date',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...subjects.map(
                        (subject) => TableRow(
                          children: [
                            Container(
                              height: 30,
                              padding: const EdgeInsets.all(5.5),
                              child: FittedBox(
                                  child: Text(subject['subject'] ?? '')),
                            ),
                            Container(
                              height: 30,
                              padding: const EdgeInsets.all(5.5),
                              child: FittedBox(
                                child: Text(
                                    "  ${subject['marks']} / ${subject['maxMarks']}" ??
                                        '-'),
                              ),
                            ),
                            Container(
                              height: 30,
                              padding: const EdgeInsets.all(5.5),
                              child: FittedBox(
                                  child: Text(subject['grade'] ?? '')),
                            ),
                            Container(
                              height: 30,
                              padding: const EdgeInsets.all(5.5),
                              child:
                                  FittedBox(child: Text(subject['date'] ?? '')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Academic Performance          \nOveral Percentage: 66%\nConsistency: 70% ',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ' ${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: _screenWidth * .38,
            height: 600,
            child: Column(
              children: [
                Container(
                  height: 600,
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      Container(
                        height: 500,
                        width: 500,
                        child: Center(
                          child: _radarData.length > 0
                              ? RadarChartWidget(
                                  subjectsData: _radarData,
                                )
                              : const SizedBox(),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green, // Assign color
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Average'),
                          const SizedBox(width: 20),
                          Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue, // Assign color
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Current'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _screenWidth = 0;
  double _screenHeight = 0;
  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;

    return _screenWidth > 1200
        ? (widget.orientation ? horizontalCard() : verticalCard())
        : verticalCard();
  }
}
