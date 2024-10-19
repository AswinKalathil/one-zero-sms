import 'package:flutter/material.dart';

import 'package:one_zero/database_helper.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:mysql1/mysql1.dart';

ConnectionSettings dbSettingLocal = ConnectionSettings(
  host: 'localhost', // Update with your host
  port: 3306, // Default MySQL port
  user: 'root', // Update with your MySQL username
  password: '123', // Update with your MySQL password
  db: 'test1', // Update with your MySQL database name
  timeout: Duration(seconds: 1), // Connection timeout (default is 30 seconds)
);
ConnectionSettings dbSettingRemote = ConnectionSettings(
  host: 'sql.freedb.tech', // Update with your host
  port: 3306, // Default MySQL port
  user: 'freedb_tester_main', // Update with your MySQL username
  password: r'$whBv@c2Z8Trd@#', // Update with your MySQL password
  db: 'freedb_one_zero_test_remote_db', // Update with your MySQL database name
  timeout: Duration(seconds: 1), // Connection timeout (default is 30 seconds)
);

final List<Color> cardBackgroundColors = [
  Color.fromARGB(255, 176, 213, 226), // Light Blue
  Color.fromARGB(255, 50, 172, 113), // Light Green
  Color.fromARGB(255, 255, 222, 137), // Light Yellow
  Color(0xFFF08080), // Light Coral
  Color.fromARGB(255, 194, 194, 231), // Light Lavender
  Color(0xFFFFDAB9), // Light Peach
];

List<Color> GRAPH_LINE_COLORS = [
  Colors.blue, // Bright Blue
  Colors.red, // Bright Red
  Colors.green, // Bright Green
  Colors.orange, // Orange
  Colors.purple, // Purple
  Colors.teal, // Teal
  Colors.pink, // Pink
  Colors.amber, // Amber
];

//   ? Color.fromARGB(255, 2, 47, 22)
// : Color.fromARGB(255, 45, 205, 114),
Column getLogo(double fontSize, double opacity) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      StrokeText(
        strokeColor: Color.fromRGBO(0, 0, 0, opacity),
        strokeWidth: 2,
        textAlign: TextAlign.center,
        text: "ONE ZERO",
        textStyle: TextStyle(
          fontSize: fontSize + 10,
          fontFamily: 'Revue',
          color: Color.fromRGBO(70, 68, 68, opacity),
        ),
      ),
      StrokeText(
        strokeColor: Color.fromRGBO(0, 0, 0, opacity),
        strokeWidth: 2,
        textAlign: TextAlign.center,
        text: " TUITION + ENTRENCE",
        textStyle: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Revue',
          color: Color.fromRGBO(70, 68, 68, opacity),
        ),
      ),
    ],
  );
}

Column getLogoColored(double fontSize, double opacity) {
  return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "ONE ZERO",
          style: TextStyle(
            fontSize: fontSize * 1.2,
            fontFamily: 'Revue',
            color: Colors.red.withOpacity(opacity),
          ),
        ),
        Text(
          " TUITION + ENTRENCE",
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: 'Revue',
            color: Colors.red.withOpacity(opacity),
          ),
        )
      ]);
}

DatabaseHelper dbHelperForConstants = DatabaseHelper();

Future<void> initializeStreamNames(int class_id) async {
  print("initializeStreamNames class_id: $class_id");
  STREAM_NAMES = await dbHelperForConstants.getStreamNames(class_id);
  print(STREAM_NAMES);
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
      "Remove"
    ],
    columnLengths: [
      50,
      200,
      205,
      150,
      100,
      150,
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
List<Map<String, Object>> classDataList = [
  {
    'class_id': 1,
    'class_name': 'Plus Two STATE',
    'academic_year': 'academicYear',
    'section': 'HSS'
  },
  {
    'class_id': 2,
    'class_name': 'Plus Two CBSE',
    'academic_year': 'academicYear',
    'section': 'HSS'
  },
  {
    'class_id': 3,
    'class_name': 'Plus One STATE',
    'academic_year': 'academicYear',
    'section': 'HSS'
  },
  {
    'class_id': 4,
    'class_name': 'Plus One CBSE',
    'academic_year': 'academicYear',
    'section': 'HSS'
  },
  {
    'class_id': 5,
    'class_name': '10th STATE',
    'academic_year': 'academicYear',
    'section': 'HSS'
  },
  {
    'class_id': 6,
    'class_name': '10th CBSE',
    'academic_year': 'academicYear',
    'section': 'HS'
  },
  {
    'class_id': 7,
    'class_name': '9th STATE',
    'academic_year': 'academicYear',
    'section': 'HS'
  },
  {
    'class_id': 8,
    'class_name': '9th CBSE',
    'academic_year': 'academicYear',
    'section': 'HS'
  },
  {
    'class_id': 9,
    'class_name': '8th STATE',
    'academic_year': 'academicYear',
    'section': 'HS'
  },
  {
    'class_id': 10,
    'class_name': '8th CBSE',
    'academic_year': 'academicYear',
    'section': 'HS'
  },
];

List<Map<String, Object>> subjectDataList = [
//plus two state

  {'subject_id': 1, 'subject_name': 'Mathematics', 'class_id': 1},
  {'subject_id': 2, 'subject_name': 'Physics', 'class_id': 1},
  {'subject_id': 3, 'subject_name': 'Chemistry', 'class_id': 1},
  {'subject_id': 4, 'subject_name': 'Botany', 'class_id': 1},
  {'subject_id': 5, 'subject_name': 'Zoology', 'class_id': 1},

// plus two cbse

  {'subject_id': 6, 'subject_name': 'Mathematics', 'class_id': 2},
  {'subject_id': 7, 'subject_name': 'Physics', 'class_id': 2},
  {'subject_id': 8, 'subject_name': 'Chemistry', 'class_id': 2},
  {'subject_id': 9, 'subject_name': 'Botany', 'class_id': 2},
  {'subject_id': 10, 'subject_name': 'Zoology', 'class_id': 2},

// plus one state

  {'subject_id': 11, 'subject_name': 'Mathematics', 'class_id': 3},
  {'subject_id': 12, 'subject_name': 'Physics', 'class_id': 3},
  {'subject_id': 13, 'subject_name': 'Chemistry', 'class_id': 3},
  {'subject_id': 14, 'subject_name': 'Botany', 'class_id': 3},
  {'subject_id': 15, 'subject_name': 'Zoology', 'class_id': 3},

// plus one cbse

  {'subject_id': 16, 'subject_name': 'Mathematics', 'class_id': 4},
  {'subject_id': 17, 'subject_name': 'Physics', 'class_id': 4},
  {'subject_id': 18, 'subject_name': 'Chemistry', 'class_id': 4},
  {'subject_id': 19, 'subject_name': 'Botany', 'class_id': 4},
  {'subject_id': 20, 'subject_name': 'Zoology', 'class_id': 4},

  // // 10th state
  {'subject_id': 21, 'subject_name': 'English', 'class_id': 5},
  {'subject_id': 22, 'subject_name': 'Hindi', 'class_id': 5},
  {'subject_id': 23, 'subject_name': 'Mathematics', 'class_id': 5},
  {'subject_id': 25, 'subject_name': 'Social Science', 'class_id': 5},
  {'subject_id': 26, 'subject_name': 'Physics', 'class_id': 5},
  {'subject_id': 27, 'subject_name': 'Chemistry', 'class_id': 5},
  {'subject_id': 28, 'subject_name': 'Biology', 'class_id': 5},

  // 10th cbse
  {'subject_id': 29, 'subject_name': 'English', 'class_id': 6},
  {'subject_id': 30, 'subject_name': 'Hindi', 'class_id': 6},
  {'subject_id': 31, 'subject_name': 'Mathematics', 'class_id': 6},
  {'subject_id': 32, 'subject_name': 'Social Science', 'class_id': 6},
  {'subject_id': 33, 'subject_name': 'Physics', 'class_id': 6},
  {'subject_id': 34, 'subject_name': 'Chemistry', 'class_id': 6},
  {'subject_id': 35, 'subject_name': 'Biology', 'class_id': 6},

  // 9th state
  {'subject_id': 36, 'subject_name': 'English', 'class_id': 7},
  {'subject_id': 37, 'subject_name': 'Hindi', 'class_id': 7},
  {'subject_id': 38, 'subject_name': 'Mathematics', 'class_id': 7},
  {'subject_id': 39, 'subject_name': 'Social Science', 'class_id': 7},
  {'subject_id': 40, 'subject_name': 'Physics', 'class_id': 7},
  {'subject_id': 41, 'subject_name': 'Chemistry', 'class_id': 7},
  {'subject_id': 42, 'subject_name': 'Biology', 'class_id': 7},
  // 9th cbse
  {'subject_id': 43, 'subject_name': 'English', 'class_id': 8},
  {'subject_id': 44, 'subject_name': 'Hindi', 'class_id': 8},
  {'subject_id': 45, 'subject_name': 'Mathematics', 'class_id': 8},
  {'subject_id': 46, 'subject_name': 'Social Science', 'class_id': 8},
  {'subject_id': 47, 'subject_name': 'Physics', 'class_id': 8},
  {'subject_id': 48, 'subject_name': 'Chemistry', 'class_id': 8},
  {'subject_id': 49, 'subject_name': 'Biology', 'class_id': 8},
  // 8th state
  {'subject_id': 50, 'subject_name': 'English', 'class_id': 9},
  {'subject_id': 51, 'subject_name': 'Hindi', 'class_id': 9},
  {'subject_id': 52, 'subject_name': 'Mathematics', 'class_id': 9},
  {'subject_id': 53, 'subject_name': 'Social Science', 'class_id': 9},
  {'subject_id': 54, 'subject_name': 'Physics', 'class_id': 9},
  {'subject_id': 55, 'subject_name': 'Chemistry', 'class_id': 9},
  {'subject_id': 56, 'subject_name': 'Biology', 'class_id': 9},
  // 8th cbse
  {'subject_id': 57, 'subject_name': 'English', 'class_id': 10},
  {'subject_id': 58, 'subject_name': 'Hindi', 'class_id': 10},
  {'subject_id': 59, 'subject_name': 'Mathematics', 'class_id': 10},
  {'subject_id': 60, 'subject_name': 'Social Science', 'class_id': 10},
  {'subject_id': 61, 'subject_name': 'Physics', 'class_id': 10},
  {'subject_id': 62, 'subject_name': 'Chemistry', 'class_id': 10},
  {'subject_id': 63, 'subject_name': 'Biology', 'class_id': 10},
];

List<Map<String, Object>> streamDataList = [
  //12th
  //state
  {'stream_id': 1, 'stream_name': '12th Bio STATE', 'class_id': 1},
  {'stream_id': 2, 'stream_name': '12th CS STATE', 'class_id': 1},
  //cbse
  {'stream_id': 3, 'stream_name': '12th Bio-Hindi CBSE', 'class_id': 2},
  {'stream_id': 4, 'stream_name': '12th Bio-Math CBSE', 'class_id': 2},
  {'stream_id': 5, 'stream_name': '12th CS CBSE', 'class_id': 2},
  //11th
  //state
  {'stream_id': 6, 'stream_name': '11th Bio STATE', 'class_id': 3},
  {'stream_id': 7, 'stream_name': '11th CS STATE', 'class_id': 3},
  //cbse
  {'stream_id': 8, 'stream_name': '11th Bio-Hindi CBSE', 'class_id': 4},
  {'stream_id': 9, 'stream_name': '11th Bio-Math CBSE', 'class_id': 4},
  {'stream_id': 10, 'stream_name': '11th CS CBSE', 'class_id': 4},
  //10th
  //state
  {'stream_id': 11, 'stream_name': '10th STATE', 'class_id': 5},
  //cbse
  {'stream_id': 12, 'stream_name': '10th CBSE', 'class_id': 6},
  //9th
  //state
  {'stream_id': 13, 'stream_name': '9th STATE', 'class_id': 7},
  //cbse
  {'stream_id': 14, 'stream_name': '9th CBSE', 'class_id': 8},
  //8th
  //state
  {'stream_id': 15, 'stream_name': '8th STATE', 'class_id': 9},
  //cbse
  {'stream_id': 16, 'stream_name': '8th CBSE', 'class_id': 10},
];

List<Map<String, Object>> streamSubjectDataList = [
  // 12th BIO STATE
  {'stream_id': 1, 'subject_id': 1},
  {'stream_id': 1, 'subject_id': 2},
  {'stream_id': 1, 'subject_id': 3},
  {'stream_id': 1, 'subject_id': 4},
  {'stream_id': 1, 'subject_id': 5},

  // 12th CS STATE
  {'stream_id': 2, 'subject_id': 1},
  {'stream_id': 2, 'subject_id': 2},
  {'stream_id': 2, 'subject_id': 3},

  //12th bio-hindi cbse
  {'stream_id': 3, 'subject_id': 7},
  {'stream_id': 3, 'subject_id': 8},
  {'stream_id': 3, 'subject_id': 9},
  {'stream_id': 3, 'subject_id': 10},

  //12th bio-math cbse
  {'stream_id': 4, 'subject_id': 6},
  {'stream_id': 4, 'subject_id': 7},
  {'stream_id': 4, 'subject_id': 8},
  {'stream_id': 4, 'subject_id': 9},
  {'stream_id': 4, 'subject_id': 10},

  //12th cs cbse
  {'stream_id': 5, 'subject_id': 6},
  {'stream_id': 5, 'subject_id': 7},
  {'stream_id': 5, 'subject_id': 8},

  // 11th BIO STATE
  {'stream_id': 6, 'subject_id': 11},
  {'stream_id': 6, 'subject_id': 12},
  {'stream_id': 6, 'subject_id': 13},
  {'stream_id': 6, 'subject_id': 14},
  {'stream_id': 6, 'subject_id': 15},

  // 11th CS STATE
  {'stream_id': 7, 'subject_id': 11},
  {'stream_id': 7, 'subject_id': 12},
  {'stream_id': 7, 'subject_id': 13},

  //11th bio-hindi cbse
  {'stream_id': 8, 'subject_id': 17},
  {'stream_id': 8, 'subject_id': 18},
  {'stream_id': 8, 'subject_id': 19},
  {'stream_id': 8, 'subject_id': 20},

  //11th bio-math cbse
  {'stream_id': 9, 'subject_id': 16},
  {'stream_id': 9, 'subject_id': 17},
  {'stream_id': 9, 'subject_id': 18},
  {'stream_id': 9, 'subject_id': 19},
  {'stream_id': 9, 'subject_id': 20},

  //11th cs cbse
  {'stream_id': 10, 'subject_id': 16},
  {'stream_id': 10, 'subject_id': 17},
  {'stream_id': 10, 'subject_id': 18},

  //10th STATE
  {'stream_id': 11, 'subject_id': 21},
  {'stream_id': 11, 'subject_id': 22},
  {'stream_id': 11, 'subject_id': 23},
  {'stream_id': 11, 'subject_id': 25},
  {'stream_id': 11, 'subject_id': 26},
  {'stream_id': 11, 'subject_id': 27},
  {'stream_id': 11, 'subject_id': 28},

  //10th CBSE
  {'stream_id': 12, 'subject_id': 29},
  {'stream_id': 12, 'subject_id': 30},
  {'stream_id': 12, 'subject_id': 31},
  {'stream_id': 12, 'subject_id': 32},
  {'stream_id': 12, 'subject_id': 33},
  {'stream_id': 12, 'subject_id': 34},
  {'stream_id': 12, 'subject_id': 35},

  //9th STATE
  {'stream_id': 13, 'subject_id': 36},
  {'stream_id': 13, 'subject_id': 37},
  {'stream_id': 13, 'subject_id': 38},
  {'stream_id': 13, 'subject_id': 39},
  {'stream_id': 13, 'subject_id': 40},
  {'stream_id': 13, 'subject_id': 41},
  {'stream_id': 13, 'subject_id': 42},

  //9th CBSE
  {'stream_id': 14, 'subject_id': 43},
  {'stream_id': 14, 'subject_id': 44},
  {'stream_id': 14, 'subject_id': 45},
  {'stream_id': 14, 'subject_id': 46},
  {'stream_id': 14, 'subject_id': 47},
  {'stream_id': 14, 'subject_id': 48},
  {'stream_id': 14, 'subject_id': 49},

  //8th STATE
  {'stream_id': 15, 'subject_id': 50},
  {'stream_id': 15, 'subject_id': 51},
  {'stream_id': 15, 'subject_id': 52},
  {'stream_id': 15, 'subject_id': 53},
  {'stream_id': 15, 'subject_id': 54},
  {'stream_id': 15, 'subject_id': 55},
  {'stream_id': 15, 'subject_id': 56},

  //8th CBSE
  {'stream_id': 16, 'subject_id': 57},
  {'stream_id': 16, 'subject_id': 58},
  {'stream_id': 16, 'subject_id': 59},
  {'stream_id': 16, 'subject_id': 60},
  {'stream_id': 16, 'subject_id': 61},
  {'stream_id': 16, 'subject_id': 62},
  {'stream_id': 16, 'subject_id': 63},
];

String createQuery = '''
  CREATE TABLE IF NOT EXISTS class_table (
  id INTEGER AUTO_INCREMENT PRIMARY KEY ,           
  class_name VARCHAR(32) NOT NULL,              
  academic_year VARCHAR(32) NOT NULL,
  section VARCHAR(32) NOT NULL         
);

  CREATE TABLE IF NOT EXISTS stream_table (
  id INTEGER AUTO_INCREMENT PRIMARY KEY , 
  stream_name VARCHAR(32) NOT NULL,  
  class_id INTEGER,                          
  FOREIGN KEY (class_id) REFERENCES class_table(id) ON DELETE CASCADE
);

  CREATE TABLE IF NOT EXISTS subject_table (
  id INTEGER AUTO_INCREMENT PRIMARY KEY ,   
  subject_name VARCHAR(32) NOT NULL,            
  class_id INTEGER,
  FOREIGN KEY (class_id) REFERENCES class_table(id) ON DELETE CASCADE
);

  CREATE TABLE IF NOT EXISTS stream_subjects_table (
  id INTEGER AUTO_INCREMENT PRIMARY KEY ,   
  stream_id INTEGER,
  subject_id INTEGER,
  FOREIGN KEY (stream_id) REFERENCES stream_table(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subject_table(id) ON DELETE CASCADE
);

  CREATE TABLE IF NOT EXISTS student_table (
  id INTEGER PRIMARY KEY ,  
  student_name VARCHAR(32) NOT NULL,
  photo_id VARCHAR(32),
  parent_phone VARCHAR(32),
  gender VARCHAR(32),
  school_name VARCHAR(32),
  stream_id INTEGER NOT NULL,
  FOREIGN KEY (stream_id) REFERENCES stream_table(id) ON DELETE CASCADE
);

  CREATE TABLE IF NOT EXISTS test_table (
  id INTEGER PRIMARY KEY ,   
  subject_id INTEGER,
  topic VARCHAR(32),
  max_mark INTEGER,
  test_date DATETIME NOT NULL,
  FOREIGN KEY (subject_id) REFERENCES subject_table(id) ON DELETE CASCADE
);

  CREATE TABLE IF NOT EXISTS test_score_table (
  id INTEGER PRIMARY KEY AUTO_INCREMENT,   
  score INTEGER,
  student_id INTEGER,
  test_id INTEGER,
  FOREIGN KEY (student_id) REFERENCES student_table(id) ON DELETE CASCADE,
  FOREIGN KEY (test_id) REFERENCES test_table(id) ON DELETE CASCADE
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
