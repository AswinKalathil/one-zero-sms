
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:screenshot/screenshot.dart';

// class PdfGenerationScreen extends StatefulWidget {
//   @override
//   _PdfGenerationScreenState createState() => _PdfGenerationScreenState();
// }

// class _PdfGenerationScreenState extends State<PdfGenerationScreen> {
//   final ScreenshotController _screenshotController = ScreenshotController();

//   // This method captures the widget as an image
//   Future<Uint8List> _captureWidgetAsImage() async {
//     final screenshot = await _screenshotController.capture();
//     return screenshot!;
//   }

//   // This method generates and prints the PDF
//   Future<void> _generateAndPrintPDF() async {
//     final capturedImage = await _captureWidgetAsImage();

//     final pdf = pw.Document();

//     // Add the screenshot image to the PDF document
//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) {
//           return pw.Center(
//             child: pw.Image(pw.MemoryImage(capturedImage)),
//           ); // Display the captured widget as an image in the PDF
//         },
//       ),
//     );

//     // Use the printing package to print or save the PDF
//     Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
//       return pdf.save();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Capture Widget and Save as PDF')),
//       body: Screenshot(
//         controller: _screenshotController,
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Your widget that you want to capture
//               Container(
//                 width: 300,
//                 height: 400,
//                 decoration: BoxDecoration(
//                   color: Colors.blue,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Center(
//                   child: Text(
//                     'This is the widget to capture!',
//                     style: TextStyle(color: Colors.white, fontSize: 20),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _generateAndPrintPDF,
//                 child: const Text('Save as PDF'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // void main() => runApp(MaterialApp(home: PdfGenerationScreen()));
