import 'package:flutter/material.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
import 'dart:math';

class RadarChartWidget extends StatelessWidget {
  // Ticks for the chart
  final List<Map<String, dynamic>> subjectsData;
  const RadarChartWidget({
    Key? key,
    required this.subjectsData,
  }) : super(key: key);

  Map<String, dynamic> convertSubjectsData(List<Map<String, dynamic>> data) {
    print(data);
    // Extract features and marks
    List<String> features =
        subjectsData.map((subject) => subject['subject'] as String).toList();

    // Create a valueData list with one entry for each subject
    List<List<double>> valueData = [];

    // Assuming each subject has the same number of marks
    for (int i = 0; i < subjectsData[0]['marks'].length; i++) {
      List<double> marksForEntry = subjectsData
          .map((subject) => (subject['marks'][i] as num).toDouble())
          .toList();
      valueData.add(marksForEntry);
    }
    print(valueData);
    return {
      'features': features,
      'valueData': valueData,
    };
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = convertSubjectsData(subjectsData);

    List<int> ticks = []; // Ticks for the chart

    switch (data['features'].length) {
      case 3:
        ticks = [50, 100];
        break;
      case 5:
        ticks = [25, 50, 75, 100];
        break;
      case 7:
        ticks = [25, 50, 75, 100];
        break;
      default:
        ticks = [50, 100];
    }

    return Container(
      color: Colors.white,
      child: Center(
        child: RadarChart(
          ticks: ticks,
          features: data['features'],
          data: data['valueData'],
          outlineColor: Colors.grey,
          sides: data['features'].length, // Number of sides in the chart
          featuresTextStyle: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
          key: UniqueKey(),
          ticksTextStyle: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
