import 'package:flutter/material.dart';

class DataEntryPage extends StatefulWidget {
  final List<String> headers; // Parameter

  // Constructor accepting the headers list
  DataEntryPage({Key? key, required this.headers}) : super(key: key);
  @override
  _DataEntryPageState createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  late List<String> headers; // Use late initialization

  List<Map<String, TextEditingController>> rows = [];
  List<List<FocusNode>> focusNodes = [];

  @override
  void initState() {
    super.initState();
    // Add ID column
    headers = widget.headers; // Initialize headers

    _addNewRow();
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

      rows.add(controllers);
      focusNodes.add(nodes);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (nodes.isNotEmpty) {
          FocusScope.of(context).requestFocus(nodes[0]);
        }
      });
    });
  }

  void _onSubmit() {
    for (var row in rows) {
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

    List<Map<String, String>> data = rows.map((row) {
      return row.map((key, controller) => MapEntry(key, controller.text));
    }).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      rows.clear();
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
                    rows.length,
                    (rowIndex) => DataRow(
                      color: MaterialStateProperty.resolveWith<Color>((states) {
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
                                  rows.removeAt(rowIndex);
                                  focusNodes.removeAt(rowIndex);
                                });
                              },
                            ),
                          );
                        } else {
                          int cellIndex = headers.indexOf(header);
                          return _buildDataCell(
                            rows[rowIndex][header]!,
                            focusNodes[rowIndex][cellIndex],
                            cellIndex < focusNodes[rowIndex].length - 1
                                ? focusNodes[rowIndex][cellIndex + 1]
                                : null,
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
  ) {
    return DataCell(
      Container(
        width: 150, // Fixed width for column
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
    return Container(
      color: Colors.blue.shade100, // Header background color
      padding: EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
