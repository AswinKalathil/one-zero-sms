// import 'package:flutter/material.dart';
// import 'package:one_zero/appProviders.dart';
// import 'package:one_zero/constants.dart';
// import 'package:one_zero/custom-widgets.dart';
// import 'package:one_zero/database_helper.dart';
// import 'package:one_zero/pieChart.dart';
// import 'package:provider/provider.dart';
// import 'package:screenshot/screenshot.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'dart:io'; // For Platform, Directory, and File
// import 'package:pdf/pdf.dart'; // For PDF generationimport 'package:file_picker/file_picker.dart';
// import 'package:file_picker/file_picker.dart';

// import 'dart:io';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';

// class Pdfgeneration extends StatefulWidget {
//   String studentId;

//   Pdfgeneration({Key? key, required this.studentId}) : super(key: key);
//   @override
//   PdfgenerationState createState() => PdfgenerationState();
// }

// class PdfgenerationState extends State<Pdfgeneration> {
//   String _studentName = '';

//   String _className = '';
//   String _classId = '';
//   String studentAcadamicYear = '';
//   String currentMonth = DateTime.now().month.toString();
//   String photoUrl = '';
//   String errorPhotoUrl = 'assets/ml.jpg';
//   String _gender = '';
//   String schoolName = '';
//   List<Map<String, dynamic>> subjects = [];
//   List<Map<String, dynamic>> _radarData = [];
//   DatabaseHelper _dbHelper = DatabaseHelper();
//   Map<String, dynamic> studentData = {};

//   @override
//   void initState() {
//     super.initState();

//     fetchStudentData();
//   }

//   void updateStudentId(String newStudentId) {
//     setState(() {
//       widget.studentId = newStudentId;
//     });
//   }

//   Future<void> fetchStudentData() async {
//     if (widget.studentId == 0) {
//       print("Student id is 0");
//       return;
//     }
//     List<Map<String, dynamic>> studentData =
//         await _dbHelper.getStudentData(widget.studentId);
//     if (studentData.isEmpty) {
//       return;
//     }

//     List<Map<String, dynamic>> resultsfromDb =
//         await _dbHelper.getGradeCard(widget.studentId);
//     if (resultsfromDb.isEmpty) {
//       throw Exception("No data found for student name: ${widget.studentId}");
//     }
//     // print("Results received from db: $resultsfromDb");
//     List<Map<String, dynamic>> results = getLatestScores(resultsfromDb);

//     if (studentData.isNotEmpty) {
//       if (mounted) {
//         setState(() {
//           _studentName = studentData.first['student_name'] as String? ?? '-';
//           _className = studentData.first['class_name'] as String? ?? '-';
//           schoolName = studentData.first['school_name'] as String? ?? '-';
//           photoUrl = studentData.first['photo_path'];
//           _gender = studentData.first['gender'] as String? ?? 'M';

//           if (!File(photoUrl).existsSync()) {
//             errorPhotoUrl =
//                 (_gender == 'M' ? 'assets/ml.jpg' : 'assets/fl.jpg');
//           }

//           _classId =
//               Provider.of<ClassPageValues>(context, listen: false).classId;
//           initializeStreamNames(_classId);
//         });
//       }
//     }

//     if (results.isNotEmpty) {
//       // Using a standard for loop to handle async operations correctly
//       for (var element in results) {
//         int marks;
//         int maxMarks;

//         if (element['score'] == '-') {
//           marks = 0;
//         } else {
//           marks = element['score'] ?? 0;
//         }
//         if (element['max_mark'] == '-') {
//           maxMarks = 0;
//         } else {
//           maxMarks = element['max_mark'] ?? 0;
//         }

//         // Fetch the average score for the current subject
//         var avg = await _dbHelper.getStudentSubjectAverage(
//             widget.studentId, element['subject_id']);

//         // Ensure avg is a double and handle null values
//         double averageScore = (avg is double)
//             ? avg
//             : 0.0; // Default to 0.0 if avg is null or not a double
//         double currentPercentage = (marks * 100 / maxMarks).isNaN ||
//                 (marks * 100 / maxMarks).isInfinite
//             ? 0.0
//             : (marks * 100 / maxMarks);
//         // Update _radarData with the new average score
//         _radarData.add({
//           'subject': element['subject_name'],
//           'marks': [averageScore, currentPercentage],
//         });
//       }

// // Once the loop is done, you can safely print the data

//       subjects = results.map((row) {
//         final subjectName = row['subject_name'] as String? ?? '-';

//         final latestScore = (row['score'] != null && row['score'] != '-')
//             ? (row['score'] is int
//                 ? row['score']
//                 : int.tryParse(row['score'] as String) ?? 0)
//             : '-'; // Replaced with '-' if null or invalid

//         final maxMark = (row['max_mark'] != null && row['max_mark'] != -1)
//             ? (row['max_mark'] is int
//                 ? row['max_mark']
//                 : int.tryParse(row['max_mark'] as String) ?? '-')
//             : '-'; // Replaced with '-' if null or invalid

//         // Handle date parsing
//         String dateFormatted = '';
//         DateTime? date = DateTime.tryParse(row['test_date']?.toString() ?? '');

//         // Check if the date is not null
//         if (date != null) {
//           // Format the date as 'dd-MM-yyyy'
//           dateFormatted =
//               '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
//         } else {
//           // Fallback for null dates
//           dateFormatted = '-';
//         }

//         return {
//           'subject': subjectName,
//           'maxMarks': maxMark.toString(),
//           'marks': latestScore == '' ? '-' : latestScore.toString(),
//           'grade': _calculateGrade(latestScore == '-' ? -1 : latestScore,
//               maxMark is String ? -1 : maxMark),
//           'date': dateFormatted,
//         };
//       }).toList();
//       if (mounted) {
//         setState(() {
//           subjects;
//         });
//       }
//     }
//     if (mounted)
//       setState(() {
//         _radarData;
//       });
//   }

//   List<Map<String, dynamic>> getLatestScores(List<Map<String, dynamic>> tests) {
//     final Map<String, Map<String, dynamic>> latestScores = {};
//     final Set<String> subjectsSet = {}; // Track all subjects encountered

//     for (var test in tests) {
//       String subject = test['subject_name'];
//       String subjectId = test['subject_id'] ?? '';
//       String testId = test['test_id'] ?? '';

//       // Handle score as an int, either from int or parsed from string
//       int? score = test['score'] is int
//           ? test['score']
//           : int.tryParse(test['score'] as String);

//       // Handle max_mark, ensuring it's treated as an int or remains null
//       int? maxMark = test['max_mark'] is int ? test['max_mark'] : null;

//       // Handle test_date
//       DateTime? testDate;

//       if (test['test_date'] != null) {
//         // Check if the test_date is already a DateTime
//         if (test['test_date'] is DateTime) {
//           testDate = test['test_date']
//               as DateTime; // Directly assign if it's already a DateTime
//         } else if (test['test_date'] is String) {
//           // If it's a String, parse it to DateTime
//           testDate = DateTime.tryParse(test['test_date'] as String);
//         } else {
//           // Handle unexpected types
//           print(
//               'Unexpected type for test_date: ${test['test_date'].runtimeType}');
//         }
//       }

//       // Mark the subject as processed
//       subjectsSet.add(subject);

//       // Check for valid test entry
//       if (testDate != null && maxMark != null) {
//         var existingEntry = latestScores[subject];

//         DateTime? existingDate = existingEntry?['test_date'] != null
//             ? DateTime.parse(existingEntry?['test_date'])
//             : null;

//         bool isAfterComparison =
//             existingDate == null || testDate.isAfter(existingDate!);

//         // Update the entry only if it doesn't exist or if the current testDate is more recent
//         if (isAfterComparison == true) {
//           latestScores[subject] = {
//             'subject_name': subject,
//             'subject_id': subjectId,
//             'score': score, // Keep score as int
//             'max_mark': maxMark, // Keep max_mark as int or null
//             'test_date': testDate.toIso8601String(),
//             'test_id': testId // Store as String for output
//           };
//         }
//       }
//     }

//     // Ensure all subjects are represented, even if no tests were conducted
//     for (String subject in subjectsSet) {
//       if (!latestScores.containsKey(subject)) {
//         latestScores[subject] = {
//           // Placeholder for no test conducted
//           'subject_name': subject,
//           'subject_id': '-', // Indicate no test conducted
//           'score': '-', // Indicate no test conducted
//           'max_mark': '-', // Indicate no test conducted
//           'test_date': null // No date available
//         };
//       }
//     }

//     // Convert latest scores map to a list
//     return latestScores.values.toList();
//   }

//   String _calculateGrade(int score, int maxMark) {
//     if (maxMark == -1) {
//       return '-';
//     } else if (score == -1) {
//       return 'Absent';
//     }

//     // print('Score: $score, Max Mark: $maxMark');

//     double percentage = (score / maxMark) * 100;

//     if (percentage >= 90) return 'A+';
//     if (percentage >= 80) return 'A';
//     if (percentage >= 70) return 'B+';
//     if (percentage >= 60) return 'B';
//     if (percentage >= 50) return 'C+';
//     if (percentage >= 40) return 'C';
//     return 'F';
//   }

//   ScreenshotController _screenshotController = ScreenshotController();
//   Widget verticalCardPrint() {
//     bool isFullApluss = false;
//     int aplussCount = 0;

//     for (var subject in subjects) {
//       if (subject['grade'] == 'A+') {
//         aplussCount++;
//       }
//     }
//     isFullApluss = aplussCount == subjects.length && aplussCount > 0;
//     double rowheight = 25.0;
//     int rowIndex = 0;

//     return SizedBox(
//       child: AspectRatio(
//         aspectRatio: 210 / 345, // A4 aspect ratio (210mm x 297mm)
//         // aspectRatio: 297 / 210,
//         child: Container(
//           // padding: const EdgeInsets.symmetric(horizontal: 50.0),
//           color: Colors.white,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(10),
//                   child: Text("Report Card",
//                       style:
//                           TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                 ),
//               ),
//               Stack(children: [
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: [
//                         SizedBox(
//                             width: 80,
//                             height: 100,
//                             child: Image.file(
//                               File(
//                                   photoUrl!), // Display the image without adding it as an asset
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return Image.asset(
//                                   errorPhotoUrl,
//                                   fit: BoxFit.cover,
//                                 );
//                               },
//                             )),
//                         Padding(
//                           padding:
//                               const EdgeInsets.only(left: 10.0, bottom: 10),
//                           child: SizedBox(
//                             width: 270,
//                             height: 100,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 Text(
//                                   _studentName,
//                                   style: const TextStyle(
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                                 Text(
//                                   _className,
//                                   style: const TextStyle(fontSize: 16),
//                                 ),
//                                 Text(
//                                   schoolName,
//                                   style: const TextStyle(fontSize: 16),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const Spacer(),
//                         getLogoColored(10, .6),
//                       ],
//                     ),
//                     const Align(
//                       alignment: Alignment.topLeft,
//                       child: Text(
//                         'Latest Grades',
//                         style: TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ],
//                 ),
//                 isFullApluss
//                     ? Positioned(
//                         right: 100,
//                         top: 20,
//                         child: Padding(
//                           padding: const EdgeInsets.only(left: 10, top: 20.0),
//                           child: Image.asset(
//                             'assets/apluss.png',
//                             width: 100,
//                             height: 100,
//                           ),
//                         ),
//                       )
//                     : const SizedBox(),
//               ]),
//               const SizedBox(height: 8.0),
//               Align(
//                 alignment: Alignment.topCenter,
//                 child: SizedBox(
//                   height: 50 + subjects.length * rowheight,
//                   width: 500,
//                   child: Table(
//                     border: TableBorder.all(color: Colors.grey),
//                     columnWidths: const {
//                       0: FlexColumnWidth(2),
//                       1: FlexColumnWidth(6),
//                       2: FlexColumnWidth(4),
//                       3: FlexColumnWidth(3),
//                       4: FlexColumnWidth(3),
//                     },
//                     children: [
//                       const TableRow(
//                         decoration: BoxDecoration(
//                           color: Color.fromRGBO(0, 0, 0, 0.05),
//                         ),
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(5),
//                             child: Center(
//                               child: FittedBox(
//                                 child: Text(
//                                   'SL No.',
//                                   style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(5),
//                             child: Center(
//                               child: FittedBox(
//                                 child: Text(
//                                   'Subject',
//                                   style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(5),
//                             child: Center(
//                               child: FittedBox(
//                                 child: Text(
//                                   'Marks',
//                                   style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(5),
//                             child: Center(
//                               child: FittedBox(
//                                 child: Text(
//                                   'Grade',
//                                   style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(5),
//                             child: Center(
//                               child: Text(
//                                 'Date',
//                                 style: TextStyle(
//                                     fontSize: 12, fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       ...subjects.map(
//                         (subject) {
//                           rowIndex++;
//                           return TableRow(
//                             children: [
//                               Container(
//                                 height: rowheight,
//                                 padding: const EdgeInsets.all(5.5),
//                                 child:
//                                     FittedBox(child: Text(rowIndex.toString())),
//                               ),
//                               Container(
//                                 height: rowheight,
//                                 padding: const EdgeInsets.symmetric(
//                                     vertical: 5, horizontal: 5),
//                                 child: Align(
//                                   alignment: Alignment.centerLeft,
//                                   child: FittedBox(
//                                       child: Text(
//                                     subject['subject'] ?? '',
//                                     textAlign: TextAlign.left,
//                                   )),
//                                 ),
//                               ),
//                               Container(
//                                 height: rowheight,
//                                 padding: const EdgeInsets.all(5),
//                                 child: FittedBox(
//                                   child: Text(
//                                       "  ${subject['marks']} / ${subject['maxMarks']}" ??
//                                           '-'),
//                                 ),
//                               ),
//                               Container(
//                                 height: rowheight,
//                                 padding: const EdgeInsets.all(5),
//                                 child: FittedBox(
//                                     child: Text(subject['grade'] ?? '')),
//                               ),
//                               Container(
//                                 height: rowheight,
//                                 padding: const EdgeInsets.all(5.5),
//                                 child: FittedBox(
//                                     child: Text(subject['date'] ?? '')),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             width: 15,
//                             height: 15,
//                             decoration: const BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Colors.green, // Assign color
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           const Text('Average'),
//                           const SizedBox(width: 20),
//                         ],
//                       ),
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       Row(
//                         children: [
//                           Container(
//                             width: 15,
//                             height: 15,
//                             decoration: const BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Colors.blue, // Assign color
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           const Text('Current'),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const Spacer(),
//                   const Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         'Overall: 80%',
//                         textAlign: TextAlign.end,
//                         style: TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         'Consitancy: 70%',
//                         textAlign: TextAlign.end,
//                         style: TextStyle(fontSize: 12),
//                       ),
//                     ],
//                   )
//                 ],
//               ),
//               Align(
//                 alignment: Alignment.center,
//                 child: Container(
//                   height: 300,
//                   width: 600,
//                   child: Center(
//                     child: _radarData.length > 0
//                         ? RadarChartWidget(
//                             subjectsData: _radarData,
//                           )
//                         : const SizedBox(),
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     ' ${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}',
//                     style: const TextStyle(fontSize: 10),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   bool isSaving = false;

//   Future<void> generatePDF(String directoryPath) async {
//     if (directoryPath == null || directoryPath.isEmpty) return; // User canceled

//     // Generate a unique file name for each student
//     String outputPath = '$directoryPath/$_studentName-report.pdf';

//     setState(() {
//       isSaving = true; // Show the progress indicator
//     });

//     // If the user canceled the save dialog, exit the function
//     if (outputPath == null) return;
//     setState(() {
//       isSaving = true; // Show the progress indicator
//     });

//     final pdf = pw.Document();
//     var container = verticalCardPrint();

//     final screenshotImage = await _screenshotController.captureFromWidget(
//       InheritedTheme.captureAll(context, Material(child: container)),
//       pixelRatio: 2,
//     );

//     if (screenshotImage != null) {
//       pdf.addPage(
//         pw.Page(
//           pageFormat: PdfPageFormat.a4.copyWith(
//             marginTop: 20,
//             marginBottom: 20,
//             marginLeft: 50,
//             marginRight: 50,
//           ), // Remove margins
//           build: (context) {
//             return pw.Center(
//               child: pw.Image(
//                 width: PdfPageFormat.a4.width,
//                 fit: pw.BoxFit.fitHeight,
//                 pw.MemoryImage(screenshotImage),
//               ),
//             );
//           },
//         ),
//       );

//       final outputFile = File(outputPath);

//       try {
//         await outputFile.writeAsBytes(await pdf.save());
//         // Show success feedback
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('PDF saved to: $outputPath'),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       } on FileSystemException catch (e) {
//         // Handle file access errors (e.g., if file is in use)
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Error: Unable to save PDF'),
//             duration: Duration(seconds: 3),
//           ),
//         );
//         print('Error saving PDF: $e');
//       }
//     } else {
//       print("Error capturing screenshot");
//     }
//     setState(() {
//       isSaving = false; // Hide the progress indicator
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }
