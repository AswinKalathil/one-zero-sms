import 'package:flutter/material.dart';
import 'package:one_zero/database_helper.dart';

class TestAnalytics extends StatelessWidget {
  final List<String> allSubjects;
  final List<List<Map<String, dynamic>>> testResults;

  TestAnalytics({required this.allSubjects, required this.testResults});
  DatabaseHelper dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    print('AllSubjects: $allSubjects');
    print('TestResults: $testResults');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        testResults.isNotEmpty
            ? ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 1000, // Adjust height as needed
                ),
                child: GridView.builder(
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable scrolling
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 3.5 / 3 // Number of rows
                      ),
                  itemCount: allSubjects.length,
                  itemBuilder: (context, index) {
                    var result = testResults[index];
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(allSubjects[index],
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Table(
                              border: TableBorder.all(
                                  color: Colors.grey, width: .4),
                              columnWidths: const {
                                0: FlexColumnWidth(1),
                                1: FlexColumnWidth(3),
                                2: FlexColumnWidth(1),
                                3: FlexColumnWidth(1),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: Center(
                                        child: Text(
                                          'SL No.',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: Center(
                                        child: Text(
                                          'Chapter Name',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: Center(
                                        child: Text(
                                          'Marks',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: Center(
                                        child: Text(
                                          'Date',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ]),
                          SizedBox(
                            width: double.infinity,
                            height: 300,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Container(
                                decoration: BoxDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    result.isNotEmpty
                                        ? Table(
                                            border: TableBorder.all(
                                                color: Colors.grey, width: .4),
                                            columnWidths: const {
                                              0: FlexColumnWidth(1),
                                              1: FlexColumnWidth(3),
                                              2: FlexColumnWidth(1),
                                              3: FlexColumnWidth(1),
                                            },
                                            children: [
                                              ...result.asMap().entries.map(
                                                (entry) {
                                                  int rowIndex = entry.key + 1;
                                                  var subject = entry.value;
                                                  return TableRow(
                                                    decoration: BoxDecoration(
                                                        color: (Theme.of(
                                                                        context)
                                                                    .brightness ==
                                                                Brightness
                                                                    .light)
                                                            ? (rowIndex % 2 == 0
                                                                ? Colors.grey
                                                                    .shade200
                                                                : Colors.white)
                                                            : (rowIndex % 2 == 0
                                                                ? Colors.grey
                                                                    .shade600
                                                                : Colors.grey
                                                                    .shade700)),
                                                    children: [
                                                      Container(
                                                        height: 30,
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.5),
                                                        child: FittedBox(
                                                            child: Text(rowIndex
                                                                    .toString() ??
                                                                '')),
                                                      ),
                                                      Container(
                                                        height: 30,
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.5),
                                                        child: FittedBox(
                                                          child: Text(subject[
                                                                      'topic']
                                                                  .toString() ??
                                                              '-'),
                                                        ),
                                                      ),
                                                      Container(
                                                        height: 30,
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.5),
                                                        child: FittedBox(
                                                            child: Text(
                                                                "${subject['score']} / ${subject['max_mark']}" ??
                                                                    '')),
                                                      ),
                                                      Container(
                                                        height: 30,
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.5),
                                                        child: FittedBox(
                                                            child: Text(subject[
                                                                        'test_date']
                                                                    .toString()
                                                                    .substring(
                                                                        0,
                                                                        10) ??
                                                                '')),
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
                                              child: Text('No tests available'),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            : Container(
                height: 200, // Adjust height as needed
                child: const Center(
                  child: Text('No tests available'),
                ),
              ),
      ],
    );
  }
}
