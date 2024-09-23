import 'package:flutter/material.dart';

import 'package:one_zero/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stroke_text/stroke_text.dart';

final List<Color> cardBackgroundColors = [
  // Color.fromARGB(255, 176, 213, 226), // Light Blue
  // Color.fromARGB(255, 50, 172, 113), // Light Green
  // Color.fromARGB(255, 255, 222, 137), // Light Yellow
  // Color(0xFFF08080), // Light Coral
  Color.fromARGB(255, 194, 194, 231), // Light Lavender
  // Color(0xFFFFDAB9), // Light Peach
];

//   ? Color.fromARGB(255, 2, 47, 22)
// : Color.fromARGB(255, 45, 205, 114),
Column getLogo(double fontSize) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      StrokeText(
        strokeColor: Color.fromRGBO(0, 0, 0, 0.05),
        strokeWidth: 2,
        textAlign: TextAlign.center,
        text: "ONE ZERO",
        textStyle: TextStyle(
          fontSize: fontSize + 10,
          fontFamily: 'Revue',
          color: Color.fromRGBO(70, 68, 68, 0.05),
        ),
      ),
      StrokeText(
        strokeColor: Color.fromRGBO(0, 0, 0, 0.05),
        strokeWidth: 2,
        textAlign: TextAlign.center,
        text: " TUITION + ENTRENCE",
        textStyle: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Revue',
          color: Color.fromRGBO(70, 68, 68, 0.05),
        ),
      ),
    ],
  );
}

DatabaseHelper dbHelperForConstants = DatabaseHelper();
Future<List<String>> getStreamNames() async {
  return await dbHelperForConstants.getStreamNames();
}

Future<void> initializeStreamNames() async {
  STREAM_NAMES = await getStreamNames();
}

List<String> STREAM_NAMES = [];

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
      "Stream Name",
      "School Name",
      "Gender",
      "Parent Phone",
      "Photo Path",
      "Remove"
    ],
    columnLengths: [
      50,
      150,
      200,
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

String cretateQuery = '''
CREATE TABLE class_table (
  id INTEGER PRIMARY KEY ,           
  class_name TEXT NOT NULL,              
  academic_year TEXT NOT NULL             
);

CREATE TABLE stream_table (
  id INTEGER PRIMARY KEY , 
  stream_name TEXT NOT NULL,  
  class_id INTEGER,                          
  FOREIGN KEY (class_id) REFERENCES class_table(id)
);

CREATE TABLE subject_table (
  id INTEGER PRIMARY KEY ,   
  subject_name TEXT NOT NULL,            
  class_id INTEGER,
  FOREIGN KEY (class_id) REFERENCES class_table(id)
);

CREATE TABLE stream_subjects_table (
  id INTEGER PRIMARY KEY ,   
  stream_id INTEGER,
  subject_id INTEGER,
  FOREIGN KEY (stream_id) REFERENCES stream_table(id),
  FOREIGN KEY (subject_id) REFERENCES subject_table(id)
);

CREATE TABLE student_table (
  id INTEGER PRIMARY KEY ,  
  student_name TEXT NOT NULL,
  photo_id TEXT,
  parent_phone TEXT,
  gender TEXT,
  school_name TEXT,
  stream_id INTEGER NOT NULL,
  FOREIGN KEY (stream_id) REFERENCES stream_table(id)
);

CREATE TABLE test_table (
  id INTEGER PRIMARY KEY ,   
  subject_id INTEGER,
  topic TEXT,
  max_mark INTEGER,
  test_date DATETIME NOT NULL,
  FOREIGN KEY (subject_id) REFERENCES subject_table(id)
);

CREATE TABLE test_score_table (
  id INTEGER PRIMARY KEY Autoincrement,   
  score INTEGER,
  student_id INTEGER,
  test_id INTEGER,
  FOREIGN KEY (student_id) REFERENCES student_table(id),
  FOREIGN KEY (test_id) REFERENCES test_table(id)
);

CREATE VIEW student_grade_view AS
SELECT 
  s.id AS student_id,
  s.student_name,
  COALESCE(s.photo_id, 'default_photo.png') AS photo_path,
  c.class_name,
  c.academic_year,
  sub.subject_name,
  COALESCE(ts.score, 0) AS latest_score,
  t.max_mark,
  t.test_date
FROM student_table s
LEFT JOIN stream_table st ON s.stream_id = st.id
LEFT JOIN class_table c ON st.class_id = c.id
LEFT JOIN test_score_table ts ON s.id = ts.student_id
LEFT JOIN test_table t ON ts.test_id = t.id
LEFT JOIN subject_table sub ON t.subject_id = sub.id;



''';
