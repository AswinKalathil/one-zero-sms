import 'package:flutter/material.dart';
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
    _addNewRow();
  }

  void setMaxId() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    maxId = await dbHelper.getMaxId(widget.metadata.tableName);

    setState(() {
      print("MAX ID: $maxId");
      maxId = maxId;
    });
  }

  void _addNewRow() {
    setState(() {
      var controllers = <String, TextEditingController>{};
      var nodes = <FocusNode>[];

      for (var header in headers) {
        if (header != 'Actions') {
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
    for (var row in rowTextEditingControllers) {
      if (row.values.any((controller) => controller.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all the fields for each row.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    List<Map<String, String>> data = rowTextEditingControllers.map((row) {
      return row.map((key, controller) => MapEntry(key, controller.text));
    }).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    // if (data[0].containsKey('class_id')) {
    //   var subjectData = data.map((row) {
    //     return {
    //       'subject_id': row['subject_id']!,
    //       'subject_name': row['subject']!,
    //       'class_id': row['class_id']!,
    //     };
    //   }).toList();
    //   // Insert data to the database
    //   for (var row in data) {
    //     // Insert data to the database
    //     await dbHelper.insertToTable('class_table', row);
    //   }
    // }
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

  @override
  Widget build(BuildContext context) {
    DatabaseHelper dbHelper = DatabaseHelper();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Text(
                  'Enter New Class Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: _addNewRow,
                child: Text('Add Row'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: _onSubmit,
                child: Text('Submit'),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16.0, // Space between columns
                  border: TableBorder(
                    verticalInside: BorderSide(color: Colors.grey, width: 1),
                  ),
                  headingRowColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    return Colors.blue.shade100; // Header background color
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
                        return rowIndex % 2 == 0
                            ? Colors.grey.shade200
                            : Colors.white;
                      }),
                      cells: headers.map((header) {
                        if (header == 'Actions') {
                          return DataCell(
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color:
                                      const Color.fromARGB(255, 241, 167, 161)),
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
                              icon: Icon(Icons.save,
                                  color:
                                      const Color.fromARGB(255, 241, 167, 161)),
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
                              // Fixed width for column
                              color: Colors.blue
                                  .shade100, // Change to your preferred color
                              // Optional: Add padding for better visuals
                              child: Text(rowId.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
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
          )
        ],
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
          decoration: InputDecoration(
            border: InputBorder.none,
          ),
          maxLines: 1,
          onSubmitted: (value) {
            if (nextFocus == null) {
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
        color: Colors.blue.shade100, // Header background color
        padding: EdgeInsets.all(8.0),
        child: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ExamEntry extends StatefulWidget {
  final InputTableMetadata metadata;
  // Parameter

  // Constructor accepting the headers list
  ExamEntry({Key? key, required this.metadata}) : super(key: key);
  @override
  _ExamEntryState createState() => _ExamEntryState();
}

class _ExamEntryState extends State<ExamEntry> {
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
    _addNewRow();
  }

  void setMaxId() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    maxId = await dbHelper.getMaxId(widget.metadata.tableName);

    setState(() {
      print("MAX ID: $maxId");
      maxId = maxId;
    });
  }

  void _addNewRow() {
    setState(() {
      var controllers = <String, TextEditingController>{};
      var nodes = <FocusNode>[];

      for (var header in headers) {
        if (header != 'Actions') {
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
    for (var row in rowTextEditingControllers) {
      if (row.values.any((controller) => controller.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all the fields for each row.'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }
    }

    List<Map<String, String>> data = rowTextEditingControllers.map((row) {
      return row.map((key, controller) => MapEntry(key, controller.text));
    }).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    // if (data[0].containsKey('class_id')) {
    //   var subjectData = data.map((row) {
    //     return {
    //       'subject_id': row['subject_id']!,
    //       'subject_name': row['subject']!,
    //       'class_id': row['class_id']!,
    //     };
    //   }).toList();
    //   // Insert data to the database
    //   for (var row in data) {
    //     // Insert data to the database
    //     await dbHelper.insertToTable('class_table', row);
    //   }
    // }
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

  @override
  Widget build(BuildContext context) {
    DatabaseHelper dbHelper = DatabaseHelper();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Text(
                  'Enter New Class Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: _addNewRow,
                child: Text('Add Row'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: _onSubmit,
                child: Text('Submit'),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16.0, // Space between columns
                  border: TableBorder(
                    verticalInside: BorderSide(color: Colors.grey, width: 1),
                  ),
                  headingRowColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    return Colors.blue.shade100; // Header background color
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
                        return rowIndex % 2 == 0
                            ? Colors.grey.shade200
                            : Colors.white;
                      }),
                      cells: headers.map((header) {
                        if (header == 'Actions') {
                          return DataCell(
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color:
                                      const Color.fromARGB(255, 241, 167, 161)),
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
                              icon: Icon(Icons.save,
                                  color:
                                      const Color.fromARGB(255, 241, 167, 161)),
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
                              // Fixed width for column
                              // Change to your preferred color
                              // Optional: Add padding for better visuals
                              child: Text(rowId.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
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
          )
        ],
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
          decoration: InputDecoration(
            border: InputBorder.none,
          ),
          maxLines: 1,
          onSubmitted: (value) {
            if (nextFocus == null) {
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
        color: Colors.blue.shade100, // Header background color
        padding: EdgeInsets.all(8.0),
        child: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
