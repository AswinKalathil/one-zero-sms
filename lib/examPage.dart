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
  ExamScoreSheet(
      {super.key,
      required this.isClassTablesInitialized,
      required this.classes});

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 100.0, vertical: 20),
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
                                margin:
                                    const EdgeInsets.only(left: 10, top: 10),
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
                                  width: 600,
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
                            width: 630,
                            height: _studentList.length * 50.0 + 300,
                            child: ExamEntry(
                                test_id: _testId, key: ValueKey(_testId)),
                          ),
                        )
                      : SizedBox(height: 400, child: getLogo(40)),
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
      width: 600,
      height: 310,
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
        // Show a success message
        synchTestHistory();
        // _studentList = await _dbHelper.getStudentIdsAndNamesByTestId(_testId);
        // for (int i = 0; i < _studentList.length; i++) {
        //   _dbHelper.insertToTable('test_score_table', {
        //     'student_id': _studentList[i]['student_id'],
        //     'score': '-',
        //     'test_id': test['id'],
        //   });
        // }
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
