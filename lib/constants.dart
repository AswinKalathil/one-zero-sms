import 'package:flutter/material.dart';

final List<Color> cardBackgroundColors = [
  Color.fromARGB(255, 176, 213, 226), // Light Blue
  Color.fromARGB(255, 50, 172, 113), // Light Green
  Color.fromARGB(255, 255, 222, 137), // Light Yellow
  Color(0xFFF08080), // Light Coral
  Color.fromARGB(255, 194, 194, 231), // Light Lavender
  Color(0xFFFFDAB9), // Light Peach
];
List<String> streams = ['Science', 'Commerce', 'Arts'];
List<String> classNames = [
  'Plustwo CBSE',
  'Plustwo STATE',
  'Plusone CBSE',
  'Plusone STATE',
  '10th CBSE',
  '10th STATE',
  '9th CBSE',
  '9th STATE'
];

class InputTableMetadata {
  final String tableName;
  final List<String> columnNames;
  final List<double> columnLengths;

  InputTableMetadata(
      {required this.tableName,
      required this.columnNames,
      required this.columnLengths});
}

// Assuming InputTableMetadata class is already defined as mentioned before.
Map<String, InputTableMetadata> tableMetadataMap = {
  "class_table": InputTableMetadata(
    tableName: "class_table",
    columnNames: [
      "ID",
      "Class Name",
      "Academic Year",
      "Subjects",
      "Actions",
    ],
    columnLengths: [
      50,
      150,
      100,
      150,
      50,
    ],
  ),
  "student_table": InputTableMetadata(
    tableName: "student_table",
    columnNames: [
      "ID",
      "Student Name",
      "Stream name",
      "School Name",
      "Student Phone",
      "Parent Name",
      "parent Phone",
      "Photo path",
      "Actions"
    ],
    columnLengths: [
      50,
      150,
      50,
      100,
      100,
      150,
      100,
      100,
      50,
    ],
  ),
  "subject_table": InputTableMetadata(
    tableName: "subject_table",
    columnNames: ["ID", "Subject Name", "Class ID", "Actions"],
    columnLengths: [
      50,
      100,
      50,
      50,
    ],
  ),
  "stream_table": InputTableMetadata(
    tableName: "stream_table",
    columnNames: ["ID", "Stream Name", "Class ID", "Subjects", "Actions"],
    columnLengths: [
      50,
      100,
      50,
      200,
      50,
    ],
  ),
  "test_table": InputTableMetadata(
    tableName: "test_table",
    columnNames: ["ID", "Subject Name", "Max Marks", "Test Date", "Save"],
    columnLengths: [
      50,
      100,
      50,
      50,
      50,
    ],
  ),
  "marks_table": InputTableMetadata(
    tableName: "marks_table",
    columnNames: ["ID", "Student Name", "Marks Obtained", "Actions"],
    columnLengths: [
      50,
      50,
      50,
      50,
      50,
    ],
  ),
};
