import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// // Sample subjects data
// List<Map<String, dynamic>> subjectsData = [
//   {
//     "subject": "Mathematics",
//     "maxMarks": 80,
//     "marks": 76,
//     "grade": "A+",
//     "date": "30-09-2024"
//   },
//   {
//     "subject": "Physics",
//     "maxMarks": 100,
//     "marks": 35,
//     "grade": "F",
//     "date": "30-09-2024"
//   },
//   {
//     "subject": "Chemistry",
//     "maxMarks": 50,
//     "marks": 26,
//     "grade": "C+",
//     "date": "30-09-2024"
//   },
//   {
//     "subject": "Botany",
//     "maxMarks": 30,
//     "marks": 26,
//     "grade": "A",
//     "date": "30-09-2024"
//   },
//   {
//     "subject": "Zoology",
//     "maxMarks": 100,
//     "marks": 83,
//     "grade": "A",
//     "date": "30-09-2024"
//   }
// ];

class AppColors {
  static const Color contentColorBlue = Color(0xFF00BFFF);
  static const Color contentColorYellow = Color(0xFFFFD700);
  static const Color contentColorPurple = Color(0xFF800080);
  static const Color contentColorGreen = Color(0xFF008000);
  static const Color mainTextColor1 = Colors.white;
}

class PieChartSample2 extends StatefulWidget {
  List<Map<String, dynamic>> subjectsData;
  PieChartSample2({required this.subjectsData, super.key});

  @override
  State<StatefulWidget> createState() => PieChart2State();
}

class PieChart2State extends State<PieChartSample2> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: <Widget>[
          const SizedBox(height: 18),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: showingSections(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
          _buildLegend(),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    double totalMarks =
        widget.subjectsData.fold(0, (sum, item) => sum + item['marks']);

    return List.generate(widget.subjectsData.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final subject = widget.subjectsData[i];
      final double percentage = (subject['marks'] / totalMarks) * 100;

      return PieChartSectionData(
        color: _getColorForSubject(subject['subject']),
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: AppColors.mainTextColor1,
          shadows: shadows,
        ),
      );
    });
  }

  Color _getColorForSubject(String subject) {
    switch (subject) {
      case 'Mathematics':
        return AppColors.contentColorBlue;
      case 'Physics':
        return AppColors.contentColorYellow;
      case 'Chemistry':
        return AppColors.contentColorPurple;
      case 'Botany':
        return AppColors.contentColorGreen;
      case 'Zoology':
        return Colors.orange; // Custom color for Zoology
      default:
        return Colors.grey;
    }
  }

  Widget _buildLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.subjectsData.map((subject) {
        return Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: _getColorForSubject(subject['subject']),
            ),
            const SizedBox(width: 8),
            Text(subject['subject']),
          ],
        );
      }).toList(),
    );
  }
}
