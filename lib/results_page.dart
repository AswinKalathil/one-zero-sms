import 'package:flutter/material.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/database_helper.dart';

class ClassDetailPage extends StatefulWidget {
  final String className;
  final int classIndex;
  final bool isDedicatedPage;

  ClassDetailPage(
      {required this.className,
      required this.classIndex,
      required this.isDedicatedPage});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  String? _selectedcriteria = 'Student';
  List<String> _criteriaOptions = [];
  // Default criteria

  int? _studentId;
  String _studentName = '';
  String _studentNameForGrade = '';
  String searchText = '';
  String searchTextfinal = '';
  FocusNode serchButtonFocusNode = FocusNode();
  String _selecteddClass = '';
  String _selectedSubject = '';
  List<Map<String, dynamic>> _studentsOfNameList = [];
  List<Map<String, dynamic>> _studentsOfClassList = [];
  List<Map<String, dynamic>> _studentsOfSubjectList = [];
  int resultBoardIndex = 0;
  bool showGradeCard = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _selectedcriteria = 'Student';
    _criteriaOptions = widget.isDedicatedPage
        ? ['Student', 'Subject']
        : ['Student', 'Class', 'Subject'];
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

    if (value.isNotEmpty) {
      if (_selectedcriteria == 'Student') {
        fetchedStudentsList = await _dbHelper.getStudentsOfName(value);
      } else if (_selectedcriteria == 'Class') {
        fetchedStudentsList = await _dbHelper.getStudentsOfClass(value);
      } else if (_selectedcriteria == 'Subject') {
        fetchedStudentsList = await _dbHelper.getStudentsOfSubject(value);
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
      value = widget.className;
      fetchedStudentsList = await _dbHelper.getStudentsOfClass(value);
      _studentsOfClassList = fetchedStudentsList;
      resultBoardIndex = 4;
      searchText = value;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: 2000,
        child: Column(
          children: [
            widget.isDedicatedPage
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          widget.className,
                          style: TextStyle(fontFamily: 'revue', fontSize: 25),
                        ),
                      ),
                    ),
                  )
                : Container(),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 100),
              height: MediaQuery.of(context).size.height * .9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: .75,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      cursorColor: Colors.grey,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search by $_selectedcriteria',
                                        prefixIcon: const Icon(Icons.search),
                                        filled: true,
                                        fillColor:
                                            Theme.of(context).canvasColor,
                                        focusColor:
                                            Theme.of(context).canvasColor,
                                        contentPadding:
                                            const EdgeInsets.all(15.0),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          borderSide: BorderSide(
                                              color:
                                                  Colors.grey.withOpacity(.4),
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
                                        onSubmittedSerch(value);
                                        serchButtonFocusNode.requestFocus();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        !widget.isDedicatedPage
                                            ? SizedBox(
                                                width: 200,
                                                child: _criteriaDropdown(),
                                              )
                                            : const SizedBox(),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: ElevatedButton(
                                              focusNode: serchButtonFocusNode,
                                              onPressed: () {
                                                onSubmittedSerch(
                                                    searchTextfinal);
                                              },
                                              child: const Text('Search')),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: switch (resultBoardIndex) {
                              3 => Text("Search results with  '$searchText'",
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              4 => Text("$searchText Students",
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              5 => Text("Students of $searchText",
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              _ => const Text(""),
                            },
                          ),
                          Expanded(
                            flex: 1,
                            child: switch (resultBoardIndex) {
                              3 => _studentsOfNameList == []
                                  ? const CircleAvatar() //need updation
                                  : studentsListView(_studentsOfNameList),
                              4 => studentsListView(_studentsOfClassList),
                              5 => studentsListView(_studentsOfSubjectList),
                              _ => Container(child: getLogo(30)),
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      child: showGradeCard
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment
                                  .start, // Aligns children to the start (left)
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: GradeCard(
                                    key: UniqueKey(),
                                    studentName: _studentNameForGrade,
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: getLogo(30),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
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
    print(students);
    return SizedBox(
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                child: Container(
                  margin: const EdgeInsets.all(4.0),
                  height: 60,
                  padding: const EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Theme.of(context).cardColor,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle, // Make the container circular
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
                          // errorBuilder: (BuildContext context, Object error,
                          //     StackTrace? stackTrace) {
                          //   return student['gender'] == 'M'
                          //       ? Image.asset('assets/ml.jpg',
                          //           fit: BoxFit.cover)
                          //       : Image.asset('assets/fl.jpg',
                          //           fit: BoxFit.cover);
                          // },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student['student_name'] as String,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(student['stream_name'] as String),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  setState(() {
                    _studentNameForGrade = student['student_name'] as String;
                    showGradeCard = true;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class GradeCard extends StatefulWidget {
  final String studentName;

  GradeCard({Key? key, required this.studentName}) : super(key: key);
  @override
  _GradeCardState createState() => _GradeCardState();
}

class _GradeCardState extends State<GradeCard> {
  String studentName = '';
  String className = '';
  String currentMonth = DateTime.now().month.toString();
  String photoUrl = '';
  List<Map<String, dynamic>> subjects = [];

  @override
  void initState() {
    super.initState();

    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    DatabaseHelper dbHelper = DatabaseHelper();

    List<Map<String, dynamic>> resultsfromDb =
        await dbHelper.getGradeCard(widget.studentName);
    if (resultsfromDb.isEmpty) {
      throw Exception("No data found for student name: ${widget.studentName}");
    }
    print("Results received from db: $resultsfromDb");
    List<Map<String, dynamic>> results = getLatestScores(resultsfromDb);

    if (results.isNotEmpty) {
      // print("Results received from db: $results");--------------
      setState(() {
        // Extract basic information from the first entry
        studentName = results.first['student_name'] as String? ?? '-';
        className = results.first['class_name'] as String? ?? '-';
        // photoUrl = results.first['photo_path'] as String? ??
        //     (results.first['gender'] == 'M'
        //         ? 'assets/ml.jpg'
        //         : 'assets/fl.jpg');
        photoUrl = (results.first['gender'] == 'M'
            ? 'assets/ml.jpg'
            : 'assets/fl.jpg');

        // Construct the list of subjects
        subjects = results.map((row) {
          final subjectName = row['subject_name'] as String? ?? '-';

          // Handle latestScore with type checks
          final latestScore = (row['score'] != null && row['score'] != '-')
              ? (row['score'] is int
                  ? row['score']
                  : int.tryParse(row['score'] as String) ?? 0)
              : '-'; // Replaced with '-' if null or invalid

          // Handle maxMark with type checks
          final maxMark = (row['max_mark'] != null && row['max_mark'] != -1)
              ? (row['max_mark'] is int
                  ? row['max_mark']
                  : int.tryParse(row['max_mark'] as String) ?? '-')
              : '-'; // Replaced with '-' if null or invalid

          // Handle date parsing
          DateTime date =
              DateTime.tryParse(row['test_date'] as String? ?? '') ??
                  DateTime.now();

          return {
            'subject': subjectName,
            'maxMarks': maxMark.toString(),
            'marks': latestScore == '-' ? '-' : latestScore.toString(),
            'grade': _calculateGrade(latestScore == '-' ? -1 : latestScore,
                maxMark is String ? -1 : maxMark),
            'date':
                "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
          };
        }).toList();
      });
    }
  }

  List<Map<String, dynamic>> getLatestScores(List<Map<String, dynamic>> tests) {
    final Map<String, Map<String, dynamic>> latestScores = {};
    final Set<String> subjectsSet = {}; // Track all subjects encountered

    for (var test in tests) {
      String subject = test['subject_name'];
      String studentName = test['student_name'];
      String photoPath = test['photo_path'];
      String gender = test['gender'];
      String className = test['class_name'];
      String academicYear = test['academic_year'];
      int testId = test['test_id'] ?? 0;
      // Handle score as an int, either from int or parsed from string
      int? score = test['score'] is int
          ? test['score']
          : int.tryParse(test['score'] as String);

      // Handle max_mark, ensuring it's treated as an int or remains null
      int? maxMark = test['max_mark'] is int ? test['max_mark'] : null;

      // Handle test_date
      DateTime? testDate = test['test_date'] != null
          ? DateTime.tryParse(test['test_date'] as String)
          : null;

      // Mark the subject as processed
      subjectsSet.add(subject);

      // Check for valid test entry
      if (testDate != null && maxMark != null) {
        var existingEntry = latestScores[subject];

        // Update the entry only if it doesn't exist or if the current testDate is more recent
        if (existingEntry == null ||
            existingEntry['test_date'] == null ||
            testId > existingEntry['test_id']) {
          latestScores[subject] = {
            'student_name': studentName,
            'photo_path': photoPath,
            'gender': gender,
            'class_name': className,
            'academic_year': academicYear,
            'subject_name': subject,
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
          'student_name': 'N/A', // Placeholder for no test conducted
          'photo_path': 'N/A', // Placeholder for no test conducted
          'gender': 'N/A', // Placeholder for no test conducted
          'class_name': 'N/A', // Placeholder for no test conducted
          'academic_year': 'N/A', // Placeholder for no test conducted
          'subject_name': subject,
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

    print('Score: $score, Max Mark: $maxMark');

    double percentage = (score / maxMark) * 100;
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C+';
    if (percentage >= 40) return 'C';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: AspectRatio(
        aspectRatio: 210 / 297, // A4 aspect ratio (210mm x 297mm)
        child: Container(
          padding: const EdgeInsets.all(30.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8.0),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Class: $className',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Date: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    height: 130,
                    child: Image.asset(
                      photoUrl,
                      fit: BoxFit.fitHeight, // Fills the circular container
                      errorBuilder: (BuildContext context, Object error,
                          StackTrace? stackTrace) {
                        return Image.asset('assets/ml.jpg', fit: BoxFit.cover);
                      },
                    ),
                  )
                  // child: Image.asset(
                  //   photoUrl,
                  //   fit: BoxFit.fitHeight,
                  //   errorBuilder: (_, __, ___) {
                  //     return Image.asset('assets/ml.jpg');
                  //   },
                  // )),
                ],
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Grades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Expanded(
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
                      children: [
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Center(
                            child: Text(
                              'Subject',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Center(
                            child: Text(
                              'Marks',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Center(
                            child: Text(
                              'Grade',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
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
            ],
          ),
        ),
      ),
    );
  }
}
