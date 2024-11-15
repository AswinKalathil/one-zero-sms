// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:screenshot/screenshot.dart';

// /// Load student image from assets
// Future<Uint8List> loadStudentImage() async {
//   final data = await rootBundle.load('assets/ml.jpg');
//   return data.buffer.asUint8List();
// }

// /// Capture radar chart image using ScreenshotController
// Future<Uint8List> captureRadarChartImage(
//     ScreenshotController screenshotController) async {
//   return await screenshotController.capture() ?? Uint8List(0);
// }

// /// Create the PDF document with radar chart image
// Future<Uint8List> createPDF({
//   required String studentName,
//   required String className,
//   required String schoolName,
//   required List<Map<String, dynamic>> subjects,
//   required Uint8List studentImage,
//   required Uint8List radarChartImage,
// }) async {
//   final pdf = pw.Document();

//   pdf.addPage(
//     pw.Page(
//       build: (pw.Context context) => pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.start,
//             children: [
//               pw.Container(
//                 width: 80,
//                 height: 100,
//                 child: pw.Image(pw.MemoryImage(studentImage)),
//               ),
//               pw.SizedBox(width: 20),
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(studentName,
//                       style: pw.TextStyle(
//                           fontSize: 20, fontWeight: pw.FontWeight.bold)),
//                   pw.Text(className, style: pw.TextStyle(fontSize: 16)),
//                   pw.Text(schoolName, style: pw.TextStyle(fontSize: 16)),
//                 ],
//               ),
//             ],
//           ),
//           pw.SizedBox(height: 20),
//           pw.Text('Latest Grades',
//               style:
//                   pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
//           pw.SizedBox(height: 10),
//           pw.Table.fromTextArray(
//             headers: ['Subject', 'Marks', 'Grade', 'Date'],
//             data: subjects
//                 .map((subject) => [
//                       subject['subject'] ?? '',
//                       "${subject['marks']} / ${subject['maxMarks']}" ?? '-',
//                       subject['grade'] ?? '',
//                       subject['date'] ?? '',
//                     ])
//                 .toList(),
//           ),
//           pw.SizedBox(height: 20),
//           pw.Text(
//             'Date: ${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}',
//             style: pw.TextStyle(fontSize: 10),
//           ),
//           pw.SizedBox(height: 20),
//           pw.Text('Radar Chart',
//               style:
//                   pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
//           pw.SizedBox(height: 10),
//           pw.Container(
//             width: 200,
//             height: 200,
//             child: pw.Image(pw.MemoryImage(radarChartImage)),
//           ),
//         ],
//       ),
//     ),
//   );

//   return pdf.save();
// }

// /// Generate and display PDF, including radar chart
// Future<void> generateAndDisplayPDF(
//     ScreenshotController screenshotController) async {
//   final studentImage = await loadStudentImage();
//   final radarChartImage = await captureRadarChartImage(screenshotController);

//   final pdfData = await createPDF(
//     studentName: 'Ajith Jose Shaji',
//     className: 'Plus Two',
//     schoolName: 'Example School',
//     subjects: [
//       {
//         'subject': 'Math',
//         'marks': 95,
//         'maxMarks': 100,
//         'grade': 'A+',
//         'date': '2024-11-11'
//       },
//       {
//         'subject': 'Science',
//         'marks': 88,
//         'maxMarks': 100,
//         'grade': 'A',
//         'date': '2024-11-11'
//       },
//     ],
//     studentImage: studentImage,
//     radarChartImage: radarChartImage,
//   );

//   await Printing.layoutPdf(onLayout: (format) => pdfData);
// }

// /// Radar chart widget wrapped in RepaintBoundary for screenshot
// class RadarChartWidgetprint extends StatelessWidget {
//   final ScreenshotController screenshotController;

//   RadarChartWidgetprint({required this.screenshotController});

//   @override
//   Widget build(BuildContext context) {
//     return Screenshot(
//       controller: screenshotController,
//       child: RepaintBoundary(
//         child: Container(
//           width: 200,
//           height: 200,
//           color: Colors.blue, // Replace with radar chart widget.
//           child: Center(child: Text('Radar Chart Placeholder')),
//         ),
//       ),
//     );
//   }
// }
