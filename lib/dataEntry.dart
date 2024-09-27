import 'package:flutter/material.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';
import 'package:one_zero/constants.dart';

class DataEntryPage extends StatefulWidget {
  final InputTableMetadata metadata;
  // Parameter

  // Constructor accepting the headers list
  DataEntryPage({Key? key, required this.metadata}) : super(key: key);
  @override
  _DataEntryPageState createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  late List<String> headers; // Use late initialization
  late List<double> columnLengths;
  int maxId = 0;

  List<Map<String, TextEditingController>> rowTextEditingControllers = [];
  List<List<FocusNode>> focusNodes = [];

  @override
  void initState() {
    super.initState();
    // Add ID column
    headers = widget.metadata.columnNames; // Initialize headers
    columnLengths = widget.metadata.columnLengths;
    setMaxId();
    for (var i = 0; i < 1; i++) {
      _addNewRow();
    }
  }

  void setMaxId() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    maxId = await dbHelper.getMaxId(widget.metadata.tableName);

    setState(() {
      maxId = maxId;
    });
  }

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
      var check1 = 0;
      var check2 = 0;
      // prepare data for class table
      var subjectId = await dbHelper.getMaxId('subject_table');
      for (var row in data) {
        // Insert data to the database
        Map<String, dynamic> classData = {
          'id': row['ID']!,
          'class_name': row['Class Name']!,
          'academic_year': row['Academic Year']!,
        };
        check1 = await dbHelper.insertToTable('class_table', classData);
        var subjects = row['Subjects']!.split(',');
        for (var subject in subjects) {
          Map<String, dynamic> subjectData = {
            'id': subjectId,
            'subject_name': subject,
            'class_id': row['ID']!,
          };
          check2 = await dbHelper.insertToTable('subject_table', subjectData);
          subjectId++;
        }
      }
      if (check1 == 0 && check2 == 0) {
        insertionSuccess = 0;
      } else {
        insertionSuccess = 1;
      }
    } else if (widget.metadata.tableName == 'student_table') {
      print("Student table data $data");
      for (var row in data) {
        int straemId = await dbHelper.getStreamId(row['Stream Name']!);
        if (straemId == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stream not found!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        Map<String, dynamic> studentData = {
          'id': row['ID']!,
          'student_name': row['Student Name']!,
          'stream_id': straemId,
          'photo_id': row['Photo Path']!,
          'gender': (row['Gender']!),
          'parent_phone': row['Parent Phone']!,
          'school_name': row['School Name']!,
        };
        var check = 0;
        check = await dbHelper.insertToTable('student_table', studentData);

        if (check == 0) {
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
      setMaxId();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    setState(() {
      rowTextEditingControllers.clear();
      focusNodes.clear();
      _addNewRow();
    });
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 300,
                    child: ToggleButtons(
                      color: Colors
                          .black, // Color of the text and icons (unselected)
                      selectedColor: Colors
                          .white, // Color of the text and icons (selected)
                      fillColor: Theme.of(context)
                          .primaryColor, // Background color (selected)
                      borderColor: Colors.grey, // Border color (unselected)
                      selectedBorderColor: Theme.of(context)
                          .primaryColor, // Border color (selected)
                      borderRadius: BorderRadius.circular(8.0), // Border radius
                      constraints: BoxConstraints(
                        minHeight: 40.0,
                        minWidth: 80.0,
                      ),
                      children: const <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('HS'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('HSS'),
                        ),
                      ],
                      isSelected: _selections,
                      onPressed: (int index) {
                        setState(() {
                          for (int i = 0; i < _selections.length; i++) {
                            _selections[i] = i == index;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _onSubmit,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(
              color: Theme.of(context).canvasColor, // Line color
              thickness: 2, // Line thickness
            ),
            const SizedBox(height: 20),
            Padding(
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
                      label: _buildHeaderCell(header),
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
                                  rowTextEditingControllers.removeAt(rowIndex);
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
                                  rowTextEditingControllers.removeAt(rowIndex);
                                  focusNodes.removeAt(rowIndex);
                                });
                              },
                            ),
                          );
                        } else if (header == 'ID') {
                          int rowId = maxId + rowIndex + 1;
                          rowTextEditingControllers[rowIndex][header]!.text =
                              rowId.toString();

                          return DataCell(
                            Container(
                              width: double.infinity,
                              child: Text(rowId.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                          );
                        } else if (header == 'Stream Name' &&
                            widget.metadata.tableName == 'student_table') {
                          return DataCell(
                            Container(
                                width: double.infinity,
                                child: autoFill(
                                  controller:
                                      rowTextEditingControllers[rowIndex]
                                          [header] as TextEditingController,
                                  optionsList: STREAM_NAMES,
                                  labelText: '',
                                  needBorder: false,
                                  nextFocusNode: focusNodes[rowIndex]
                                      [headers.indexOf(header) + 1],
                                )),
                          );
                        } else {
                          int cellIndex = headers.indexOf(header);
                          return _buildDataCell(
                            rowTextEditingControllers[rowIndex][header]!,
                            focusNodes[rowIndex][cellIndex],
                            cellIndex < focusNodes[rowIndex].length - 1
                                ? (cellIndex == 1
                                    ? focusNodes[rowIndex][3]
                                    : focusNodes[rowIndex][cellIndex + 1])
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

  Widget _buildHeaderCell(String title) {
    return Center(
      child: Container(
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

class StudentDataCell extends StatelessWidget {
  final String columnName;
  final String? studentName;
  final TextEditingController? scoreController;
  final FocusNode? focusNode;
  final int studentId;
  final String currentScore;
  final VoidCallback? onSubmitted;

  StudentDataCell({
    required this.columnName,
    this.studentName,
    this.scoreController,
    this.focusNode,
    required this.studentId,
    required this.currentScore,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    switch (columnName) {
      case 'Student Name':
        return SizedBox(
          width: 300,
          child: Text(
            studentName ?? '',
            style: const TextStyle(),
          ),
        );
      case 'ID':
        return SizedBox(
          width: 50,
          child: Text(
            studentId.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      case 'Score':
        return SizedBox(
          width: 100,
          child: TextField(
            controller: scoreController,
            focusNode: focusNode,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => onSubmitted?.call(),
          ),
        );
      default:
        return const Text('');
    }
  }
}
