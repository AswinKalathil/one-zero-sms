import 'dart:ffi';

import 'package:flutter/material.dart';

import 'package:one_zero/database_helper.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Assuming your DatabaseHelper is in this file

class ClassDetailPage extends StatefulWidget {
  final String className;
  final int classIndex;

  ClassDetailPage({required this.className, required this.classIndex});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  String? _selectedcriteria;

  String? _studentId;
  List<Map<String, dynamic>> _studentsOfClassList = [];
  List<Map<String, dynamic>> _studentsOfSubjectList = [];
  int resultBoardIndex = 0;
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
          break;
        case 'Class':
          resultBoardIndex = 1;
          break;
        case 'Subject':
          resultBoardIndex = 2;
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
          flex: 2, // 30% of the width
          child: Material(
            elevation: 2,
            child: ListView(
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
                      if (value.isNotEmpty) {
                        print("Searching for $value");
                        if (_selectedcriteria == 'Student') {
                          String? tempStudentId =
                              await dbHelper.getStudentId(value);
                          setState(() {
                            _studentId = tempStudentId ?? '';
                            resultBoardIndex = 3;
                          });
                        } else if (_selectedcriteria == 'Class') {
                          var fetchedStudentsList =
                              await dbHelper.getStudentsOfClass(value);
                          setState(() {
                            _studentsOfClassList = fetchedStudentsList;
                            resultBoardIndex = 4;
                          });
                        } else if (_selectedcriteria == 'Subject') {
                          var fetchedStudentsList =
                              await dbHelper.getStudentsOfSubject(value);
                          setState(() {
                            _studentsOfSubjectList = fetchedStudentsList;
                            print("Students of Subject: $fetchedStudentsList");
                            resultBoardIndex = 5;
                          });
                        }
                      }
                    },
                  ),
                ),
                ListTile(
                  title: const Text("Class"),
                  leading: Checkbox(
                    value: _selectedcriteria == 'Class',
                    onChanged: (bool? value) {
                      _onSelected('Class');
                    },
                  ),
                  onTap: () => _onSelected('Class'),
                ),
                ListTile(
                  title: const Text("Subject"),
                  leading: Checkbox(
                    value: _selectedcriteria == "Subject",
                    onChanged: (bool? value) {
                      _onSelected("Subject");
                    },
                  ),
                  onTap: () => _onSelected("Subject"),
                ),
                ListTile(
                  title: const Text("Student"),
                  leading: Checkbox(
                    value: _selectedcriteria == "Student",
                    onChanged: (bool? value) {
                      _onSelected("Student");
                    },
                  ),
                  onTap: () => _onSelected("Student"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 8, // 80% of the width
          child: Container(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                switch (resultBoardIndex) {
                  0 => const Text("Student Result"),
                  3 => GradeCard(key: UniqueKey(), studentId: _studentId ?? ''),
                  1 => const Text("Class Result"),
                  4 => StudentsListView(
                      key: UniqueKey(), students: _studentsOfClassList),
                  2 => const Text("Subject Result"),
                  5 => StudentsListView(
                      key: UniqueKey(), students: _studentsOfSubjectList),
                  _ => const Text("Invalid"),
                }
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StudentsListView extends StatelessWidget {
  final List<Map<String, dynamic>> students;

  StudentsListView({required Key key, required this.students})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return Container(
            margin: const EdgeInsets.all(8.0),
            width: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(
                  student['photo_id'] ?? 'assets/ml.jpg',
                ),
                onBackgroundImageError: (_, __) {
                  // Handle any image loading error
                },
              ),
              title: Text(student['student_name']),
              onTap: () {
                // Handle tile tap
                print('Tapped on ${student['student_name']}');
              },
            ),
          );
        },
      ),
    );
  }
}

class GradeCard extends StatefulWidget {
  final String studentId;

  GradeCard({Key? key, required this.studentId}) : super(key: key);
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
        await dbHelper.getGradeCard(widget.studentId);

    if (results.isNotEmpty) {
      setState(() {
        if (results.isEmpty) {
          throw Exception("No data found for student ID: ${widget.studentId}");
        }

        // Extract basic information from the first entry
        studentName = results.first['student_name'] as String;
        className = results.first['class_name'] as String;
        photoUrl = results.first['photo_path'] as String? ?? 'assets/ml.jpg';

        // Construct the list of subjects
        subjects = results.map((row) {
          final subjectName = row['subject_name'] as String;
          final latestScore = row['latest_score'] as int;
          final maxMark = row['max_mark'] as int;

          return {
            'subject': subjectName,
            'maxMarks': maxMark.toString(),
            'marks': latestScore.toString(),
            'grade': _calculateGrade(latestScore, maxMark),
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
    return Center(
      child: AspectRatio(
        aspectRatio: 297 / 210, // A4 aspect ratio (210mm x 297mm)
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.white,
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
                          'Month: $currentMonth',
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
                        fit: BoxFit.fitHeight,
                        errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) {
                          return Image.asset('assets/ml.jpg');
                        },
                      )),
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
                  border: TableBorder.all(color: Colors.black),
                  columnWidths: {
                    0: const FlexColumnWidth(2),
                    1: const FlexColumnWidth(1),
                    2: const FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text(
                            'Subject',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text(
                            'Obtained Marks',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text(
                            'Grade',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...subjects.map(
                      (subject) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(subject['subject'] ?? ''),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                                "  ${subject['marks']} / ${subject['maxMarks']}" ??
                                    ''),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(subject['grade'] ?? ''),
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

class GradeCard2 extends StatelessWidget {
  final String studentName;
  final String className;
  final String currentMonth;
  final String photoUrl;
  final List<Map<String, String>>
      subjects; // Each map contains 'subject', 'marks', 'grade'

  GradeCard2({
    required this.studentName,
    required this.className,
    required this.currentMonth,
    required this.photoUrl,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Center(
        child: AspectRatio(
          aspectRatio: 297 / 210, // A4 aspect ratio (210mm x 297mm)
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold), // Reduced font size
                              ),
                              Text(
                                'Class: $className',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Month: $currentMonth',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 100,
                            height: 130,
                            child: Image.asset(
                              photoUrl,
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Grades',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold), // Reduced font size
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: Table(
                    border: TableBorder.all(color: Colors.black),
                    columnWidths: {
                      0: const FlexColumnWidth(2),
                      1: const FlexColumnWidth(1),
                      2: const FlexColumnWidth(1),
                    },
                    children: [
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(6.0), // Reduced padding
                            child: Text(
                              'Subject',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Text(
                              'Marks',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Text(
                              'Grade',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      ...subjects.map(
                        (subject) => TableRow(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.all(6.0), // Reduced padding
                              child: Text(subject['subject'] ?? ''),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(subject['marks'] ?? ''),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(subject['grade'] ?? ''),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text("One Zero")
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: GradeCard2(
      studentName: "John Doe",
      className: "10th Grade",
      currentMonth: "September",
      photoUrl: "https://example.com/photo.jpg",
      subjects: [
        {'subject': 'Mathematics', 'marks': '85', 'grade': 'A'},
        {'subject': 'Science', 'marks': '78', 'grade': 'B+'},
        {'subject': 'English', 'marks': '92', 'grade': 'A+'},
      ],
    ),
  ));
}
