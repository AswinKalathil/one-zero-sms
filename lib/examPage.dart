import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/dataEntry.dart';
import 'package:one_zero/database_helper.dart';

class ExamScoreSheet extends StatefulWidget {
  final int classId;
  final bool isClassTablesInitialized;
  final List<Map<String, dynamic>> classes;
  final bool isMenuExpanded;
  ExamScoreSheet(
      {super.key,
      required this.classId,
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

  final ScrollController _scrollController = ScrollController();

  bool _changeExist = true;
  bool reset = false;
  List<Map<String, dynamic>> _studentList = [];
  int _testId = 0;
  List<String> _subjectForSuggestions = [];
  List<String>? _subjectsOfClass = [];

  int _selectedClassid = 0;
  List<Map<String, dynamic>> _testHistory = [];
  DateTime _selectedDate = DateTime.now();
  DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchSubjects(widget.classId);

    synchTestHistory();
  }

  void fetchSubjects(int classId) async {
    _subjectsOfClass = await _dbHelper.getClassSubjects(widget.classId);

    _selectedClassid = widget.classId;

    if (_subjectsOfClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class not found in the database'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      setState(() {
        _subjectForSuggestions = _subjectsOfClass ?? [];
      });
    }

    return;
  }

  @override
  Widget build(BuildContext context) {
    List<FocusNode> focusNodes = List.generate(5, (_) => FocusNode());

    return (widget.isClassTablesInitialized)
        ? SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Listener(
              onPointerSignal: (pointerSignal) {
                // Handle horizontal scrolling with mouse wheel
                if (pointerSignal is PointerScrollEvent) {
                  _scrollController.position.moveTo(
                    _scrollController.offset +
                        pointerSignal
                            .scrollDelta.dy, // Adjusts scrolling to horizontal
                  );
                }
              },
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: 1330,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
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
                                      width: 600,
                                      margin: const EdgeInsets.only(
                                          left: 10, top: 10),
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

                                          CustomButton(
                                              text: "ADD",
                                              onPressed: () {
                                                saveExam();
                                              },
                                              width: 100,
                                              height: 35,
                                              textColor: Colors.white),
                                          // ElevatedButton(
                                          //   focusNode: focusNodes[4],
                                          //   onPressed: () {
                                          //     saveExam();
                                          //   },
                                          //   child: const Text('  Save  '),
                                          // ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                        margin: const EdgeInsets.only(
                                            left: 10, bottom: 10),
                                        padding: const EdgeInsets.all(20),
                                        height: 250,
                                        width: 600,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.grey.withOpacity(.5),
                                            width: .5,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                // Container(
                                                //   padding: const EdgeInsets.symmetric(
                                                //       vertical: 5),
                                                //   height: 70,
                                                //   width: 200,
                                                //   child: AutoFill(
                                                //     key: ValueKey(
                                                //         widget.classes.hashCode),
                                                //     labelText: 'Class Name',
                                                //     controller: _classNameController,
                                                //     focusNode: focusNodes[0],
                                                //     nextFocusNode: focusNodes[1],
                                                //     optionsList: widget.classes
                                                //         .map((e) => e['class_name']
                                                //             .toString())
                                                //         .toList(),
                                                //     // onSubmitCallback: (value) async {
                                                //     //   if (value.isNotEmpty) {

                                                //     // },
                                                //   ),
                                                // ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 10),
                                                  width: 200,
                                                  child:
                                                      DropdownButtonFormField(
                                                    decoration: InputDecoration(
                                                      labelText: 'Subject Name',
                                                      filled: true,
                                                      fillColor:
                                                          Theme.of(context)
                                                              .canvasColor,
                                                      focusColor: Colors.grey,
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              15.0),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4.0),
                                                        borderSide: BorderSide(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    .2),
                                                            width: 0.4),
                                                      ),
                                                    ),
                                                    items:
                                                        _subjectForSuggestions
                                                            .map((subject) =>
                                                                DropdownMenuItem(
                                                                  value:
                                                                      subject,
                                                                  child: Text(
                                                                      subject),
                                                                ))
                                                            .toList(),
                                                    onChanged: (value) {
                                                      _subjectNameController
                                                              .text =
                                                          value as String;
                                                    },
                                                  ),
                                                ),
                                                // Container(
                                                //   padding: const EdgeInsets.symmetric(
                                                //       vertical: 5),
                                                //   height: 70,
                                                //   width: 200,
                                                //   child: AutoFill(
                                                //     key: ValueKey(
                                                //         _subjectForSuggestions
                                                //             .hashCode),
                                                //     labelText: 'Subject',
                                                //     controller:
                                                //         _subjectNameController,
                                                //     nextFocusNode: focusNodes[2],
                                                //     optionsList:
                                                //         _subjectForSuggestions,
                                                //   ),
                                                // ),

                                                Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 10),
                                                  width: 200,
                                                  child: TextField(
                                                      focusNode: focusNodes[2],
                                                      controller:
                                                          _topicController,
                                                      //new decoration
                                                      decoration:
                                                          InputDecoration(
                                                        label: const Text(
                                                            ' Chapter/Topic'),
                                                        filled: true,
                                                        fillColor:
                                                            Theme.of(context)
                                                                .canvasColor,
                                                        focusColor: Colors.grey,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .all(15.0),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4.0),
                                                          borderSide: BorderSide(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      .2),
                                                              width: 0.4),
                                                        ),
                                                      ),
                                                      onSubmitted: (value) {
                                                        setState(() {
                                                          _changeExist = true;
                                                        });
                                                        focusNodes[3]
                                                            .requestFocus();
                                                      }),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 10),
                                                  width: 200,
                                                  child: TextField(
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter
                                                          .digitsOnly
                                                    ],
                                                    focusNode: focusNodes[3],
                                                    controller:
                                                        _maxiMarkController,
                                                    decoration: InputDecoration(
                                                      label: const Text(
                                                          'Max Mark'),
                                                      filled: true,
                                                      fillColor:
                                                          Theme.of(context)
                                                              .canvasColor,
                                                      focusColor: Colors.grey,
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              15.0),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4.0),
                                                        borderSide: BorderSide(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    .2),
                                                            width: 0.4),
                                                      ),
                                                    ),
                                                    onSubmitted: (value) {
                                                      focusNodes[4]
                                                          .requestFocus();

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
                                                  onTap: () =>
                                                      _pickDate(context),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            22.0),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}  ", // Default to today's date
                                                          style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        const Icon(Icons
                                                            .calendar_today),
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
                                      margin: const EdgeInsets.only(
                                          left: 10, top: 10),
                                      padding: const EdgeInsets.all(20),
                                      width: 600,
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
                                  width: 600,
                                  height: 685,
                                  child: ExamEntry(
                                    test_id: _testId,
                                    key: ValueKey(_testId),
                                    parentsetstate: () {
                                      super.setState(() {
                                        synchTestHistory();
                                        _changeExist = true;
                                      });
                                    },
                                  ),
                                ),
                              )
                            : SizedBox(),
                      ],
                    ),
                  ),
                ),
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
    _testHistory = await _dbHelper.getTestHistory(widget.classId);

    setState(() {});
  }

  Widget showTestHistory() {
    return Container(
      width: 600,
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
                          _testHistory[index]['test_date'] != null
                              ? (() {
                                  final testDate =
                                      _testHistory[index]['test_date'];
                                  if (testDate is DateTime) {
                                    // If it's already a DateTime, format it directly
                                    return DateFormat('yyyy-MM-dd – kk:mm')
                                        .format(testDate);
                                  } else if (testDate is String) {
                                    // If it's a String, replace spaces and parse
                                    try {
                                      return DateFormat('yyyy-MM-dd – kk:mm')
                                          .format(
                                        DateTime.parse(
                                            testDate.replaceAll(' ', 'T')),
                                      );
                                    } catch (e) {
                                      // Handle parsing error
                                      return "--/--/--"; // Return a default value on error
                                    }
                                  } else {
                                    // Handle unexpected types
                                    return "--/--/--"; // Return a default value
                                  }
                                }())
                              : "--/--/--", // Handle null case
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
    // if (_classNameController.text.isEmpty ||
    if (_subjectNameController.text.isEmpty ||
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
      if (await _dbHelper.insertToTable('test_table', test) != -1) {
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
  Function parentsetstate;

  ExamEntry({Key? key, required this.test_id, required this.parentsetstate})
      : super(key: key);

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
  int maxScore = 100;
  bool _isLoading = true;

  @override
  void initState() {
    headers = ['ID', 'Student Name', 'Score'];
    columnLengths = [100, 300, 100];

    fetchStudents(widget.test_id);
    super.initState();

    if (rowTextEditingControllers.isEmpty) {
      // Delay for 2 seconds before showing the "No Students Found" message
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      _isLoading = false;
    }
    // _addNewRows();
  }

  void fetchStudents(int testId) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    // print("Test id $testId");
    // studentList = await dbHelper.getStudentIdsAndNamesByTestId(testId);

    _studentScoreList = await dbHelper.getTestDataSheetForUpdate(testId);
    testDetails = await dbHelper.getTestDetails(testId);
    // print(" Students length ${_studentScoreList.length}");

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

      maxScore = testDetails['max_mark'];
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
        : _isLoading
            ? const Center(
                child: SizedBox(
                    width: 50, height: 50, child: CircularProgressIndicator()))
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/missing-students.png', // Asset image path
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "No Students Found",
                      style: TextStyle(
                          fontFamily: 'revue',
                          color: Colors.grey,
                          fontSize: 20),
                    )
                  ],
                ),
              );
  }

  Widget buildDataTable() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: EdgeInsets.all(20),
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
          SizedBox(
            width: 550,
            child: Row(
              children: [
                Text(
                  "${testDetails['subject_name']} ",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${testDetails['topic']} ",
                  style: const TextStyle(
                      fontSize: 20, fontStyle: FontStyle.italic),
                ),
                Spacer(),
                PopupMenuButton(itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      child: Text("Edit"),
                      value: "edit",
                    ),
                    PopupMenuItem(
                      child: Text("Delete"),
                      value: "delete",
                    ),
                  ];
                }, onSelected: (value) {
                  if (value == "delete") {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Delete Test'),
                          content: const Text(
                              'Are you sure you want to delete this test?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await dbHelper.deleteFromTable(
                                    "test_table", widget.test_id);
                                widget.parentsetstate();

                                Navigator.of(context).pop();
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  } else if (value == "edit") {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Edit Test'),
                          content: const Text(
                              'Are you sure you want to edit this test?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                widget.parentsetstate();
                                Navigator.of(context).pop();
                                // Navigator.of(context).pop();
                              },
                              child: const Text('Edit'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                }),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                  width: 400,
                  child: Text(
                      "${testDetails['test_date'].toString().substring(0, 10)}")),
            ],
          ),
          const SizedBox(height: 20),
          Divider(
            color: Theme.of(context).canvasColor, // Line color
            thickness: 2, // Line thickness
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, right: 30.0),
              child: CustomButton(
                  text: "SAVE",
                  onPressed: () {
                    saveExamScores();
                  },
                  width: 85,
                  height: 35,
                  textColor: Colors.white),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
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
                          header == 'Score' ? "$header \n($maxScore)" : header,
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
                              maxMark: maxScore,
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

  void saveExamScores() async {
    bool abort = false;
    var data = rowTextEditingControllers.map((controller) {
      if (controller.text.isNotEmpty) {
        if (int.parse(controller.text) > maxScore ||
            int.parse(controller.text) < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Score should be within $maxScore'),
              backgroundColor: Colors.red,
            ),
          );
          abort = true;
          return "-";
        }
      }

      return controller.text.trim();
    }).toList();

    if (abort) return;
    DatabaseHelper dbHelper = DatabaseHelper();

    for (int i = 0; i < _studentScoreList.length; i++) {
      print("${_studentScoreList[i]['test_score_id']} :${data[i]} ");

      var changes = await dbHelper
          .updateTestScore(_studentScoreList[i]['test_score_id'], {
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

class StudentDataCell extends StatelessWidget {
  final String columnName;
  final String? studentName;
  final TextEditingController? scoreController;
  final FocusNode? focusNode;
  final int studentId;
  final String currentScore;
  final int maxMark;
  final VoidCallback? onSubmitted;

  StudentDataCell({
    required this.columnName,
    this.studentName,
    this.scoreController,
    this.focusNode,
    required this.studentId,
    required this.currentScore,
    required this.maxMark,
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
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onSubmitted: (value) {
              int? score = int.tryParse(value);

              if (score != null) {
                // If the score is not null, check if it's less than or equal to the max score
                if (score <= maxMark && score >= 0) {
                  // Valid score, proceed to save
                  onSubmitted?.call();
                } else {
                  // Invalid score (greater than max score)

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Score shoulbe within $maxMark"),
                        backgroundColor: Colors.black),
                  );
                }
              } else {
                onSubmitted?.call();
              }
            },
          ),
        );
      default:
        return const Text('');
    }
  }
}
