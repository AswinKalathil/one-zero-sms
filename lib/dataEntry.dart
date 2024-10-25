import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/constants.dart';
import 'package:uuid/uuid.dart';

class DataEntryPage extends StatefulWidget {
  final InputTableMetadata metadata;
  final String classId;
  // Parameter

  // Constructor accepting the headers list
  DataEntryPage({Key? key, required this.metadata, required this.classId})
      : super(key: key);
  @override
  _DataEntryPageState createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  late List<String> headers; // Use late initialization
  late List<double> columnLengths;
  String maxId = '';

  List<Map<String, TextEditingController>> rowTextEditingControllers = [];
  List<List<FocusNode>> focusNodes = [];

  @override
  void initState() {
    super.initState();
    // Add ID column
    headers = widget.metadata.columnNames; // Initialize headers
    columnLengths = widget.metadata.columnLengths;
    // setMaxId();
    for (var i = 0; i < 1; i++) {
      _addNewRow();
    }
  }

  // void setMaxId() async {
  //   DatabaseHelper dbHelper = DatabaseHelper();
  //   maxId = await dbHelper.getMaxId(widget.metadata.tableName);

  //   setState(() {
  //     maxId = maxId;
  //   });
  // }

  void _addNewRow() {
    setState(() {
      var controllers = <String, TextEditingController>{};
      var nodes = <FocusNode>[];

      for (var header in headers) {
        if (header != 'Remove') {
          controllers[header] = TextEditingController();
          nodes.add(FocusNode());
        }
      }

      rowTextEditingControllers.add(controllers);
      focusNodes.add(nodes);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (nodes.isNotEmpty) {
          FocusScope.of(context).requestFocus(nodes[1]);
        }
      });
    });
  }

  Future<void> _onSubmit() async {
    DatabaseHelper dbHelper = DatabaseHelper();

    int insertionSuccess = 0;
    for (var row in rowTextEditingControllers) {
      if (row.values.any((controller) => controller.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all the fields for each row.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    List<Map<String, String>> data = rowTextEditingControllers.map((row) {
      return row
          .map((key, controller) => MapEntry(key, controller.text.trim()));
    }).toList();
    // Insert data to the database

    if (widget.metadata.tableName == 'class_table') {
      // var check1 = -1;
      // var check2 = -1;
      // // prepare data for class table
      // var subjectId = await dbHelper.getMaxId('subject_table');
      // for (var row in data) {
      //   // Insert data to the database
      //   Map<String, dynamic> classData = {
      //     'id': row['ID']!,
      //     'class_name': row['Class Name']!,
      //     'academic_year': row['Academic Year']!,
      //   };
      //   check1 = await dbHelper.insertToTable('class_table', classData);
      //   var subjects = row['Subjects']!.split(',');
      //   for (var subject in subjects) {
      //     Map<String, dynamic> subjectData = {
      //       'id': subjectId,
      //       'subject_name': subject,
      //       'class_id': row['ID']!,
      //     };
      //     check2 = await dbHelper.insertToTable('subject_table', subjectData);
      //     subjectId++;
      //   }
      // }
      // if (check1 == -1 && check2 == -1) {
      //   insertionSuccess = 0;
      // } else {
      //   insertionSuccess = 1;
      // }
    } else if (widget.metadata.tableName == 'student_table') {
      var uuid = Uuid();
      print("Student table data $data");
      for (var row in data) {
        String straemId =
            await dbHelper.getStreamId(row['Stream Name']!, widget.classId);

        if (straemId == '') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stream not found!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        Map<String, dynamic> studentData = {
          'id': uuid.v4(),
          'student_name': row['Student Name']!,
          'stream_id': straemId,
          'photo_id': '-',
          'gender': (row['Gender']!),
          'parent_phone': row['Parent Phone']!,
          'school_name': row['School Name']!,
        };
        var check = -1;
        check = await dbHelper.insertToTable('student_table', studentData);

        if (check == -1) {
          insertionSuccess = 0;
        } else {
          insertionSuccess = 1;
        }
      }
    }

    if (insertionSuccess == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data submission failed!'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // setMaxId();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        rowTextEditingControllers.clear();
        focusNodes.clear();
        _addNewRow();
      });
    }
  }

  void _handleKeyEvent(FocusNode currentFocus, FocusNode? nextFocus) {
    if (nextFocus != null) {
      currentFocus.unfocus();
      FocusScope.of(context).requestFocus(nextFocus);
    }
  }

  List<bool> _selections = [true, false];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height * 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.start,
            //     children: [
            //       SizedBox(
            //           width: 300,
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               ElevatedButton(
            //                 style: ElevatedButton.styleFrom(
            //                   backgroundColor: _selections[0]
            //                       ? Theme.of(context).primaryColor
            //                       : Colors.grey[300],
            //                   foregroundColor:
            //                       _selections[0] ? Colors.white : Colors.black,
            //                 ),
            //                 onPressed: () {
            //                   setState(() {
            //                     _selections = [true, false];
            //                     initializeStreamNames(widget.classId);
            //                   });
            //                 },
            //                 child: const Text('HSS'),
            //               ),
            //               const SizedBox(
            //                   width: 16), // Space between the buttons
            //               ElevatedButton(
            //                 style: ElevatedButton.styleFrom(
            //                   backgroundColor: _selections[1]
            //                       ? Theme.of(context).primaryColor
            //                       : Colors.grey[300],
            //                   foregroundColor:
            //                       _selections[1] ? Colors.white : Colors.black,
            //                 ),
            //                 onPressed: () {
            //                   setState(() {
            //                     _selections = [false, true];
            //                     initializeStreamNames(widget.classId);
            //                   });
            //                 },
            //                 child: const Text('HS'),
            //               ),
            //             ],
            //           )),
            //       const SizedBox(width: 20),
            //     ],
            //   ),
            // ),

            const SizedBox(height: 20),
            Divider(
              color: Theme.of(context).canvasColor, // Line color
              thickness: 2, // Line thickness
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16.0, // Space betweSen columns
                    border: const TableBorder(
                      verticalInside: BorderSide(color: Colors.grey, width: 1),
                    ),
                    headingRowColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      return Theme.of(context)
                          .primaryColor; // Header background color
                    }),
                    columns: headers.map((header) {
                      return DataColumn(
                        label: _buildHeaderCell(header,
                            width: columnLengths[headers.indexOf(header)]),
                      );
                    }).toList(),
                    rows: List<DataRow>.generate(
                      rowTextEditingControllers.length,
                      (rowIndex) => DataRow(
                        color: WidgetStateProperty.resolveWith<Color>((states) {
                          return (Theme.of(context).brightness ==
                                  Brightness.light)
                              ? (rowIndex % 2 == 0
                                  ? Colors.white
                                  : Colors.grey.shade200)
                              : (rowIndex % 2 == 0
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade700);
                        }),
                        cells: headers.map((header) {
                          if (header == 'Remove') {
                            return DataCell(
                              IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.black),
                                onPressed: () {
                                  setState(() {
                                    rowTextEditingControllers
                                        .removeAt(rowIndex);
                                    focusNodes.removeAt(rowIndex);
                                  });
                                },
                              ),
                            );
                          } else if (header == 'Save') {
                            return DataCell(
                              IconButton(
                                icon: const Icon(Icons.save,
                                    color: Color.fromRGBO(241, 167, 161, .5)),
                                onPressed: () {
                                  setState(() {
                                    rowTextEditingControllers
                                        .removeAt(rowIndex);
                                    focusNodes.removeAt(rowIndex);
                                  });
                                },
                              ),
                            );
                          } else if (header == 'ID') {
                            rowTextEditingControllers[rowIndex][header]!.text =
                                (rowIndex + 1).toString();

                            return DataCell(
                              Container(
                                width: double.infinity,
                                child: Text((rowIndex + 1).toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            );
                          } else if (header == 'Parent Phone') {
                            int cellIndex = headers.indexOf(header);

                            return DataCell(
                              Container(
                                width: double.infinity,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  controller:
                                      rowTextEditingControllers[rowIndex]
                                          [header]!,
                                  focusNode: focusNodes[rowIndex][cellIndex],
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter
                                        .digitsOnly, // Restrict input to digits only
                                  ],
                                  onChanged: (value) {
                                    if (value.length == 10) {
                                      // Move to the next focus node if input is valid (10 digits)
                                      focusNodes[rowIndex][cellIndex].unfocus();
                                      _addNewRow();
                                    }
                                  },
                                  onSubmitted: (value) {
                                    if (value.length == 10) {
                                      // Move to the next focus node if input is valid (10 digits)
                                      _addNewRow();
                                    } else {
                                      // Show error if input is not valid (not 10 digits)
                                      focusNodes[rowIndex][cellIndex]
                                          .requestFocus();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please enter a valid 10-digit phone number.'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          } else if (header == 'Gender') {
                            int cellIndex = headers.indexOf(header);

                            return DataCell(
                              Container(
                                width: double.infinity,
                                child: StatefulBuilder(
                                  builder: (context, setState) {
                                    return DropdownButtonFormField<String>(
                                      focusNode: focusNodes[rowIndex]
                                          [cellIndex],
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.grey)),
                                        border: InputBorder.none,
                                      ),
                                      value: rowTextEditingControllers[rowIndex]
                                                  [header]!
                                              .text
                                              .isNotEmpty
                                          ? rowTextEditingControllers[rowIndex]
                                                  [header]!
                                              .text
                                          : null, // Get the current value from the controller
                                      items: ['M', 'F', 'Other']
                                          .map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                                fontWeight: FontWeight.normal),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          if (newValue != null) {
                                            // Update the controller with the selected gender
                                            rowTextEditingControllers[rowIndex]
                                                    [header]!
                                                .text = newValue;
                                            focusNodes[rowIndex][cellIndex + 1]
                                                .requestFocus();
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          } else if (header == 'Stream Name') {
                            int cellIndex = headers.indexOf(header);
                            if (rowTextEditingControllers[rowIndex][header]!
                                    .text
                                    .isEmpty &&
                                STREAM_NAMES.length > 0) {
                              rowTextEditingControllers[rowIndex][header]!
                                  .text = STREAM_NAMES[0];
                            }

                            return DataCell(
                              Container(
                                width: double.infinity,
                                child: StatefulBuilder(
                                  builder: (context, setState) {
                                    return DropdownButtonFormField<String>(
                                      focusNode: focusNodes[rowIndex]
                                          [cellIndex],
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.grey)),
                                        border: InputBorder.none,
                                      ),
                                      value: rowTextEditingControllers[rowIndex]
                                                  [header]!
                                              .text
                                              .isNotEmpty
                                          ? rowTextEditingControllers[rowIndex]
                                                  [header]!
                                              .text
                                          : null, // Get the current value from the controller
                                      items: STREAM_NAMES.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value,
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.normal)),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          if (newValue != null) {
                                            // Update the controller with the selected gender
                                            rowTextEditingControllers[rowIndex]
                                                    [header]!
                                                .text = newValue;
                                            focusNodes[rowIndex][cellIndex + 1]
                                                .requestFocus();
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          } else {
                            int cellIndex = headers.indexOf(header);
                            return _buildDataCell(
                              rowTextEditingControllers[rowIndex][header]!,
                              focusNodes[rowIndex][cellIndex],
                              cellIndex < focusNodes[rowIndex].length - 1
                                  ? focusNodes[rowIndex][cellIndex + 1]
                                  : null,
                              columnLengths[cellIndex],
                            );
                          }
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Spacer(),
                Padding(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child:
                      TextButton(onPressed: _addNewRow, child: Text("New Row")),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 60.0),
                  child: CustomButton(
                      text: "Save",
                      onPressed: () {
                        _onSubmit();
                      },
                      width: 100,
                      height: 40,
                      textColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DataCell _buildDataCell(
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? nextFocus,
    double columnLength,
  ) {
    return DataCell(
      Container(
        width: columnLength, // Fixed width for column
        child: TextField(
          controller: controller,
          focusNode: currentFocus,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          maxLines: 1,
          onSubmitted: (value) {
            if (nextFocus == null) {
              if (focusNodes.last == currentFocus) {
                _addNewRow();
                return;
              } else {
                _handleKeyEvent(currentFocus, nextFocus);
              }
              _addNewRow();
              return;
            } else {
              _handleKeyEvent(currentFocus, nextFocus);
            }
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, {double? width}) {
    return Center(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
