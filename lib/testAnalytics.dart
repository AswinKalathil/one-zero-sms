import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:one_zero/database_helper.dart';
import 'package:intl/intl.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

class ScoreDataPoints {
  ScoreDataPoints({required this.x, required this.y});

  final int x; // Test index
  final int y; // Score percentage

  @override
  String toString() => 'x: $x, y: $y'; // Override toString for debugging
}

// ignore: must_be_immutable
class TestAnalytics extends StatefulWidget {
  final List<String> allSubjects;
  final List<List<Map<String, dynamic>>> testResults;

  TestAnalytics(
      {required this.allSubjects, required this.testResults, required Key key});

  @override
  State<TestAnalytics> createState() => _TestAnalyticsState();
}

class _TestAnalyticsState extends State<TestAnalytics> {
  Map<String, List<ScoreDataPoints>> graphListMap = {};

  DatabaseHelper dbHelper = DatabaseHelper();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _createAllDataPoints();
  }

  void _createAllDataPoints() {
    graphListMap
        .clear(); // Clear any existing data to avoid retaining old values

    for (var subject in widget.allSubjects) {
      createDataPointsForSubject(subject);
    }
  }

  void createDataPointsForSubject(String subject) {
    // Get the index of the subject in the allSubjects list

    int subjectIndex = widget.allSubjects.indexOf(subject);

    if (subjectIndex == -1) {
      print('Subject not found: $subject');
      return; // If subject not found in the list, return
    }
    if (widget.testResults.length <= subjectIndex) {
      // print(
      //     "error=====Subject Index: $subjectIndex   and length of list ${widget.testResults.length}");
      return;
    }
    // Get the list of test results for this subject
    List<Map<String, dynamic>> subjectTestResults =
        widget.testResults[subjectIndex].reversed.toList();
    List<ScoreDataPoints> dataPoints = [];

    // Iterate over the test results for the selected subject
    for (var i = 0; i < subjectTestResults.length; i++) {
      var test = subjectTestResults[i];

      // Initialize score and maxMark variables
      int score = 0;
      int maxMark = test['max_mark'] ?? 0; // Default to 0 if max_mark is null

      // Safely extract and convert score
      if (test['score'] is String) {
        if (test['score'] != '-' && test['score'].isNotEmpty) {
          // Attempt to parse score if it's a valid string
          try {
            score = int.parse(test['score']);
          } catch (e) {
            print('Error parsing score for test ID ${test['test_id']}: $e');
            score = 0; // Fallback on error
          }
        } else {
          score = -1;
        }
      } else if (test['score'] is int) {
        score = test['score']; // Use it directly if it's already an int
      }

      // Prevent division by zero if maxMark is 0
      if (maxMark > 0) {
        // Create data point where x = test index and y = score percentage
        ScoreDataPoints dataPoint = ScoreDataPoints(
          x: i + 1, // Test index (starting from 1)
          y: score == -1
              ? -1
              : ((score / maxMark) * 100).toInt(), // Score percentage
        );

        // Add the data point to the list
        dataPoints.add(dataPoint);
      } else {
        print('Warning: maxMark for test ID ${test['test_id']} is 0 or null.');
      }
    }

    // Add the data points for this subject to the graphListMap
    graphListMap[subject] = dataPoints;

    // Output for debugging purposes
    // print("Data points for $subject: $dataPoints");
  }

// Class to store the data points

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    for (var subject in widget.allSubjects) {
      createDataPointsForSubject(subject);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.only(top: 50.0, bottom: 20),
            child: Center(
              child: Text('Detailed Performance Analysis',
                  style:
                      TextStyle(fontSize: 8.sp, fontWeight: FontWeight.bold)),
            )),
        SizedBox(
          height: 20,
        ),
        widget.testResults.isNotEmpty && widget.allSubjects.isNotEmpty
            ? SizedBox(
                height: screenWidth > 1200
                    ? (((widget.allSubjects.length + 1) / 2).ceil() * 430.0)
                    : ((widget.allSubjects.length + 1) * 500.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth > 1200 ? 2 : 1,
                      childAspectRatio: screenWidth > 1200 ? 3.7 / 2.1 : 2 / 1),
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable scrolling

                  itemCount: widget.allSubjects.length + 1,
                  itemBuilder: (context, index) {
                    if (widget.testResults.length < index) {
                      return CircularProgressIndicator();
                    }

                    if (index == widget.allSubjects.length) {
                      return Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        width: double.infinity,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 20.0, top: 8, bottom: 8),
                                child: Text('Overall Analysis',
                                    style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Divider(),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                height: 290,
                                child: SfCartesianChart(
                                  primaryXAxis: CategoryAxis(
                                    title: AxisTitle(
                                        text:
                                            'Tests No.'), // Title for the X-axis
                                  ),
                                  primaryYAxis: NumericAxis(
                                    minimum: 0,
                                    maximum: 100,
                                    title: AxisTitle(
                                        text:
                                            'Score Percentage'), // Title for the Y-axis
                                  ),
                                  // Chart title
                                  title: ChartTitle(
                                    text: 'Overall Performance Trend',
                                    textStyle:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),

                                  // Enable legend
                                  legend: Legend(
                                    isVisible: true,
                                  ),

                                  // Enable tooltip
                                  tooltipBehavior: TooltipBehavior(
                                      enable: true, duration: 1),
                                  series: <CartesianSeries<ScoreDataPoints,
                                      int>>[
                                    ...widget.allSubjects
                                        .map((subject) {
                                          // Check if the data exists for the subject to avoid null exceptions
                                          if (graphListMap
                                              .containsKey(subject)) {
                                            return SplineSeries<ScoreDataPoints,
                                                int>(
                                              legendIconType:
                                                  LegendIconType.circle,
                                              width: 3,
                                              // Define the style of the line
                                              // Dotted line between points
                                              markerSettings: MarkerSettings(
                                                  isVisible: true,
                                                  width: 4,
                                                  height: 4,
                                                  shape: DataMarkerType.circle),

                                              dataSource: graphListMap[subject],
                                              xValueMapper:
                                                  (ScoreDataPoints exam, _) =>
                                                      exam.x,
                                              yValueMapper:
                                                  (ScoreDataPoints exam, _) =>
                                                      exam.y == -1
                                                          ? null
                                                          : exam.y,
                                              name: subject,
                                              // Enable data label
                                              dataLabelSettings:
                                                  DataLabelSettings(
                                                      isVisible: false),
                                            );
                                          } else {
                                            return null; // Return null if no data exists for that subject
                                          }
                                        })
                                        .where((series) => series != null)
                                        .cast<
                                            SplineSeries<ScoreDataPoints,
                                                int>>()
                                        .toList(), // Filter out nulls
                                  ],
                                ),
                              )
                            ]),
                      );
                    } else {
                      List<Map<String, dynamic>> result = [];

                      if (widget.testResults.length >= index) {
                        result = widget.testResults[index];

                        return Container(
                          height: 400,
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 20.0, top: 8, bottom: 8),
                                child: Text(widget.allSubjects[index],
                                    style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 20, top: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Table(
                                              border: TableBorder.all(
                                                  color: Colors.grey,
                                                  width: .4),
                                              columnWidths: const {
                                                0: FlexColumnWidth(1),
                                                1: FlexColumnWidth(3),
                                                2: FlexColumnWidth(1),
                                                3: FlexColumnWidth(1),
                                              },
                                              children: [
                                                TableRow(
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(6.0),
                                                      child: Center(
                                                        child: FittedBox(
                                                          child: Text(
                                                            'Test No.',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(6.0),
                                                      child: Center(
                                                        child: FittedBox(
                                                          child: Text(
                                                            'Chapter Name',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(6.0),
                                                      child: Center(
                                                        child: FittedBox(
                                                          child: Text(
                                                            'Marks',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(6.0),
                                                      child: Center(
                                                        child: FittedBox(
                                                          child: Text(
                                                            'Date',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ]),
                                          SizedBox(
                                            width: double.infinity,
                                            height: getWidthBasedOnScreenSize(
                                                    context) -
                                                32,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.vertical,
                                              physics: BouncingScrollPhysics(),
                                              child: Container(
                                                decoration: BoxDecoration(),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    result.isNotEmpty
                                                        ? Table(
                                                            border:
                                                                TableBorder.all(
                                                                    color: Colors
                                                                        .grey,
                                                                    width: .4),
                                                            columnWidths: const {
                                                              0: FlexColumnWidth(
                                                                  1),
                                                              1: FlexColumnWidth(
                                                                  3),
                                                              2: FlexColumnWidth(
                                                                  1),
                                                              3: FlexColumnWidth(
                                                                  1),
                                                            },
                                                            children: [
                                                              ...result
                                                                  .asMap()
                                                                  .entries
                                                                  .map(
                                                                (entry) {
                                                                  int rowIndex =
                                                                      entry.key +
                                                                          1;
                                                                  var subject =
                                                                      entry
                                                                          .value;
                                                                  return TableRow(
                                                                    decoration: BoxDecoration(
                                                                        color: (Theme.of(context).brightness == Brightness.light)
                                                                            ? (rowIndex % 2 == 0
                                                                                ? Colors.grey.shade200
                                                                                : Colors.white)
                                                                            : (rowIndex % 2 == 0 ? Colors.grey.shade600 : Colors.grey.shade700)),
                                                                    children: [
                                                                      Container(
                                                                        height:
                                                                            30,
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            5.5),
                                                                        child: FittedBox(
                                                                            child:
                                                                                Text((result.length - rowIndex + 1).toString() ?? '')),
                                                                      ),
                                                                      Container(
                                                                        height:
                                                                            30,
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            5.5),
                                                                        child:
                                                                            FittedBox(
                                                                          child:
                                                                              Text(subject['topic'].toString() ?? '-'),
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        height:
                                                                            30,
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            5.5),
                                                                        child: FittedBox(
                                                                            child:
                                                                                Text("${subject['score']} / ${subject['max_mark']}" ?? '')),
                                                                      ),
                                                                      Container(
                                                                        height:
                                                                            30,
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            5.5),
                                                                        child: FittedBox(
                                                                            child:
                                                                                Text(DateFormat('MMM dd').format(DateTime.parse(subject['test_date'])) ?? '')),
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                              ),
                                                            ],
                                                          )
                                                        : Container(
                                                            height:
                                                                200, // Adjust height as needed
                                                            child: const Center(
                                                              child: Text(
                                                                  'No tests available'),
                                                            ),
                                                          ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: FractionallySizedBox(
                                      widthFactor: 1,
                                      child: Container(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: getWidthBasedOnScreenSize(
                                                  context), // Set the height as per your requirement
                                              child: SfCartesianChart(
                                                primaryXAxis: CategoryAxis(
                                                  title: AxisTitle(
                                                      text: 'Tests No.',
                                                      textStyle: TextStyle(
                                                          fontSize: 4.sp)),
                                                ),
                                                primaryYAxis: NumericAxis(
                                                  maximum: 100,
                                                  minimum: 0,
                                                  interval: 25,
                                                  title: AxisTitle(
                                                      text: 'Score Percentage',
                                                      textStyle: TextStyle(
                                                          fontSize: 4.sp)),
                                                ),
                                                title: ChartTitle(
                                                  text: 'Performance Trend',
                                                  textStyle: TextStyle(
                                                      fontSize: 4.sp,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                legend:
                                                    Legend(isVisible: false),
                                                tooltipBehavior:
                                                    TooltipBehavior(
                                                        enable: true),
                                                series: <CartesianSeries<
                                                    ScoreDataPoints, int>>[
                                                  LineSeries<ScoreDataPoints,
                                                      int>(
                                                    dataSource: graphListMap[
                                                        widget.allSubjects[
                                                            index]],
                                                    xValueMapper:
                                                        (ScoreDataPoints exam,
                                                                _) =>
                                                            exam.x,
                                                    yValueMapper:
                                                        (ScoreDataPoints exam,
                                                                _) =>
                                                            exam.y == -1
                                                                ? null
                                                                : exam.y,
                                                    // spacing: 0.5,
                                                    name: 'Percentage Score',
                                                    markerSettings:
                                                        MarkerSettings(
                                                            isVisible: true,
                                                            width: 4,
                                                            height: 4,
                                                            shape:
                                                                DataMarkerType
                                                                    .circle),
                                                    dataLabelSettings:
                                                        DataLabelSettings(
                                                      isVisible: true,
                                                      textStyle: TextStyle(
                                                          fontSize: 2.sp),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Container(
                          height: 200, // Adjust height as needed
                          child: const Center(
                            child: Text('No tests available'),
                          ),
                        );
                      }
                    }
                  },
                ),
              )
            : Container(
                height: 200, // Adjust height as needed
                child: const Center(
                  child: Text('No tests available'),
                ),
              ),
        // Divider(),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 100.0),
        //   child: SizedBox(
        //     width: double.infinity,
        //     child:
        //         Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        //       Padding(
        //         padding: const EdgeInsets.all(30.0),
        //         child: Text('Overall Analysis',
        //             style:
        //                 TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
        //       ),
        //       Container(
        //         decoration: BoxDecoration(
        //           color: Theme.of(context).cardColor,
        //           borderRadius: BorderRadius.circular(10),
        //         ),
        //         height: 500,
        //         child: SfCartesianChart(
        //           primaryXAxis: CategoryAxis(
        //             title: AxisTitle(text: 'Tests No.'), // Title for the X-axis
        //           ),
        //           primaryYAxis: NumericAxis(
        //             minimum: 0,
        //             maximum: 100,
        //             title: AxisTitle(
        //                 text: 'Percentage Marks'), // Title for the Y-axis
        //           ),
        //           // Chart title
        //           title: ChartTitle(
        //             text: 'Performance Trend',
        //             textStyle: TextStyle(fontWeight: FontWeight.bold),
        //           ),

        //           // Enable legend
        //           legend: Legend(
        //             isVisible: true,
        //           ),

        //           // Enable tooltip
        //           tooltipBehavior: TooltipBehavior(enable: true, duration: 1),
        //           series: <CartesianSeries<ScoreDataPoints, int>>[
        //             ...widget.allSubjects
        //                 .map((subject) {
        //                   // Check if the data exists for the subject to avoid null exceptions
        //                   if (graphListMap.containsKey(subject)) {
        //                     return SplineSeries<ScoreDataPoints, int>(
        //                       legendIconType: LegendIconType.circle,
        //                       width: 3,
        //                       // Define the style of the line
        //                       // Dotted line between points
        //                       markerSettings: MarkerSettings(
        //                           isVisible: true,
        //                           width: 4,
        //                           height: 4,
        //                           shape: DataMarkerType.circle),

        //                       dataSource: graphListMap[subject],
        //                       xValueMapper: (ScoreDataPoints exam, _) => exam.x,
        //                       yValueMapper: (ScoreDataPoints exam, _) =>
        //                           exam.y == -1 ? null : exam.y,
        //                       name: subject,
        //                       // Enable data label
        //                       dataLabelSettings:
        //                           DataLabelSettings(isVisible: false),
        //                     );
        //                   } else {
        //                     return null; // Return null if no data exists for that subject
        //                   }
        //                 })
        //                 .where((series) => series != null)
        //                 .cast<SplineSeries<ScoreDataPoints, int>>()
        //                 .toList(), // Filter out nulls
        //           ],
        //         ),
        //       )
        //     ]),
        //   ),
        // )
      ],
    );
  }

  double getWidthBasedOnScreenSize(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    // Assign category based on width
    int category;
    if (width > 1200) {
      category = 4;
    } else if (width > 1000) {
      category = 3;
    } else if (width > 800) {
      category = 2;
    } else {
      category = 1;
    }

    // Use switch to return width based on the category
    switch (category) {
      case 4:
        return 211; // For screens larger than 1200
      case 3:
        return 300; // For screens between 1001 and 1200
      case 2:
        return 180;
      case 1: // For screens between 801 and 1000
      default:
        return 200; // For screens smaller than 1000
    }
  }
}
