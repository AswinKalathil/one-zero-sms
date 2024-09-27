import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/dataEntry.dart';
import 'package:one_zero/database_helper.dart';

class ExamScoreSheet extends StatefulWidget {
  final bool isClassTablesInitialized;
  final List<Map<String, dynamic>> classes;
  final bool isMenuExpanded;
  ExamScoreSheet(
      {super.key,
      required this.isClassTablesInitialized,
      required this.classes,
      required this.isMenuExpanded});

  @override
  State<ExamScoreSheet> createState() => _ExamScoreSheetState();
}

class _ExamScoreSheetState extends State<ExamScoreSheet> {
  TextEditingController _classNameController = TextEditingController();
  TextEditingController _subjectNameController = TextEditingController();
  TextEditingController _topicController = TextEditingController();
  TextEditingController _maxiMarkController = TextEditingController();

  bool _changeExist = true;
  bool reset = false;
  List<Map<String, dynamic>> _studentList = [];
  int _testId = 0;
  List<String> _subjectForSuggestions = [];
  int _selectedClassid = 0;
  List<Map<String, dynamic>> _testHistory = [];
  DateTime _selectedDate = DateTime.now();
  DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    synchTestHistory();
  }

  @override
  Widget build(BuildContext context) {
    List<FocusNode> focusNodes = List.generate(5, (_) => FocusNode());

    List<String>? subjectsOfClass = [];
    return (widget.isClassTablesInitialized)
        ? SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: widget.isMenuExpanded
                      ? 50
                      : MediaQuery.of(context).size.width * .075,
                  vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.all(5),
                    child: SizedBox(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.38,
                                margin:
                                    const EdgeInsets.only(left: 10, top: 10),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(.5),
                                    width: .5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Add New Exam',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Spacer(),
                                    ElevatedButton(
                                      focusNode: focusNodes[4],
                                      onPressed: () {
                                        saveExam();
                                      },
                                      child: const Text('  Save  '),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  margin: const EdgeInsets.only(
                                      left: 10, bottom: 10),
                                  padding: const EdgeInsets.all(20),
                                  height: 310,
                                  width:
                                      MediaQuery.of(context).size.width * 0.38,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(.5),
                                      width: .5,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            height: 70,
                                            width: 200,
                                            child: autoFill(
                                              key: ValueKey(
                                                  widget.classes.hashCode),
                                              labelText: 'Class Name',
                                              controller: _classNameController,
                                              focusNode: focusNodes[0],
                                              nextFocusNode: focusNodes[1],
                                              optionsList: widget.classes
                                                  .map((e) => e['class_name']
                                                      .toString())
                                                  .toList(),
                                              onSubmitCallback: (value) async {
                                                if (value.isNotEmpty) {
                                                  subjectsOfClass =
                                                      await _dbHelper
                                                          .getClassSubjects(
                                                              value);

                                                  _selectedClassid = widget
                                                      .classes
                                                      .firstWhere((element) =>
                                                          element[
                                                              'class_name'] ==
                                                          value)['id'];

                                                  if (subjectsOfClass == null) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Class not found in the database'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  } else {
                                                    setState(() {
                                                      _subjectForSuggestions =
                                                          subjectsOfClass ?? [];
                                                    });
                                                  }

                                                  return;
                                                }
                                              },
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            height: 70,
                                            width: 200,
                                            child: autoFill(
                                              key: ValueKey(
                                                  _subjectForSuggestions
                                                      .hashCode),
                                              labelText: 'Subject',
                                              controller:
                                                  _subjectNameController,
                                              nextFocusNode: focusNodes[2],
                                              optionsList:
                                                  _subjectForSuggestions,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            width: 200,
                                            child: TextField(
                                                focusNode: focusNodes[2],
                                                controller: _topicController,
                                                //new decoration
                                                decoration: InputDecoration(
                                                  label: const Text(
                                                      ' Chapter/Topic'),
                                                  filled: true,
                                                  fillColor: Theme.of(context)
                                                      .canvasColor,
                                                  focusColor: Colors.grey,
                                                  contentPadding:
                                                      const EdgeInsets.all(
                                                          15.0),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4.0),
                                                    borderSide: BorderSide(
                                                        color: Colors.grey
                                                            .withOpacity(.2),
                                                        width: 0.4),
                                                  ),
                                                ),
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    _changeExist = true;
                                                  });
                                                  focusNodes[3].requestFocus();
                                                }),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            width: 200,
                                            child: TextField(
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              focusNode: focusNodes[3],
                                              controller: _maxiMarkController,
                                              decoration: InputDecoration(
                                                label: const Text('Max Mark'),
                                                filled: true,
                                                fillColor: Theme.of(context)
                                                    .canvasColor,
                                                focusColor: Colors.grey,
                                                contentPadding:
                                                    const EdgeInsets.all(15.0),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4.0),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey
                                                          .withOpacity(.2),
                                                      width: 0.4),
                                                ),
                                              ),
                                              onSubmitted: (value) {
                                                focusNodes[4].requestFocus();

                                                setState(() {
                                                  _changeExist = true;
                                                });
                                              },
                                            ),
                                          ),
                                          const Row(
                                            children: [],
                                          ),
                                        ],
                                      ),

                                      //second column --------
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _pickDate(context),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(22.0),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}  ", // Default to today's date
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const Icon(
                                                      Icons.calendar_today),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 10, top: 10),
                                padding: const EdgeInsets.all(20),
                                width: MediaQuery.of(context).size.width * 0.38,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(.5),
                                    width: .5,
                                  ),
                                ),
                                child: Text(
                                  'Recent Tests ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              showTestHistory(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  !_changeExist
                      ? Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: _studentList.length * 50.0 + 300,
                            child: ExamEntry(
                                test_id: _testId, key: ValueKey(_testId)),
                          ),
                        )
                      : SizedBox(),
                ],
              ),
            ),
          )
        : Container(
            child: Center(
              child: Text("No Class Data Found"),
            ),
          );
  }

  _pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate, // Use the selected date or today's date by default
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void synchTestHistory() async {
    _testHistory = await _dbHelper.getTestHistory();

    setState(() {});
  }

  Widget showTestHistory() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.38,
      height: 240,
      margin: const EdgeInsets.only(left: 10, bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey.withOpacity(.5),
          width: .5,
        ),
      ),
      child: ListView.builder(
        itemCount: _testHistory.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              _testId = _testHistory[index]['test_id'];

              _studentList =
                  await _dbHelper.getStudentIdsAndNamesByTestId(_testId);

              setState(() {
                _testId;
                _studentList;
                _changeExist = false;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Colors.grey.withOpacity(1), width: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _testHistory[index]['subject_name'] ?? "--",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _testHistory[index]['topic'] ?? "_",
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          )),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          DateFormat('yyyy-MM-dd – kk:mm').format(
                                  DateTime.parse(_testHistory[index]
                                          ['test_date']
                                      .replaceAll(' ', 'T'))) ??
                              "--/--/--",
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          _testHistory[index]['class_name'] ?? "--",
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Spacer(),
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Test ID: ${_testHistory[index]['test_id']}" ?? "_",
                            style: TextStyle(
                              fontSize: 8,
                            ),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  saveExam() async {
    if (_classNameController.text.isEmpty ||
        _subjectNameController.text.isEmpty ||
        _topicController.text.isEmpty ||
        _maxiMarkController.text.isEmpty) {
      // Show an error message if any field is empty

      // print(
      //     "classname: ${_classNameController.text} \nsubject: ${_subjectNameController.text}\n topic: ${_topicController.text}\n maxmark: ${_maxiMarkController.text}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all the fields.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // All fields are filled, proceed with your logic

      int maxtestId = await _dbHelper.getMaxId('test_table');

      Map<String, dynamic> newTest = {
        'testId': maxtestId + 1,
        'date': _selectedDate.toString(),
        'className': _classNameController.text,
        'maxMark': _maxiMarkController.text,
        'topic': _topicController.text,
        'subject_name': _subjectNameController.text,
      };
      // print(
      //     "class id at subject fetch: $_selectedClassid");
      int subjectId = await _dbHelper.getSubjectId(
          _subjectNameController.text, _selectedClassid);

      if (subjectId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject not found in the database'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      Map<String, dynamic> test = {
        'id': newTest['testId'],
        'subject_id': subjectId,
        'topic': newTest['topic'],
        'max_mark': int.parse(newTest['maxMark']),
        'test_date': newTest['date'],
      };
      print(test);
      if (await _dbHelper.insertToTable('test_table', test) != 0) {
        synchTestHistory();
        _studentList =
            await _dbHelper.getStudentIdsAndNamesByTestId(test['id']);
        for (int i = 0; i < _studentList.length; i++) {
          _dbHelper.insertToTable('test_score_table', {
            'student_id': _studentList[i]['student_id'],
            'test_id': test['id'],
          });
        }
        // Show a success message

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test details saved successfully'),

            // Use the default theme color
          ),
        );
        _testId = maxtestId + 1;

        _studentList = await _dbHelper.getStudentIdsAndNamesByTestId(_testId);

        setState(() {
          _changeExist = false;
        });
      }

      // Proceed with further processing, like saving data to a database or sending it to a server
      // Example: saveDataToDatabase(studentName, stream, studentPhone, schoolName, parentName, parentPhone, photoPath);
    }
  }
}

class ExamEntry extends StatefulWidget {
  final int test_id;

  ExamEntry({
    Key? key,
    required this.test_id,
  }) : super(key: key);

  @override
  _ExamEntryState createState() => _ExamEntryState();
}

class _ExamEntryState extends State<ExamEntry> {
  late List<String> headers;
  late List<double> columnLengths;
  List<TextEditingController> rowTextEditingControllers = [];
  List<FocusNode> focusNodes = [];
  List<Map<String, dynamic>> _studentScoreList = [];
  Map<String, dynamic> testDetails = {};
  int maxId = 0;
  DatabaseHelper dbHelper = DatabaseHelper();
  @override
  void initState() {
    headers = ['ID', 'Student Name', 'Score'];
    columnLengths = [100, 300, 100];

    fetchStudents(widget.test_id);
    super.initState();
    // _addNewRows();
  }

  void fetchStudents(int testId) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    print("Test id $testId");
    // studentList = await dbHelper.getStudentIdsAndNamesByTestId(testId);

    _studentScoreList = await dbHelper.getTestDataSheetForUpdate(testId);
    testDetails = await dbHelper.getTestDetails(testId);
    print(" Students length ${_studentScoreList.length}");

    setState(() {
      rowTextEditingControllers =
          List.generate(_studentScoreList.length, (index) {
        return TextEditingController();
      });
      focusNodes.addAll(List.generate(_studentScoreList.length, (index) {
        return FocusNode();
      }));

      for (int i = 0; i < _studentScoreList.length; i++) {
        rowTextEditingControllers[i].text =
            _studentScoreList[i]['score']?.toString() ?? "";
      }
    });
  }

  void _moveFocusToNextRow(int currentRowIndex) {
    if (currentRowIndex + 1 < focusNodes.length) {
      FocusScope.of(context).requestFocus(focusNodes[currentRowIndex + 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return rowTextEditingControllers.isNotEmpty
        ? buildDataTable() // Function that contains your DataTable widget
        : const Center(child: CircularProgressIndicator());
  }

  Widget buildDataTable() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: Colors.grey.withOpacity(0.5),
          width: .5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0),
            child: SizedBox(
              width: 300,
              child: Text(
                "${testDetails['subject_name']}  Test",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                    width: 400,
                    child: Text(
                        "${testDetails['test_date'].toString().substring(0, 10)}")),
                ElevatedButton(
                  onPressed: () async {
                    var data = rowTextEditingControllers.map((controller) {
                      print("Data ${controller.text}");
                      return controller.text.trim();
                    }).toList();
                    DatabaseHelper dbHelper = DatabaseHelper();

                    for (int i = 0; i < _studentScoreList.length; i++) {
                      print(
                          "${_studentScoreList[i]['test_score_id']} :${data[i]} ");

                      var changes = await dbHelper.updateTestScore(
                          _studentScoreList[i]['test_score_id'], {
                        'score': data[i].toString(),
                      });
                      print("Changes $changes");
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data submitted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columnSpacing: 16.0,
                  border: const TableBorder(
                    verticalInside: BorderSide(color: Colors.grey, width: 1),
                  ),
                  headingRowColor:
                      WidgetStateProperty.resolveWith<Color>((states) {
                    return Theme.of(context).primaryColor;
                  }),
                  columns: headers.map((header) {
                    return DataColumn(
                      label: Center(
                        child: Text(
                          header,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                  rows: List<DataRow>.generate(
                    _studentScoreList.length,
                    (rowIndex) {
                      var student = _studentScoreList[rowIndex];
                      var controller = rowTextEditingControllers[rowIndex];
                      return DataRow(
                        color:
                            MaterialStateProperty.resolveWith<Color>((states) {
                          return (Theme.of(context).brightness ==
                                  Brightness.light)
                              ? (rowIndex % 2 == 0
                                  ? Colors.grey.shade200
                                  : Colors.white)
                              : (rowIndex % 2 == 0
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade700);
                        }),
                        cells: headers.map((header) {
                          var isScoreColumn = header == 'Score';

                          return DataCell(
                            StudentDataCell(
                              columnName: header,
                              studentName: header == 'Student Name'
                                  ? student['student_name'] as String
                                  : null,
                              scoreController:
                                  isScoreColumn ? controller : null,
                              focusNode:
                                  isScoreColumn ? focusNodes[rowIndex] : null,
                              studentId: header == 'ID'
                                  ? student['student_id'] as int
                                  : 0,
                              currentScore: student['score']?.toString() ?? "",
                              onSubmitted: isScoreColumn
                                  ? () => _moveFocusToNextRow(rowIndex)
                                  : null,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> showNewAcadamicYearDialog(BuildContext context) async {
    TextEditingController _textFieldController = TextEditingController();
    _textFieldController.text =
        "${DateTime.now().year}-${DateTime.now().year + 1}";
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Start New Acadamic Year'),
          content: TextField(
            controller: _textFieldController,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Dismiss without input
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(_textFieldController.text); // Return input
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
