import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:one_zero/constants.dart';

import 'package:one_zero/database_helper.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Assuming your DatabaseHelper is in this file

class ClassDetailPage extends StatefulWidget {
  final String className;
  final int classIndex;

  ClassDetailPage({required this.className, required this.classIndex});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  String? _selectedcriteria = 'Student';
  List<String> _criteriaOptions = ['Student', 'Class', 'Subject'];
  // Default criteria

  int? _studentId;
  String _studentName = '';
  String _studentNameForGrade = '';
  String searchText = '';

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

  @override
  Widget build(BuildContext context) {
    DatabaseHelper dbHelper = DatabaseHelper();

    return Row(
      children: [
        Expanded(
          flex: 4,
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
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search by $_selectedcriteria',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                              contentPadding: const EdgeInsets.all(15.0),
                            ),
                            onSubmitted: (value) async {
                              value = value.trim();
                              if (value.isNotEmpty) {
                                List<Map<String, dynamic>> fetchedStudentsList =
                                    [];
                                if (_selectedcriteria == 'Student') {
                                  fetchedStudentsList =
                                      await dbHelper.getStudentsOfName(value);
                                } else if (_selectedcriteria == 'Class') {
                                  fetchedStudentsList =
                                      await dbHelper.getStudentsOfClass(value);
                                } else if (_selectedcriteria == 'Subject') {
                                  fetchedStudentsList = await dbHelper
                                      .getStudentsOfSubject(value);
                                }

                                setState(() {
                                  searchText = value;
                                  _studentsOfNameList =
                                      _selectedcriteria == 'Student'
                                          ? fetchedStudentsList
                                          : _studentsOfNameList;
                                  _studentsOfClassList =
                                      _selectedcriteria == 'Class'
                                          ? fetchedStudentsList
                                          : _studentsOfClassList;
                                  _studentsOfSubjectList =
                                      _selectedcriteria == 'Subject'
                                          ? fetchedStudentsList
                                          : _studentsOfSubjectList;
                                  resultBoardIndex =
                                      _selectedcriteria == 'Student'
                                          ? 3
                                          : _selectedcriteria == 'Class'
                                              ? 4
                                              : 5;
                                });
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: FractionallySizedBox(
                              widthFactor: .5, child: _criteriaDropdown()),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: switch (resultBoardIndex) {
                    3 => Text("Search results with  '$searchText'",
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    4 => Text("$searchText Students",
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    5 => Text("Students of $searchText",
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    _ => const Text("Search something"),
                  },
                ),
                Expanded(
                  flex: 1,
                  child: switch (resultBoardIndex) {
                    3 => studentsListView(_studentsOfNameList),
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
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                    ],
                  )
                : Center(
                    child: getLogo(30),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _criteriaDropdown() {
    return DropdownButton<String>(
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
    return SizedBox(
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return GestureDetector(
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
                      student['photo_path'] as String? ?? 'assets/ml.jpg',
                      fit: BoxFit.cover, // Fills the circular container
                      errorBuilder: (BuildContext context, Object error,
                          StackTrace? stackTrace) {
                        return Image.asset('assets/ml.jpg', fit: BoxFit.cover);
                      },
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

    List<Map<String, dynamic>> results =
        await dbHelper.getGradeCard(widget.studentName);
    if (results.isEmpty) {
      throw Exception("No data found for student name: ${widget.studentName}");
    }
    if (results.isNotEmpty) {
      print("Results recicved from db: $results");
      setState(() {
        // Extract basic information from the first entry
        studentName = results.first['student_name'] as String;
        className = results.first['class_name'] as String;
        photoUrl = results.first['photo_path'] as String? ?? 'assets/ml.jpg';

        // Construct the list of subjects
        subjects = results.map((row) {
          final subjectName = row['subject_name']! as String;
          final latestScore = row['latest_score'] as int;
          final maxMark = row['max_mark'] as int;
          // final latestScore = 66;
          DateTime date = DateTime.parse(row['test_date'] as String);
          return {
            'subject': subjectName,
            'maxMarks': maxMark.toString(),
            'marks': latestScore.toString(),
            'grade': _calculateGrade(latestScore, maxMark),
            'date':
                "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
          };
        }).toList();
      });
    }
  }

  String _calculateGrade(int score, int maxMark) {
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
