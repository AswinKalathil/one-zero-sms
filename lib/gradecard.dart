import 'package:flutter/material.dart';
import 'package:one_zero/appProviders.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/pieChart.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io'; // For Platform, Directory, and File
import 'package:pdf/pdf.dart'; // For PDF generationimport 'package:file_picker/file_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class GradeCard extends StatefulWidget {
  final String studentId;

  GradeCard({Key? key, required this.studentId}) : super(key: key);
  @override
  _GradeCardState createState() => _GradeCardState();
}

class _GradeCardState extends State<GradeCard> {
  String _studentName = '';
  String _parentPhone = '';
  String _className = '';
  String _classId = '';

  String studentAcadamicYear = '';
  String currentMonth = DateTime.now().month.toString();
  String photoUrl = '';
  String errorPhotoUrl = 'assets/ml.jpg';
  String _streamName = '';
  String _gender = '';
  String schoolName = '';
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> _radarData = [];
  bool _enableEdit = false;
  DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isHorizontal = true;
  Map<String, dynamic> studentData = {};

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
    List<Map<String, dynamic>> studentData =
        await _dbHelper.getStudentData(widget.studentId);
    if (studentData.isEmpty) {
      return;
    }

    List<Map<String, dynamic>> resultsfromDb =
        await _dbHelper.getGradeCard(widget.studentId);
    if (resultsfromDb.isEmpty) {
      throw Exception("No data found for student name: ${widget.studentId}");
    }
    // print("Results received from db: $resultsfromDb");
    List<Map<String, dynamic>> results = getLatestScores(resultsfromDb);

    if (studentData.isNotEmpty) {
      if (mounted) {
        setState(() {
          _studentName = studentData.first['student_name'] as String? ?? '-';
          _className = studentData.first['class_name'] as String? ?? '-';
          schoolName = studentData.first['school_name'] as String? ?? '-';
          _streamName = studentData.first['stream_name'] as String? ?? '-';
          _parentPhone = studentData.first['parent_phone'] as String? ?? '-';
          photoUrl = studentData.first['photo_path'];
          _gender = studentData.first['gender'] as String? ?? 'M';

          if (!File(photoUrl).existsSync()) {
            errorPhotoUrl =
                (_gender == 'M' ? 'assets/ml.jpg' : 'assets/fl.jpg');
          }

          studentNameController.text = _studentName;
          parentPhoneController.text = _parentPhone;
          schoolController.text = schoolName;
          streamController.text = _streamName;
          _classId =
              Provider.of<ClassPageValues>(context, listen: false).classId;
          initializeStreamNames(_classId);
        });
      }
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
        var avg = await _dbHelper.getStudentSubjectAverage(
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
        DateTime? date = DateTime.tryParse(row['test_date']?.toString() ?? '');

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
      if (mounted) {
        setState(() {
          subjects;
        });
      }
    }
    if (mounted)
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
        aspectRatio: 210 / 210, // A4 aspect ratio (210mm x 297mm)
        // aspectRatio: 297 / 210,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8.0),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: 80,
                            height: 100,
                            child: Image.file(
                              File(
                                  photoUrl!), // Display the image without adding it as an asset
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  errorPhotoUrl,
                                  fit: BoxFit.cover,
                                );
                              },
                            )),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 10.0, bottom: 10),
                          child: SizedBox(
                            width: 270,
                            height: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _studentName,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$_className',
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
                        const Spacer(),
                        getLogoColored(10, .6),
                      ],
                    ),
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Latest Grades',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                isFullApluss
                    ? Positioned(
                        right: 100,
                        top: 20,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, top: 20.0),
                          child: Image.asset(
                            'assets/apluss.png',
                            width: 100,
                            height: 100,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ]),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green, // Assign color
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Average'),
                          const SizedBox(width: 20),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue, // Assign color
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Current'),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Overall: 80%',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Consitancy: 70%',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  )
                ],
              ),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: 225,
                  width: 320,
                  child: Center(
                    child: _radarData.length > 0
                        ? RadarChartWidget(
                            subjectsData: _radarData,
                          )
                        : const SizedBox(),
                  ),
                ),
              ),
              const Spacer(),
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

  TextEditingController studentNameController = TextEditingController();
  TextEditingController parentPhoneController = TextEditingController();
  TextEditingController schoolController = TextEditingController();
  // TextEditingController classNameController = TextEditingController();
  TextEditingController streamController = TextEditingController();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            width: _screenWidth * .38,
            height: 600,
            child: !_enableEdit
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 80,
                              height: 100,
                              child: Image.file(
                                File(
                                    photoUrl!), // Display the image without adding it as an asset
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    errorPhotoUrl,
                                    fit: BoxFit.cover,
                                  );
                                },
                              )),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 10.0, bottom: 10),
                            child: SizedBox(
                              width: 300,
                              height: 100,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    _studentName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _className,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    schoolName,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 150,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Column(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit Student Details',
                                    onPressed: () {
                                      setState(() {
                                        _enableEdit = true;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  IconButton(
                                      tooltip: 'Delete Student',
                                      onPressed: () async {
                                        // Implement delete functionality here

                                        showDialog(
                                          context: context,
                                          builder:
                                              (BuildContext dialogContext) {
                                            // Use dialogContext for the dialog's context
                                            return AlertDialog(
                                              title:
                                                  const Text('Delete Student'),
                                              content: Text(
                                                  'Are you sure you want to delete $_studentName?'),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(dialogContext)
                                                        .pop(); // Close the dialog
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    await _dbHelper
                                                        .deleteFromTable(
                                                            "student_table",
                                                            widget.studentId);

                                                    // Access Provider in the dialog's context using `dialogContext`
                                                    Provider.of<ClassPageValues>(
                                                            context,
                                                            listen: false)
                                                        .setShowGradeCard(
                                                            false);

                                                    Provider.of<ClassPageValues>(
                                                            context,
                                                            listen: false)
                                                        .removeStudentFromList(
                                                            widget.studentId);

                                                    Navigator.of(dialogContext)
                                                        .pop(); // Close the dialog
                                                  },
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.delete_rounded))
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Latest Grades',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
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
                                    child: FittedBox(
                                        child: Text(subject['date'] ?? '')),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 50,
                        child: const Text(
                          'Overal Percentage: 66%    Consistency: 70% ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                  width: 100,
                                  height: 120,
                                  child: Image.file(
                                    File(
                                        photoUrl!), // Display the image without adding it as an asset
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        errorPhotoUrl,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )),
                              if (_enableEdit)
                                Positioned(
                                  right: 0,
                                  bottom: 1,
                                  child: Container(
                                    width: 100,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.add_a_photo,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _pickAndSaveImage();
                                        // Implement image picker here
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          SizedBox(
                            width: 400,
                            height: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                        width: 400,
                                        child: TextField(
                                          controller: studentNameController,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24),
                                          decoration: InputDecoration(
                                            enabled: _enableEdit,
                                            label: const Text(
                                              'Student Name',
                                            ),
                                            border: const UnderlineInputBorder(
                                                borderSide: BorderSide.none),
                                            enabledBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors
                                                      .grey), // Bottom border when enabled
                                            ),
                                            focusedBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors
                                                      .grey), // Bottom border when enabled
                                            ),
                                          ),
                                        )),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                        width: 150,
                                        child: TextField(
                                          controller: schoolController,
                                          // style: const TextStyle(
                                          //     fontWeight: FontWeight.bold,
                                          //     fontSize: 18),
                                          decoration: InputDecoration(
                                            enabled: _enableEdit,
                                            label: const Text('School'),
                                            border: const UnderlineInputBorder(
                                                borderSide: BorderSide.none),
                                            enabledBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors
                                                      .grey), // Bottom border when enabled
                                            ),
                                            focusedBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors
                                                      .grey), // Bottom border when enabled
                                            ),
                                          ),
                                        )),
                                    const Spacer(),
                                    SizedBox(
                                        width: 210,
                                        child: DropdownButtonFormField<String>(
                                          decoration: const InputDecoration(
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.grey),
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          value:
                                              _streamName, // Default to first item if no selection
                                          items:
                                              STREAM_NAMES.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              if (newValue != null) {
                                                _streamName = newValue;
                                              }
                                            });
                                          },
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 120,
                          ),
                          SizedBox(
                            width: 150,
                            child: TextField(
                              controller: parentPhoneController,
                              // style: const TextStyle(
                              //     fontWeight: FontWeight.bold, fontSize: 18),
                              decoration: InputDecoration(
                                enabled: _enableEdit,
                                label: const Text(
                                  'Parent Phone',
                                ),
                                border: const UnderlineInputBorder(
                                    borderSide: BorderSide.none),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors
                                          .grey), // Bottom border when enabled
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors
                                          .grey), // Bottom border when enabled
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                              width: 150,
                              height: 50,
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  border: InputBorder.none,
                                ),
                                value:
                                    _gender, // Default to first item if no selection
                                items: ['M', 'F', 'Other'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    if (newValue != null) {
                                      _gender = newValue;
                                    }
                                  });
                                },
                              )),
                          const SizedBox(
                            width: 45,
                          )
                        ],
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: CustomButton(
                          text: "Save",
                          onPressed: () async {
                            String streamId = await _dbHelper.getStreamId(
                                _streamName, _classId);
                            studentData = {
                              'student_name': studentNameController.text,
                              'school_name': schoolController.text,
                              'parent_phone': parentPhoneController.text,
                              'gender': _gender,
                              'stream_id': streamId,
                              'photo_id': photoUrl
                            };
                            print('Student data: $studentData');
                            var r = _dbHelper.updateStudent(
                              widget.studentId,
                              studentData,
                            );
                            if (r != 0) {
                              setState(() {
                                _studentName = studentNameController.text;
                                _parentPhone = parentPhoneController.text;
                                schoolName = schoolController.text;
                                _enableEdit = false;
                              });

                              updateStudentsList();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Student data updated'),
                                ),
                              );
                            }
                          },
                          width: 100,
                          height: 40,
                          textColor: Colors.white,
                        ),
                      ),
                      const SizedBox(
                        height: 250,
                      )
                    ],
                  ),
          ),
          SizedBox(
            width: _screenWidth * .36,
            height: 480,
            // decoration: BoxDecoration(
            //   border: Border.all(color: Colors.grey.withOpacity(0.3)),
            //   borderRadius: BorderRadius.circular(8.0),
            //   color: Theme.of(context).cardColor,
            // ),
            child: Stack(
              children: [
                Positioned(
                  left: 70,
                  child: Center(
                    child: SizedBox(
                      height: 480,
                      width: 480,
                      child: _radarData.isNotEmpty
                          ? RadarChartWidget(
                              subjectsData: _radarData,
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green, // Assign color
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Average'),
                      const SizedBox(width: 20),
                      Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue, // Assign color
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Current'),
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
  ScreenshotController _screenshotController = ScreenshotController();
  Widget verticalCardPrint() {
    bool isFullApluss = false;
    int aplussCount = 0;

    for (var subject in subjects) {
      if (subject['grade'] == 'A+') {
        aplussCount++;
      }
    }
    isFullApluss = aplussCount == subjects.length && aplussCount > 0;
    double rowheight = 25.0;
    int rowIndex = 0;

    return SizedBox(
      child: AspectRatio(
        aspectRatio: 210 / 345, // A4 aspect ratio (210mm x 297mm)
        // aspectRatio: 297 / 210,
        child: Container(
          // padding: const EdgeInsets.symmetric(horizontal: 50.0),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text("Report Card",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ),
              Stack(children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: 80,
                            height: 100,
                            child: Image.file(
                              File(
                                  photoUrl!), // Display the image without adding it as an asset
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  errorPhotoUrl,
                                  fit: BoxFit.cover,
                                );
                              },
                            )),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 10.0, bottom: 10),
                          child: SizedBox(
                            width: 270,
                            height: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _studentName,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _className,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  schoolName,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        getLogoColored(10, .6),
                      ],
                    ),
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Latest Grades',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                isFullApluss
                    ? Positioned(
                        right: 100,
                        top: 20,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, top: 20.0),
                          child: Image.asset(
                            'assets/apluss.png',
                            width: 100,
                            height: 100,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ]),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 50 + subjects.length * rowheight,
                  width: 500,
                  child: Table(
                    border: TableBorder.all(color: Colors.grey),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(6),
                      2: FlexColumnWidth(4),
                      3: FlexColumnWidth(3),
                      4: FlexColumnWidth(3),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  'SL No.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  'Subject',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  'Marks',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  'Grade',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Center(
                              child: Text(
                                'Date',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...subjects.map(
                        (subject) {
                          rowIndex++;
                          return TableRow(
                            children: [
                              Container(
                                height: rowheight,
                                padding: const EdgeInsets.all(5.5),
                                child:
                                    FittedBox(child: Text(rowIndex.toString())),
                              ),
                              Container(
                                height: rowheight,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                      child: Text(
                                    subject['subject'] ?? '',
                                    textAlign: TextAlign.left,
                                  )),
                                ),
                              ),
                              Container(
                                height: rowheight,
                                padding: const EdgeInsets.all(5),
                                child: FittedBox(
                                  child: Text(
                                      "  ${subject['marks']} / ${subject['maxMarks']}" ??
                                          '-'),
                                ),
                              ),
                              Container(
                                height: rowheight,
                                padding: const EdgeInsets.all(5),
                                child: FittedBox(
                                    child: Text(subject['grade'] ?? '')),
                              ),
                              Container(
                                height: rowheight,
                                padding: const EdgeInsets.all(5.5),
                                child: FittedBox(
                                    child: Text(subject['date'] ?? '')),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green, // Assign color
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Average'),
                          const SizedBox(width: 20),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue, // Assign color
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Current'),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Overall: 80%',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Consitancy: 70%',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  )
                ],
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 300,
                  width: 600,
                  child: Center(
                    child: _radarData.length > 0
                        ? RadarChartWidget(
                            subjectsData: _radarData,
                          )
                        : const SizedBox(),
                  ),
                ),
              ),
              const Spacer(),
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

  bool isSaving = false;

  Future<void> saveCardToPDF() async {
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Select location to save PDF',
      fileName: '${_studentName}-report.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    // If the user canceled the save dialog, exit the function
    if (outputPath == null) return;
    setState(() {
      isSaving = true; // Show the progress indicator
    });

    final pdf = pw.Document();
    var container = verticalCardPrint();

    final screenshotImage = await _screenshotController.captureFromWidget(
      InheritedTheme.captureAll(context, Material(child: container)),
      pixelRatio: 2,
    );

    if (screenshotImage != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginTop: 20,
            marginBottom: 20,
            marginLeft: 50,
            marginRight: 50,
          ), // Remove margins
          build: (context) {
            return pw.Center(
              child: pw.Image(
                width: PdfPageFormat.a4.width,
                fit: pw.BoxFit.fitHeight,
                pw.MemoryImage(screenshotImage),
              ),
            );
          },
        ),
      );

      // final outputDir = Platform.isWindows
      //     ? Directory.systemTemp
      //     : await getTemporaryDirectory();

      // final outputPath =
      //     path.join("C:/Users/aswin/OneDrive/Desktop", 'GradeCard.pdf');
      final outputFile = File(outputPath);

      try {
        await outputFile.writeAsBytes(await pdf.save());
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: $outputPath'),
            duration: const Duration(seconds: 2),
          ),
        );
      } on FileSystemException catch (e) {
        // Handle file access errors (e.g., if file is in use)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Unable to save PDF'),
            duration: Duration(seconds: 3),
          ),
        );
        print('Error saving PDF: $e');
      }
    } else {
      print("Error capturing screenshot");
    }
    setState(() {
      isSaving = false; // Hide the progress indicator
    });
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        if (isSaving)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _screenWidth > 1200
                  ? (_isHorizontal ? _screenWidth * .75 : 600)
                  : 700,
              height: _screenWidth > 1200 ? (_isHorizontal ? 650 : 800) : 800,
              child: _screenWidth > 1200
                  ? (_isHorizontal ? horizontalCard() : verticalCard())
                  : verticalCard(), // Target widget to capture
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isHorizontal = !_isHorizontal;
                          });
                        },
                        icon: Icon(
                          _isHorizontal
                              ? Icons.vertical_split
                              : Icons.horizontal_split,
                          size: 30,
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            saveCardToPDF();
                          },
                          icon: const Icon(
                            Icons.print,
                            size: 30,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAndSaveImage() async {
    final pickedImagePath = await pickImage();
    if (pickedImagePath != null) {
      final savedImagePath = await saveImage(pickedImagePath);
      setState(() {
        photoUrl = savedImagePath!;
        print(" image saved at $photoUrl");
      });
    }
  }

  Future<Directory> getAppImageDirPath() async {
    // Get the application's documents directory
    final documentsDir = await getApplicationDocumentsDirectory();
    final accYear =
        Provider.of<UserCoice>(context, listen: false).selectedAcadamicYear;

    // Create the `one_zero_insight/data` directory structure
    final imgDir = Directory(path.join(
        documentsDir.path, 'one_zero_insight', 'Images', accYear, _className));

    // Ensure the directory structure exists
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }

    return imgDir;
  }

  Future<String?> saveImage(String imagePath) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      // final imageDir = Directory(path.join(documentsDir.path, 'images'));
      final imageDir = await getAppImageDirPath();
      if (!await imageDir.exists()) {
        await imageDir.create();
      }

      // final fileName = path.basename(imagePath);
      final fileName =
          "${_studentName}-${widget.studentId}-${DateTime.timestamp()}.jpg"
              .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final savedImagePath = path.join(imageDir.path, fileName);

      final imageFile = File(imagePath);
      await imageFile.copy(savedImagePath);
      return savedImagePath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  Future<String?> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }
    return null;
  }

  void updateStudentsList() async {
    String classId =
        Provider.of<ClassPageValues>(context, listen: false).classId;
    List<Map<String, dynamic>> studentsList =
        await _dbHelper.getStudentsOfClass(classId);
    Provider.of<ClassPageValues>(context, listen: false)
        .setStudentsListToShow(studentsList);
  }
}
