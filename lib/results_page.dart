import 'dart:ffi';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:one_zero/appProviders.dart';
import 'package:one_zero/constants.dart';
import 'package:one_zero/custom-widgets.dart';
import 'package:one_zero/database_helper.dart';

import 'package:flutter/gestures.dart';
// import 'package:one_zero/gradeCard.dart';
import 'package:one_zero/gradecard.dart';
import 'package:one_zero/pdfGeneration.dart';
import 'package:one_zero/pieChart.dart';
import 'package:one_zero/testAnalytics.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:printing/printing.dart';

class ClassDetailPage extends StatefulWidget {
  final String className;
  final String classId;
  final bool isDedicatedPage;

  const ClassDetailPage(
      {required this.className,
      required this.classId,
      required this.isDedicatedPage,
      Key? key});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  String? _selectedcriteria = 'Student';
  List<String> _criteriaOptions = [];
  // Default criteria

  String _studentId = '';

  String searchText = '';
  String searchTextfinal = '';
  FocusNode serchButtonFocusNode = FocusNode();
  List<Map<String, dynamic>> _studentsOfNameList = [];
  List<Map<String, dynamic>> _studentsOfClassList = [];
  List<Map<String, dynamic>> _studentsOfSubjectList = [];
  String _resultTitle = '';

  final ScrollController _scrollController = ScrollController();
  int resultBoardIndex = 0;

  List<String> _classSubjects = [];

  List<Map<String, dynamic>> _allSubjects = [];
  Map<String, int> _subjectTestCount = {};

  List<List<Map<String, dynamic>>> _testResults = [];
  bool _showActions = false;
  bool _printSelected = false;
  bool _markAttendance = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _selectedcriteria = 'Student';
    _criteriaOptions = ['Student', 'Class'];
    _studentId = '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myProvider = Provider.of<ClassPageValues>(context, listen: false);
      myProvider.setShowGradeCard(false);
      myProvider.setClassId(widget.classId);
      setAllSubjects();
      setTestCount();
      if (widget.isDedicatedPage) {
        resultBoardIndex = 4;
        onSubmittedSerch(context, 'class');
      }
    });
  }

  void setAllSubjects() async {
    _classSubjects = (await _dbHelper.getClassSubjects(widget.classId))!;
    setState(() {
      _classSubjects = _classSubjects;
    });
  }

  void _onSelected(String criteria) {
    if (mounted) {
      setState(() {
        _selectedcriteria = criteria;
        switch (criteria) {
          case 'Student':
            resultBoardIndex = 0;
            Provider.of<ClassPageValues>(context, listen: false)
                .setShowGradeCard(false);

            break;
          case 'Class':
            resultBoardIndex = 1;
            Provider.of<ClassPageValues>(context, listen: false)
                .setShowGradeCard(false);

            break;
          case 'Subject':
            resultBoardIndex = 2;
            Provider.of<ClassPageValues>(context, listen: false)
                .setShowGradeCard(false);

            break;
        }
      });
    }
  }

  DatabaseHelper _dbHelper = DatabaseHelper();
  void onSubmittedSerch(BuildContext context, String value) async {
    final classPageValues = context.read<ClassPageValues>();

    value = value.trim();
    List<Map<String, dynamic>> fetchedStudentsList = [];

    if (!widget.isDedicatedPage && value.isNotEmpty) {
      if (_selectedcriteria == 'Student') {
        // fetchedStudentsList = await _dbHelper.getStudentsOfName(value, 0);
        _resultTitle = "search results with  '$value' ";
      } else if (_selectedcriteria == 'Class') {
        fetchedStudentsList = await _dbHelper.getStudentsOfClass(value);
        _resultTitle = 'students of class $value';
      } else if (_selectedcriteria == 'Subject') {
        fetchedStudentsList = await _dbHelper.getStudentsOfSubject(value);
        _resultTitle = "students of '$value'";
      }

      if (mounted) {
        setState(() {
          searchText = value;
          _studentsOfNameList =
              _selectedcriteria == 'Student' ? fetchedStudentsList : [];
          _studentsOfClassList =
              _selectedcriteria == 'Class' ? fetchedStudentsList : [];
          _studentsOfSubjectList =
              _selectedcriteria == 'Subject' ? fetchedStudentsList : [];
          resultBoardIndex = _selectedcriteria == 'Student'
              ? 3
              : _selectedcriteria == 'Class'
                  ? 4
                  : 5;
        });
      }
    }

    if (widget.isDedicatedPage && value == 'class') {
      fetchedStudentsList = await _dbHelper.getStudentsOfClass(widget.classId);

      resultBoardIndex = 4;
      searchText = widget.className;
      _resultTitle = "students of class '${widget.className}'";
    } else if (_selectedcriteria == 'Student' && value.isNotEmpty) {
      fetchedStudentsList =
          await _dbHelper.getStudentsOfNameAndClass(value, widget.classId);

      _resultTitle = "search results with  '$value' ";

      resultBoardIndex = 3;
      searchText = value;
    }
    classPageValues.setStudentsListToShow(fetchedStudentsList);
    if (mounted) setState(() {});
  }

  double _screenWidth = 0;
  double _screenHeight = 0;

  List<Map<String, dynamic>> _totalTest = [];

  void setTestCount() async {
    _totalTest = await _dbHelper.getTestHistory(widget.classId);

    int testCount = 0;

    for (var index = 0; index < _classSubjects.length; index++) {
      testCount = 0;
      for (var test in _totalTest) {
        if (test['subject_name'] == _classSubjects[index]) {
          testCount++;
        }
      }
      _subjectTestCount[_classSubjects[index]] = testCount;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> _pickDirectory() async {
    // Use FilePicker to pick a directory (one-time directory selection)
    final result = await FilePicker.platform.getDirectoryPath();
    return result; // Returns null if the user cancels
  }

  bool _isSaving = false;
  int _savedCount = 0;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child:
          Consumer<ClassPageValues>(builder: (context, classPageValues, child) {
        return Container(
          padding: const EdgeInsets.all(10),
          height: _screenWidth > 1200
              ? _screenHeight * 2 +
                  (((_allSubjects.length + 1) / 2).ceil() * 520)
              : _screenHeight * 2 + ((_allSubjects.length + 1) * 600),
          child: Column(
            children: [
              Listener(
                onPointerSignal: (pointerSignal) {
                  // Handle horizontal scrolling with mouse wheel
                  if (pointerSignal is PointerScrollEvent) {
                    _scrollController.position.moveTo(
                      _scrollController.offset +
                          pointerSignal.scrollDelta
                              .dy, // Adjusts scrolling to horizontal
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
                    child: GestureDetector(
                      onTap: () {
                        print('Container tapped');
                        setState(() {
                          _showActions = false;
                          _printSelected = false;
                          _markAttendance = false;
                          _studentId = '';
                          _allSubjects = [];

                          classPageValues.setShowGradeCard(false);
                        });
                      },
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        // margin: const EdgeInsets.only(right: 50),
                        height: 700,
                        width: 1300,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 80,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Text(
                                      "Subjects",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    width: 500,
                                    height: 350,
                                    child: GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 10,
                                              mainAxisSpacing: 10,
                                              childAspectRatio: 1.5),
                                      itemCount: _classSubjects.length,
                                      itemBuilder: (context, index) {
                                        Color indexColor = SUBJECT_OBJECT[
                                                    _classSubjects[index]]
                                                ?.color ??
                                            DEFAULT_SUBJECT.color;
                                        String imagePath = SUBJECT_OBJECT[
                                                    _classSubjects[index]]
                                                ?.image ??
                                            DEFAULT_SUBJECT.image;

                                        int testCount = _subjectTestCount[
                                                _classSubjects[index]] ??
                                            0;

                                        bool showSubjectcard = true;
                                        if (_allSubjects.isNotEmpty) {
                                          showSubjectcard = _allSubjects.any(
                                              (element) =>
                                                  element['subject_name'] ==
                                                  _classSubjects[index]);
                                        }

                                        return Opacity(
                                          opacity: showSubjectcard ? 1 : .3,
                                          child: Container(
                                            margin: EdgeInsets.all(
                                                showSubjectcard ? 0 : 5),
                                            padding: const EdgeInsets.only(
                                                top: 8, left: 8, right: 4),
                                            decoration: BoxDecoration(
                                              color: indexColor,

                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(8)),
                                              // image: DecorationImage(
                                              //   alignment: Alignment.bottomRight,
                                              //   opacity: .3,
                                              //   image: AssetImage(imagePath),
                                              //   fit: BoxFit.none,
                                              // ),
                                            ),
                                            child: Stack(children: [
                                              Positioned(
                                                bottom: 5,
                                                right: 2,
                                                child: SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child: Opacity(
                                                    opacity: .35,
                                                    child: Image.asset(
                                                      imagePath,
                                                      fit: BoxFit
                                                          .contain, // Keeps aspect ratio within the specified size
                                                      alignment:
                                                          Alignment.bottomRight,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    FittedBox(
                                                      child: Text(
                                                        _classSubjects[index],
                                                        style: TextStyle(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    .9),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20),
                                                      ),
                                                    ),
                                                    Text('${testCount} Exams',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    .9),
                                                            fontSize: 12)),
                                                  ]),
                                            ]),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 60,
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 480,
                                  child: searchText.isNotEmpty
                                      ? Container(
                                          // decoration: BoxDecoration(
                                          //   borderRadius: BorderRadius.circular(10),
                                          //   border: Border.all(
                                          //     color: Colors.grey.withOpacity(.5),
                                          //     width: .5,
                                          //   ),
                                          // ),
                                          margin: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 325,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 18,
                                                              left: 30,
                                                              right: 10),
                                                      child: TextField(
                                                        cursorColor:
                                                            Colors.grey,
                                                        decoration:
                                                            InputDecoration(
                                                          hintText:
                                                              'Search by $_selectedcriteria',
                                                          prefixIcon:
                                                              const Icon(
                                                                  Icons.search),
                                                          filled: true,
                                                          fillColor:
                                                              Theme.of(context)
                                                                  .canvasColor,
                                                          focusColor:
                                                              Theme.of(context)
                                                                  .canvasColor,
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .all(15.0),
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                        .4),
                                                                width: 0.4),
                                                          ),
                                                        ),
                                                        onChanged: (value) {
                                                          classPageValues
                                                              .setShowGradeCard(
                                                                  false);

                                                          if (mounted) {
                                                            setState(() {
                                                              searchTextfinal =
                                                                  value.trim();
                                                            });
                                                          }
                                                        },
                                                        onSubmitted: (value) {
                                                          if (mounted) {
                                                            setState(() {
                                                              searchTextfinal =
                                                                  value.trim();
                                                            });
                                                          }
                                                          onSubmittedSerch(
                                                              context,
                                                              searchTextfinal);
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 18),
                                                    child: CustomButton(
                                                        text: "Search",
                                                        onPressed: () {
                                                          onSubmittedSerch(
                                                              context,
                                                              searchTextfinal);
                                                        },
                                                        width: 100,
                                                        height: 48,
                                                        textColor:
                                                            Colors.white),
                                                  ),
                                                ],
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: FittedBox(
                                                  child: Text(
                                                    _resultTitle,
                                                    style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                // child: switch (resultBoardIndex) {
                                                //   3 => Text(
                                                //       "search results with  '$searchText'",
                                                //       style: const TextStyle(
                                                //         fontSize: 20,
                                                //       )),
                                                //   4 => Text(
                                                //       "students of class $searchText",
                                                //       style: const TextStyle(
                                                //         fontSize: 20,
                                                //       )),
                                                //   5 => Text("students of $searchText",
                                                //       style: const TextStyle(
                                                //         fontSize: 20,
                                                //       )),
                                                //   _ => const Text(""),
                                                // },
                                              ),
                                              classPageValues
                                                          .studentsListToShow ==
                                                      []
                                                  ? const CircleAvatar() //need updation
                                                  : studentsListView(
                                                      classPageValues
                                                          .studentsListToShow),
                                            ],
                                          ),
                                        )
                                      : const SizedBox(),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 80,
                                    ),
                                    ToggleButtons(
                                      isSelected: [
                                        _printSelected, // State for the 'Print' button
                                        _markAttendance, // State for the 'Attendance' button
                                      ],
                                      onPressed: (int index) {
                                        setState(() {
                                          if (index == 0) {
                                            _printSelected = !_printSelected;
                                            _markAttendance = false;
                                          } else if (index == 1) {
                                            _markAttendance = !_markAttendance;
                                            _printSelected = false;
                                          }
                                          _showActions =
                                              _printSelected || _markAttendance;
                                        });
                                      },
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 27.0),
                                          child: Text(
                                            "Print",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 27.0),
                                          child: Text(
                                            "Attendance",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Row(
                                    //   children: [
                                    //     TextButton(
                                    //       onPressed: () {
                                    //         if (mounted) {
                                    //           setState(() {
                                    //             _printSelected = !_printSelected;
                                    //             _markAttendance = false;

                                    //             _showActions = _printSelected ||
                                    //                 _markAttendance;
                                    //           });
                                    //         }
                                    //       },
                                    //       child: const Text(
                                    //         "Print",
                                    //         style: TextStyle(
                                    //             fontSize: 16,
                                    //             fontWeight: FontWeight.bold),
                                    //       ),
                                    //     ),
                                    //     SizedBox(
                                    //       width: 70,
                                    //     ),
                                    //     TextButton(
                                    //       onPressed: () {
                                    //         if (mounted) {
                                    //           setState(() {
                                    //             _markAttendance =
                                    //                 !_markAttendance;
                                    //             _printSelected = false;

                                    //             _showActions = _printSelected ||
                                    //                 _markAttendance;
                                    //           });
                                    //         }
                                    //       },
                                    //       child: const Text(
                                    //         "Attendance",
                                    //         style: TextStyle(
                                    //             fontSize: 16,
                                    //             fontWeight: FontWeight.bold),
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                    _showActions && _printSelected
                                        ? GestureDetector(
                                            onTap: () {
                                              // print("Print Reports tapped!");
                                              // Add logic for printing reports
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.all(5),
                                              height: 280,
                                              width: 240,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .cardColor
                                                    .withOpacity(.9),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                border: Border.all(
                                                  color: Colors.grey
                                                      .withOpacity(.5),
                                                  width: .5,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  const Padding(
                                                      padding:
                                                          EdgeInsets.all(8),
                                                      child: Text(
                                                          "Print Reports",
                                                          style: TextStyle(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold))),
                                                  Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 5.0,
                                                                horizontal:
                                                                    16.0),
                                                        child: Checkbox(
                                                          value: classPageValues
                                                              .studentsListToShow
                                                              .every((student) =>
                                                                  selectedIds
                                                                      .contains(
                                                                          student[
                                                                              'id'])),
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              if (value ==
                                                                  true) {
                                                                // Select all IDs
                                                                classPageValues
                                                                    .studentsListToShow
                                                                    .forEach(
                                                                        (element) {
                                                                  if (!selectedIds
                                                                      .contains(
                                                                          element[
                                                                              'id'])) {
                                                                    selectedIds.add(
                                                                        element[
                                                                            'id']);
                                                                  }
                                                                });
                                                              } else {
                                                                // Clear all selected IDs
                                                                selectedIds
                                                                    .clear();
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      const Text(
                                                        "Select All",
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 5.0,
                                                                horizontal:
                                                                    16.0),
                                                        child: Checkbox(
                                                            value: false,
                                                            onChanged:
                                                                (value) {}),
                                                      ),
                                                      const Text("Single File",
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ],
                                                  ),
                                                  MouseRegion(
                                                    cursor: SystemMouseCursors
                                                        .click,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        print(
                                                            "Print Reports tapped!:\n printing ${selectedIds.length} reports");
                                                        // Add logic for printing reports
                                                        triggerPdfGeneration(
                                                            true);
                                                      },
                                                      child: Container(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            vertical: 4.0,
                                                            horizontal: 16.0),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .blueAccent
                                                              .shade100,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        child: const Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(Icons.print,
                                                                size: 20.0,
                                                                color: Colors
                                                                    .white),
                                                            SizedBox(
                                                              width: 10,
                                                            ),
                                                            Text(
                                                              "Print",
                                                              style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  MouseRegion(
                                                    cursor: SystemMouseCursors
                                                        .click,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        classPageValues
                                                            .setShowGradeCard(
                                                                false);

                                                        print(
                                                            "save Reports tapped!:\n printing ${selectedIds.length} reports");

                                                        triggerPdfGeneration(
                                                            false);
                                                        // Add logic for printing reports
                                                        classPageValues
                                                            .setShowGradeCard(
                                                                true);
                                                      },
                                                      child: Container(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            vertical: 4.0,
                                                            horizontal: 16.0),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .blueAccent
                                                              .shade100,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        child: const Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                                Icons
                                                                    .save_alt_rounded,
                                                                size: 20.0,
                                                                color: Colors
                                                                    .white),
                                                            SizedBox(
                                                              width: 10,
                                                            ),
                                                            Text(
                                                              "Save",
                                                              style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 2,
                                                  ),
                                                  if (_isSaving)
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 1),
                                                      child:
                                                          LinearProgressIndicator(
                                                        value: _progress,
                                                        minHeight: 6,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : const SizedBox(
                                            width: 250,
                                          ),
                                    _showActions && _markAttendance
                                        ? GestureDetector(
                                            onTap: () {},
                                            child: Container(
                                              margin: const EdgeInsets.all(5),
                                              height: 200,
                                              width: 240,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .cardColor
                                                    .withOpacity(.9),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                border: Border.all(
                                                  color: Colors.grey
                                                      .withOpacity(.5),
                                                  width: .5,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  const Padding(
                                                      padding:
                                                          EdgeInsets.all(8),
                                                      child: Text("Attendance",
                                                          style: TextStyle(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold))),
                                                  const Row(
                                                    children: [
                                                      Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 5.0,
                                                                horizontal:
                                                                    16.0),
                                                        child:
                                                            Text("15/09/2024"),
                                                      )
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 5.0,
                                                                horizontal:
                                                                    16.0),
                                                        child: Checkbox(
                                                          value: classPageValues
                                                              .studentsListToShow
                                                              .every((student) =>
                                                                  selectedIds
                                                                      .contains(
                                                                          student[
                                                                              'id'])),
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              if (value ==
                                                                  true) {
                                                                // Select all IDs
                                                                classPageValues
                                                                    .studentsListToShow
                                                                    .forEach(
                                                                        (element) {
                                                                  if (!selectedIds
                                                                      .contains(
                                                                          element[
                                                                              'id'])) {
                                                                    selectedIds.add(
                                                                        element[
                                                                            'id']);
                                                                  }
                                                                });
                                                              } else {
                                                                // Clear all selected IDs
                                                                selectedIds
                                                                    .clear();
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      const Text("Mark All",
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ],
                                                  ),
                                                  MouseRegion(
                                                    cursor: SystemMouseCursors
                                                        .click,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        print(
                                                            "Mark Attendance tapped!");
                                                        // Add logic for marking attendance
                                                      },
                                                      child: Container(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            vertical: 8.0,
                                                            horizontal: 16.0),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .greenAccent
                                                              .shade100,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        child: const Row(
                                                          children: [
                                                            Icon(
                                                                Icons
                                                                    .check_circle_outline,
                                                                size: 20.0,
                                                                color: Colors
                                                                    .white),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        : const SizedBox(
                                            width: 250,
                                          ),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              classPageValues.showGradeCard
                  ? ColoredBox(
                      color: Theme.of(context).cardColor.withOpacity(.4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 100,
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Report Card',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 800,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GradeCard(
                                key: ValueKey(_studentId),
                                studentId: _studentId,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(
                      width: double.infinity,
                    ),
              _testResults.isNotEmpty &&
                      _allSubjects.isNotEmpty &&
                      classPageValues.showGradeCard
                  ? Expanded(
                      child: TestAnalytics(
                        allSubjects: _allSubjects
                            .map((e) => e['subject_name'] as String)
                            .toList(),
                        testResults: _testResults,
                        key: ValueKey(_testResults.hashCode),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        );
      }),
    );
  }

  void setAnalyticsStudentId(String studentId) async {
    // Clear the previous test results
    _testResults.clear();

    // Fetch subjects for the student
    _allSubjects = await _dbHelper.getSubjectsOfStudentID(studentId);

    for (var subject in _allSubjects) {
      var subjectId = subject['subject_id'];
      var testHistory = await _dbHelper.getTestHistoryForSubjectOfStudentID(
          studentId, subjectId);
      // print(" $studentId : :\n -------------------------\n$testHistory\n\n");

      // Add the test history to the results
      _testResults.add(testHistory);
    }

    // Update the state to rebuild the widget with new data
    if (mounted) {
      setState(() {
        // Use a unique key for the TestAnalytics widget to trigger a rebuild
        _testResults =
            _testResults; // This is a redundant assignment, just for clarity
      });
    }
  }

  Widget _criteriaDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide:
              BorderSide(color: Colors.grey.withOpacity(.4), width: 0.4),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        focusColor: Colors.grey,
        contentPadding: const EdgeInsets.all(15.0),
      ),
      value: _selectedcriteria,
      items: _criteriaOptions.map((String criteria) {
        return DropdownMenuItem<String>(
          value: criteria,
          child: Text(criteria),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          if (mounted) {
            setState(() {
              _selectedcriteria = newValue;
            });
          }
        }
      },
      isExpanded: true,
      hint: const Text('Select Criteria'),
    );
  }

  List<String> selectedIds = [];
  Widget studentsListView(List<Map<String, dynamic>> students) {
    double _screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        height: 550,
        width: double.infinity,
        child: ListView.builder(
          findChildIndexCallback: (key) {
            return null;
          },
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.vertical,
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];

            return Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    child: Container(
                      margin: const EdgeInsets.all(4.0),
                      width: _studentId == student['id'] ? 450 : 400,
                      height: 70,
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: _studentId == student['id']
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.5)
                                : Colors.black.withOpacity(0.3),
                            width: _studentId == student['id'] ? 2 : 0.5),
                        borderRadius: BorderRadius.circular(8.0),
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          _studentId == student['id']
                              ? BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                )
                              : BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 0,
                                  offset: const Offset(0, 3),
                                ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 5,
                          ),
                          Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape
                                    .circle, // Make the container circular
                                border: Border.all(color: Colors.grey),
                              ),
                              clipBehavior: Clip
                                  .hardEdge, // Ensures the image is clipped to the circular shape

                              child: Image.file(
                                File(student[
                                    'photo_path']!), // Display the image without adding it as an asset
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Error fallback if Image.file fails
                                  return Image.asset(
                                    (student['gender'] == 'F'
                                        ? 'assets/fl.jpg'
                                        : 'assets/ml.jpg'),
                                    fit: BoxFit
                                        .cover, // Fills the circular container
                                  );
                                },
                              )),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student['student_name'] as String,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text(student['stream_name'] as String),
                              ],
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            child: _showActions
                                ? Checkbox(
                                    checkColor: Colors.white,
                                    fillColor: !_printSelected
                                        ? WidgetStateProperty.all((selectedIds
                                                    .contains(student['id']) &&
                                                _markAttendance
                                            ? const Color.fromARGB(
                                                255, 130, 215, 130)
                                            : const Color.fromARGB(
                                                255, 255, 147, 139)))
                                        : WidgetStateProperty.all(
                                            selectedIds.contains(student['id'])
                                                ? Colors.blue
                                                : Colors.white),
                                    activeColor: _printSelected
                                        ? Colors.blue
                                        : Colors.green,
                                    value: selectedIds.contains(student['id']),
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        if (newValue!) {
                                          selectedIds.add(student['id']);
                                        } else {
                                          selectedIds.remove(student['id']);
                                        }
                                      });
                                    },
                                  )
                                : const SizedBox(),
                          ),
                          const SizedBox(
                            width: 10,
                          )
                        ],
                      ),
                    ),
                    onDoubleTap: () {
                      if (mounted) {
                        setState(() {
                          if (_studentId == student['id']) {
                            _studentId = '';
                            Provider.of<ClassPageValues>(context, listen: false)
                                .setShowGradeCard(false);
                            _allSubjects = [];

                            return;
                          }
                          _studentId = student['id'];
                          Provider.of<ClassPageValues>(context, listen: false)
                              .setShowGradeCard(true);
                          setAnalyticsStudentId(_studentId);
                        });
                      }
                    },
                    onTap: () {
                      if (_showActions) {
                        if (mounted) {
                          setState(() {
                            if (selectedIds.contains(student['id'])) {
                              selectedIds.remove(student['id']);
                            } else {
                              selectedIds.add(student['id']);
                            }
                          });
                          return;
                        }
                      }
                      if (mounted) {
                        setState(() {
                          if (_studentId == student['id']) {
                            _studentId = '';
                            Provider.of<ClassPageValues>(context, listen: false)
                                .setShowGradeCard(false);
                            _allSubjects = [];

                            return;
                          }
                          _studentId = student['id'];
                          Provider.of<ClassPageValues>(context, listen: false)
                              .setShowGradeCard(true);
                          setAnalyticsStudentId(_studentId);
                        });
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> triggerPdfGeneration(bool isPrint) async {
    _savedCount = 0;
    _progress = 0.0;
    String? directoryPath;
    if (!isPrint)
      directoryPath = await _pickDirectory();
    else
      directoryPath = '';

    for (var studentId in List.from(selectedIds)) {
      setState(() {
        _radarData.clear();
        _isRadarDataAvailable = false;
      });
      await generatePDF(directoryPath!, studentId, isPrint);

      setState(() {
        _progress = (_savedCount + 1) / selectedIds.length;
      });

      setState(() {
        _radarData.clear(); // Clear data after processing

        _isRadarDataAvailable = false; // Reset flag
      });
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
        _progress = 0.0;
      });
    }
    if (_savedCount == selectedIds.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_savedCount Reports saved to: $directoryPath'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _studentName = '';
  String _className = '';
  String _classId = '';
  String studentAcadamicYear = '';
  String currentMonth = DateTime.now().month.toString();
  String photoUrl = '';
  String errorPhotoUrl = 'assets/ml.jpg';
  String _gender = '';
  String schoolName = '';
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> _radarData = [];
  bool _isRadarDataAvailable = false;
  Map<String, dynamic> studentData = {};

  Future<void> fetchStudentData(String idForPdf) async {
    if (idForPdf == '') {
      print("Student id is 0");
      return;
    }
    List<Map<String, dynamic>> studentData =
        await _dbHelper.getStudentData(idForPdf);
    if (studentData.isEmpty) {
      return;
    }

    List<Map<String, dynamic>> resultsfromDb =
        await _dbHelper.getGradeCard(idForPdf);
    if (resultsfromDb.isEmpty) {
      throw Exception("No data found for student name: ${idForPdf}");
    }
    // print("Results received from db: $resultsfromDb");
    List<Map<String, dynamic>> results = getLatestScores(resultsfromDb);

    if (studentData.isNotEmpty) {
      if (mounted) {
        setState(() {
          _studentName = studentData.first['student_name'] as String? ?? '-';
          _className = studentData.first['class_name'] as String? ?? '-';
          schoolName = studentData.first['school_name'] as String? ?? '-';
          photoUrl = studentData.first['photo_path'];
          _gender = studentData.first['gender'] as String? ?? 'M';

          if (!File(photoUrl).existsSync()) {
            errorPhotoUrl =
                (_gender == 'M' ? 'assets/ml.jpg' : 'assets/fl.jpg');
          }

          _classId =
              Provider.of<ClassPageValues>(context, listen: false).classId;
          initializeStreamNames(_classId);
        });
      }
    } else {
      print("Student data is empty");
    }

    if (results.isNotEmpty) {
      // Using a standard for loop to handle async operations correctly
      List<Map<String, dynamic>> uniqueResults = [];
      Set<String> subjectNames = {};

      for (var element in results) {
        if (!subjectNames.contains(element['subject_name'])) {
          subjectNames.add(element['subject_name']);
          uniqueResults.add(element);
        }
      }

      for (var element in uniqueResults) {
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
            idForPdf, element['subject_id']);
        // await Future.delayed(const Duration(milliseconds: 1000));

        // Ensure avg is a double and handle null values
        double averageScore = (avg is double)
            ? avg
            : 0.0; // Default to 0.0 if avg is null or not a double

        double currentPercentage = (marks * 100 / maxMarks).isNaN ||
                (marks * 100 / maxMarks).isInfinite
            ? 0.0
            : (marks * 100 / maxMarks);
        // Update _radarData with the new average score

        setState(() {
          _radarData.add({
            'subject': element['subject_name'],
            'marks': [averageScore, currentPercentage],
          });
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
    } else {
      print("Results is empty");
    }

    setState(() {
      _radarData;
      _isRadarDataAvailable = true;
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

  ScreenshotController _screenshotController = ScreenshotController();
  Widget verticalCardPrint(String idForPdf) {
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          LegendItem(
                            color: Colors.green,
                            isDotted: true,
                            label: 'Average',
                          ),
                          SizedBox(width: 16),
                          LegendItem(
                            color: Colors.blue,
                            isDotted: false,
                            label: 'Latest',
                          ),
                        ],
                      ),
                    ],
                  ),
                  Spacer(),
                  Column(
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
                    child: _isRadarDataAvailable
                        ? RadarChartWidget(
                            key: ValueKey(
                                _radarData.hashCode), // Forces widget update
                            subjectsData: _radarData,
                          )
                        : const SizedBox(
                            child: Text("No data found"),
                          ),
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

  Future<void> generatePDF(
      String directoryPath, String idForPdf, bool isPrint) async {
    await fetchStudentData(idForPdf);
    if (_studentName.isEmpty) {
      return;
    }
    if ((directoryPath == null || directoryPath.isEmpty) && !isPrint)
      return; // User canceled

    // Generate a unique file name for each student
    String timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .replaceAll('T', '_')
        .replaceAll('Z', ''); // Optional: Remove 'Z' if you prefer

    String outputPath =
        '$directoryPath/${_studentName} report-card $timestamp.pdf';

    setState(() {
      _isSaving = true; // Show the progress indicator
    });

    // If the user canceled the save dialog, exit the function
    if (outputPath == null) return;
    setState(() {
      _isSaving = true; // Show the progress indicator
    });

    final pdf = pw.Document();
    var container = verticalCardPrint(idForPdf);

    final screenshotImage = await _screenshotController.captureFromWidget(
      InheritedTheme.captureAll(context, Material(child: container)),
      delay: const Duration(microseconds: 1),
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

      final outputFile = File(outputPath);

      try {
        if (isPrint) {
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
          );
        } else {
          await outputFile.writeAsBytes(await pdf.save());
        }

        // Show success feedback

        setState(() {
          _savedCount++;

          if (selectedIds.length == _savedCount) {
            _isSaving = false; // Hide the progress indicator
          }
          // Hide the progress indicator
        });
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
  }
}
