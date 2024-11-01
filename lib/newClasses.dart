// import 'package:flutter/material.dart';
// import 'package:one_zero/custom-widgets.dart';
// import 'package:one_zero/database_helper.dart';
// import 'package:one_zero/constants.dart';

// class DataEntryPage extends StatefulWidget {
//   final InputTableMetadata metadata;
//   // Parameter

//   // Constructor accepting the headers list
//   DataEntryPage({Key? key, required this.metadata}) : super(key: key);
//   @override
//   _DataEntryPageState createState() => _DataEntryPageState();
// }

// class _DataEntryPageState extends State<DataEntryPage> {
//   late List<String> headers; // Use late initialization
//   late List<double> columnLengths;
//   int maxId = 0;

//   List<Map<String, TextEditingController>> rowTextEditingControllers = [];
//   List<List<FocusNode>> focusNodes = [];

//   @override
//   void initState() {
//     super.initState();
//     // Add ID column
//     headers = widget.metadata.columnNames; // Initialize headers
//     columnLengths = widget.metadata.columnLengths;
//     setMaxId();
//     _addNewRow();
//   }

//   void setMaxId() async {
//     DatabaseHelper dbHelper = DatabaseHelper();
//     maxId = await dbHelper.getMaxId(widget.metadata.tableName);

//     setState(() {
//       print("MAX ID: $maxId");
//       maxId = maxId;
//     });
//   }

//   void _addNewRow() {
//     setState(() {
//       var controllers = <String, TextEditingController>{};
//       var nodes = <FocusNode>[];

//       for (var header in headers) {
//         if (header != 'Actions') {
//           controllers[header] = TextEditingController();
//           nodes.add(FocusNode());
//         }
//       }

//       rowTextEditingControllers.add(controllers);
//       focusNodes.add(nodes);

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (nodes.isNotEmpty) {
//           FocusScope.of(context).requestFocus(nodes[1]);
//         }
//       });
//     });
//   }

//   Future<void> _onSubmit() async {
//     DatabaseHelper dbHelper = DatabaseHelper();
//     // List<Map<String, dynamic>> classDataList = [];
//     // List<Map<String, dynamic>> subjectDataList = [];
//     // Map<String, dynamic> classData = {};
//     // Map<String, dynamic> subjectData = {};
//     int insertionSuccess = 0;
//     for (var row in rowTextEditingControllers) {
//       if (row.values.any((controller) => controller.text.isEmpty)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Please fill in all the fields for each row.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//     }

//     List<Map<String, String>> data = rowTextEditingControllers.map((row) {
//       return row.map((key, controller) => MapEntry(key, controller.text));
//     }).toList();
//     print(data);
//     // Insert data to the database

//     if (widget.metadata.tableName == 'class_table') {
//       var check1 = 0;
//       var check2 = 0;
//       // prepare data for class table
//       var subjectId = await dbHelper.getMaxId('subject_table');
//       for (var row in data) {
//         // Insert data to the database
//         Map<String, dynamic> classData = {
//           'id': row['ID']!,
//           'class_name': row['Class Name']!,
//           'academic_year': row['Academic Year']!,
//         };
//         check1 = await dbHelper.insertToTable('class_table', classData);
//         var subjects = row['Subjects']!.split(',');
//         for (var subject in subjects) {
//           Map<String, dynamic> subjectData = {
//             'id': subjectId,
//             'subject_name': subject,
//             'class_id': row['ID']!,
//           };
//           check2 = await dbHelper.insertToTable('subject_table', subjectData);
//           subjectId++;
//         }
//       }
//       if (check1 == 0 && check2 == 0) {
//         insertionSuccess = 0;
//       } else {
//         insertionSuccess = 1;
//       }
//     } else if (widget.metadata.tableName == 'stream_table') {
//       var check1 = 0;
//       var check2 = 0;
//       for (var row in data) {
//         // Insert data to the database
//         Map<String, dynamic> streamData = {
//           'id': row['ID']!,
//           'stream_name': row['Stream Name']!,
//           'class_id': row['Class ID']!,
//         };
//         check1 = await dbHelper.insertToTable('stream_table', streamData);
//         var subjects = row['Subjects']!.split(',');
//         for (var subject in subjects) {
//           int subjectidForStream = await dbHelper.getSubjectId(subject);
//           int idForSSTable = await dbHelper.getMaxId('stream_subjects_table');

//           Map<String, dynamic> subjectData = {
//             'id': idForSSTable + 1,
//             'stream_id': row['ID']!,
//             'subject_id': subjectidForStream,
//           };
//           print(subjectData);
//           check2 = await dbHelper.insertToTable(
//               'stream_subjects_table', subjectData);
//         }
//       }
//       if (check1 == 0 && check2 == 0) {
//         insertionSuccess = 0;
//       } else {
//         insertionSuccess = 1;
//       }
//     } else if (widget.metadata.tableName == 'student_table') {
//       print("Student table data $data");
//       for (var row in data) {
//         int straemId = await dbHelper.getStreamId(row['Stream name']!);
//         if (straemId == 0) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Stream not found!'),
//               backgroundColor: Colors.red,
//             ),
//           );
//           return;
//         }
//         Map<String, dynamic> studentData = {
//           'id': row['ID']!,
//           'student_name': row['Student Name']!,
//           'stream_id': straemId,
//           'photo_id': row['Photo path']!,
//           'student_phone': row['Student Phone']!,
//           'parent_name': row['Parent Name']!,
//           'parent_phone': row['Parent Phone']!,
//           'school_name': row['School Name']!,
//         };
//         var check = 0;
//         check = await dbHelper.insertToTable('student_table', studentData);

//         if (check == 0) {
//           insertionSuccess = 0;
//         } else {
//           insertionSuccess = 1;
//         }
//       }
//     }

//     if (insertionSuccess == 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Data submission failed!'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } else {
//       setMaxId();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Data submitted successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }

//     setState(() {
//       rowTextEditingControllers.clear();
//       focusNodes.clear();
//       _addNewRow();
//     });
//   }

//   void _handleKeyEvent(FocusNode currentFocus, FocusNode? nextFocus) {
//     if (nextFocus != null) {
//       currentFocus.unfocus();
//       FocusScope.of(context).requestFocus(nextFocus);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               const SizedBox(
//                 width: 300,
//                 child: Text(
//                   'Enter New Class Details',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               ElevatedButton(
//                 onPressed: _addNewRow,
//                 child: const Text('Add Row'),
//               ),
//               const SizedBox(width: 20),
//               ElevatedButton(
//                 onPressed: _onSubmit,
//                 child: const Text('Submit'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           Expanded(
//             child: SingleChildScrollView(
//               scrollDirection: Axis.vertical,
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: DataTable(
//                   columnSpacing: 16.0, // Space between columns
//                   border: const TableBorder(
//                     verticalInside: BorderSide(color: Colors.grey, width: 1),
//                   ),
//                   headingRowColor:
//                       WidgetStateProperty.resolveWith<Color>((states) {
//                     return Colors.blue.shade100; // Header background color
//                   }),
//                   columns: headers.map((header) {
//                     return DataColumn(
//                       label: _buildHeaderCell(header),
//                     );
//                   }).toList(),
//                   rows: List<DataRow>.generate(
//                     rowTextEditingControllers.length,
//                     (rowIndex) => DataRow(
//                       color: WidgetStateProperty.resolveWith<Color>((states) {
//                         return rowIndex % 2 == 0
//                             ? Colors.grey.shade200
//                             : Colors.white;
//                       }),
//                       cells: headers.map((header) {
//                         if (header == 'Actions') {
//                           return DataCell(
//                             IconButton(
//                               icon: const Icon(Icons.delete,
//                                   color: Color.fromARGB(255, 241, 167, 161)),
//                               onPressed: () {
//                                 setState(() {
//                                   rowTextEditingControllers.removeAt(rowIndex);
//                                   focusNodes.removeAt(rowIndex);
//                                 });
//                               },
//                             ),
//                           );
//                         } else if (header == 'Save') {
//                           return DataCell(
//                             IconButton(
//                               icon: const Icon(Icons.save,
//                                   color: Color.fromARGB(255, 241, 167, 161)),
//                               onPressed: () {
//                                 setState(() {
//                                   rowTextEditingControllers.removeAt(rowIndex);
//                                   focusNodes.removeAt(rowIndex);
//                                 });
//                               },
//                             ),
//                           );
//                         } else if (header == 'ID') {
//                           int rowId = maxId + rowIndex + 1;
//                           rowTextEditingControllers[rowIndex][header]!.text =
//                               rowId.toString();

//                           return DataCell(
//                             Container(
//                               width: double.infinity,
//                               child: Text(rowId.toString(),
//                                   style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black)),
//                             ),
//                           );
//                         } else if (header == 'Stream Name') {
//                           return DataCell(
//                             Container(
//                                 width: double.infinity,
//                                 child: autoFill(
//                                   controller:
//                                       rowTextEditingControllers[rowIndex]
//                                           [header] as TextEditingController,
//                                   optionsList: STREAM_NAMES,
//                                   labelText: '',
//                                   needBorder: false,
//                                   nextFocusNode: focusNodes[rowIndex]
//                                       [headers.indexOf(header) + 1],
//                                 )),
//                           );
//                         } else if (header == 'Subjects') {
//                           return DataCell(
//                             Container(
//                               width: double.infinity,
//                               child: TextField(
//                                 controller: rowTextEditingControllers[rowIndex]
//                                     [header],
//                                 focusNode: focusNodes[rowIndex][1],
//                                 decoration: const InputDecoration(
//                                   border: InputBorder.none,
//                                 ),
//                                 maxLines: 1,
//                                 onSubmitted: (value) {
//                                   _handleKeyEvent(
//                                       focusNodes[rowIndex][1], null);
//                                 },
//                               ),
//                             ),
//                           );
//                         } else {
//                           int cellIndex = headers.indexOf(header);
//                           return _buildDataCell(
//                             rowTextEditingControllers[rowIndex][header]!,
//                             focusNodes[rowIndex][cellIndex],
//                             cellIndex < focusNodes[rowIndex].length - 1
//                                 ? focusNodes[rowIndex][cellIndex + 1]
//                                 : null,
//                             columnLengths[cellIndex],
//                           );
//                         }
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   DataCell _buildDataCell(
//     TextEditingController controller,
//     FocusNode currentFocus,
//     FocusNode? nextFocus,
//     double columnLength,
//   ) {
//     return DataCell(
//       Container(
//         width: columnLength, // Fixed width for column
//         child: TextField(
//           controller: controller,
//           focusNode: currentFocus,
//           decoration: const InputDecoration(
//             border: InputBorder.none,
//           ),
//           maxLines: 1,
//           onSubmitted: (value) {
//             if (nextFocus == null) {
//               _addNewRow();
//               return;
//             } else {
//               _handleKeyEvent(currentFocus, nextFocus);
//             }
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildHeaderCell(String title) {
//     return Center(
//       child: Container(
//         color: Colors.blue.shade100, // Header background color
//         padding: const EdgeInsets.all(8.0),
//         child: Text(
//           title,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }
// }

// class StudentDataCell extends StatelessWidget {
//   final String columnName;
//   final String? studentName;
//   final TextEditingController? scoreController;
//   final FocusNode? focusNode;
//   final int studentId;
//   final VoidCallback? onSubmitted;

//   StudentDataCell({
//     required this.columnName,
//     this.studentName,
//     this.scoreController,
//     this.focusNode,
//     required this.studentId,
//     this.onSubmitted,
//   });

//   @override
//   Widget build(BuildContext context) {
//     switch (columnName) {
//       case 'Student Name':
//         return SizedBox(
//           width: 300,
//           child: Text(
//             studentName ?? '',
//             style: const TextStyle(
//                 fontWeight: FontWeight.bold, color: Colors.black),
//           ),
//         );
//       case 'ID':
//         return SizedBox(
//           width: 50,
//           child: Text(
//             studentId.toString(),
//             style: const TextStyle(
//                 fontWeight: FontWeight.bold, color: Colors.black),
//           ),
//         );
//       case 'Score':
//         return SizedBox(
//           width: 100,
//           child: TextField(
//             controller: scoreController,
//             focusNode: focusNode,
//             decoration: const InputDecoration(
//               border: InputBorder.none,
//             ),
//             keyboardType: TextInputType.number,
//             onSubmitted: (_) => onSubmitted?.call(),
//           ),
//         );
//       default:
//         return const Text('');
//     }
//   }
// }

// List<Map<String, dynamic>> studentList = [];

// class ExamEntry extends StatefulWidget {
//   final int test_id;

//   ExamEntry({Key? key, required this.test_id}) : super(key: key);

//   @override
//   _ExamEntryState createState() => _ExamEntryState();
// }

// class _ExamEntryState extends State<ExamEntry> {
//   late List<String> headers;
//   late List<double> columnLengths;
//   List<TextEditingController> rowTextEditingControllers = [];
//   List<FocusNode> focusNodes = [];
//   int maxId = 0;
//   @override
//   void initState() {
//     super.initState();

//     headers = ['ID', 'Student Name', 'Score'];
//     columnLengths = [100, 300, 100];

//     rowTextEditingControllers.addAll(List.generate(headers.length, (index) {
//       return TextEditingController();
//     }));
//     focusNodes.addAll(List.generate(headers.length, (index) {
//       return FocusNode();
//     }));
//     fetchStudents(widget.test_id);

//     // _addNewRows();
//   }

//   void fetchStudents(int testId) async {
//     DatabaseHelper dbHelper = DatabaseHelper();
//     List<Map<String, dynamic>> students =
//         await dbHelper.getStudentIdsAndNamesByTestId(testId);
//     print("Student list fetched in test score entry tabel $students");
//     setState(() {
//       studentList = students;
//     });
//   }

//   void _addNewRows() {
//     for (var student in studentList) {
//       print(studentList.length);

//       for (var header in headers) {
//         if (header == 'Score') {
//           rowTextEditingControllers.add(TextEditingController());
//           focusNodes.add(FocusNode());
//         }
//       }
//     }
//   }

//   void _moveFocusToNextRow(int currentRowIndex) {
//     if (currentRowIndex + 1 < focusNodes.length) {
//       FocusScope.of(context).requestFocus(focusNodes[currentRowIndex + 1]);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Enter Exam Scores'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.save),
//             onPressed: () {
//               // Save the data

//               var data = rowTextEditingControllers.map((controller) {
//                 return controller.text;
//               }).toList();
//               DatabaseHelper dbHelper = DatabaseHelper();

//               for (int i = 0; i < studentList.length; i++) {
//                 dbHelper.insertToTable('test_score_table', {
//                   'student_id': studentList[i]['student_id'],
//                   'score': data[i].toString(),
//                   'test_id': widget.test_id
//                 });
//               }

//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Data submitted successfully!'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           scrollDirection: Axis.vertical,
//           child: DataTable(
//             columnSpacing: 16.0,
//             border: const TableBorder(
//               verticalInside: BorderSide(color: Colors.grey, width: 1),
//             ),
//             headingRowColor: WidgetStateProperty.resolveWith<Color>((states) {
//               return Colors.blue.shade100;
//             }),
//             columns: headers.map((header) {
//               return DataColumn(
//                 label: Center(
//                   child: Text(
//                     header,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               );
//             }).toList(),
//             rows: List<DataRow>.generate(
//               studentList.length,
//               (rowIndex) {
//                 var student = studentList[rowIndex];
//                 var controller = rowTextEditingControllers[rowIndex];
//                 return DataRow(
//                   color: MaterialStateProperty.resolveWith<Color>((states) {
//                     return rowIndex % 2 == 0
//                         ? Colors.grey.shade100
//                         : Colors.white;
//                   }),
//                   cells: headers.map((header) {
//                     var isScoreColumn = header == 'Score';
//                     return DataCell(
//                       StudentDataCell(
//                         columnName: header,
//                         studentName: header == 'Student Name'
//                             ? student['student_name'] as String
//                             : null,
//                         scoreController: isScoreColumn ? controller : null,
//                         focusNode: isScoreColumn ? focusNodes[rowIndex] : null,
//                         studentId:
//                             header == 'ID' ? student['student_id'] as int : 0,
//                         onSubmitted: isScoreColumn
//                             ? () => _moveFocusToNextRow(rowIndex)
//                             : null,
//                       ),
//                     );
//                   }).toList(),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }