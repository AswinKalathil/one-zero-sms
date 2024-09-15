import 'package:flutter/material.dart';

import 'package:one_zero/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final List<Color> cardBackgroundColors = [
  Color.fromARGB(255, 176, 213, 226), // Light Blue
  Color.fromARGB(255, 50, 172, 113), // Light Green
  Color.fromARGB(255, 255, 222, 137), // Light Yellow
  Color(0xFFF08080), // Light Coral
  Color.fromARGB(255, 194, 194, 231), // Light Lavender
  Color(0xFFFFDAB9), // Light Peach
];

DatabaseHelper dbHelper = DatabaseHelper();
Future<List<String>> getStreamNames() async {
  return await dbHelper.getStreamNames();
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
      "Student Phone",
      "Parent Name",
      "Parent Phone",
      "Photo Path",
      "Actions"
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
  student_phone TEXT,
  parent_name TEXT,
  parent_phone TEXT,
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
String insertQuery = '''


-- Insert 5 classes starting from class_id 1000
INSERT INTO class_table (id, class_name, academic_year) VALUES 
(1000, 'Class A', '2023-2024'),
(1001, 'Class B', '2023-2024'),
(1002, 'Class C', '2023-2024'),
(1003, 'Class D', '2023-2024'),
(1004, 'Class E', '2023-2024');

-- Insert 5 subjects for each class (subject_id starting from 2000)
INSERT INTO subject_table (id, subject_name, class_id) VALUES
(2000, 'Math', 1000),
(2001, 'Science', 1000),
(2002, 'History', 1000),
(2003, 'English', 1000),
(2004, 'Art', 1000),

(2005, 'Math', 1001),
(2006, 'Science', 1001),
(2007, 'History', 1001),
(2008, 'English', 1001),
(2009, 'Art', 1001),

(2010, 'Math', 1002),
(2011, 'Science', 1002),
(2012, 'History', 1002),
(2013, 'English', 1002),
(2014, 'Art', 1002),

(2015, 'Math', 1003),
(2016, 'Science', 1003),
(2017, 'History', 1003),
(2018, 'English', 1003),
(2019, 'Art', 1003),

(2020, 'Math', 1004),
(2021, 'Science', 1004),
(2022, 'History', 1004),
(2023, 'English', 1004),
(2024, 'Art', 1004);

-- Insert 10 students for each class (student_id starting from 3000)
INSERT INTO student_table (id, student_name, photo_id, student_phone, parent_name, parent_phone, school_name, stream_id) VALUES
(3000, 'John Doe', 'photo_3000', '1234567890', 'Parent Doe', '0987654321', 'School A', 1000),
(3001, 'Jane Smith', 'photo_3001', '1234567891', 'Parent Smith', '0987654322', 'School A', 1000),
(3002, 'Alice Johnson', 'photo_3002', '1234567892', 'Parent Johnson', '0987654323', 'School A', 1000),
(3003, 'Bob Brown', 'photo_3003', '1234567893', 'Parent Brown', '0987654324', 'School A', 1000),
(3004, 'Charlie Wilson', 'photo_3004', '1234567894', 'Parent Wilson', '0987654325', 'School A', 1000),
(3005, 'David Davis', 'photo_3005', '1234567895', 'Parent Davis', '0987654326', 'School A', 1000),
(3006, 'Eve Evans', 'photo_3006', '1234567896', 'Parent Evans', '0987654327', 'School A', 1000),
(3007, 'Frank Garcia', 'photo_3007', '1234567897', 'Parent Garcia', '0987654328', 'School A', 1000),
(3008, 'Grace Harris', 'photo_3008', '1234567898', 'Parent Harris', '0987654329', 'School A', 1000),
(3009, 'Henry King', 'photo_3009', '1234567899', 'Parent King', '0987654330', 'School A', 1000),

(3010, 'Liam Lee', 'photo_3010', '2234567890', 'Parent Lee', '1987654321', 'School B', 1001),
(3011, 'Mia Moore', 'photo_3011', '2234567891', 'Parent Moore', '1987654322', 'School B', 1001),
(3012, 'Noah Taylor', 'photo_3012', '2234567892', 'Parent Taylor', '1987654323', 'School B', 1001),
(3013, 'Olivia Jackson', 'photo_3013', '2234567893', 'Parent Jackson', '1987654324', 'School B', 1001),
(3014, 'Sophia White', 'photo_3014', '2234567894', 'Parent White', '1987654325', 'School B', 1001),
(3015, 'James Thomas', 'photo_3015', '2234567895', 'Parent Thomas', '1987654326', 'School B', 1001),
(3016, 'Lucas Martin', 'photo_3016', '2234567896', 'Parent Martin', '1987654327', 'School B', 1001),
(3017, 'Mason Thompson', 'photo_3017', '2234567897', 'Parent Thompson', '1987654328', 'School B', 1001),
(3018, 'Ethan Martinez', 'photo_3018', '2234567898', 'Parent Martinez', '1987654329', 'School B', 1001),
(3019, 'Ava Anderson', 'photo_3019', '2234567899', 'Parent Anderson', '1987654330', 'School B', 1001),

-- Insert 10 students for Class C (student_id starting from 3020)
INSERT INTO student_table (id, student_name, photo_id, student_phone, parent_name, parent_phone, school_name, stream_id) VALUES
(3020, 'Lily Cooper', 'photo_3020', '3234567890', 'Parent Cooper', '2987654321', 'School C', 1002),
(3021, 'Jack Bell', 'photo_3021', '3234567891', 'Parent Bell', '2987654322', 'School C', 1002),
(3022, 'Zoe Murphy', 'photo_3022', '3234567892', 'Parent Murphy', '2987654323', 'School C', 1002),
(3023, 'Eli Sanders', 'photo_3023', '3234567893', 'Parent Sanders', '2987654324', 'School C', 1002),
(3024, 'Emma Rogers', 'photo_3024', '3234567894', 'Parent Rogers', '2987654325', 'School C', 1002),
(3025, 'Owen Reed', 'photo_3025', '3234567895', 'Parent Reed', '2987654326', 'School C', 1002),
(3026, 'Leah Brooks', 'photo_3026', '3234567896', 'Parent Brooks', '2987654327', 'School C', 1002),
(3027, 'Nina Scott', 'photo_3027', '3234567897', 'Parent Scott', '2987654328', 'School C', 1002),
(3028, 'Ella Ward', 'photo_3028', '3234567898', 'Parent Ward', '2987654329', 'School C', 1002),
(3029, 'Max Adams', 'photo_3029', '3234567899', 'Parent Adams', '2987654330', 'School C', 1002);

-- Insert 10 students for Class D (student_id starting from 3030)
INSERT INTO student_table (id, student_name, photo_id, student_phone, parent_name, parent_phone, school_name, stream_id) VALUES
(3030, 'Ryan Hughes', 'photo_3030', '4234567890', 'Parent Hughes', '3987654321', 'School D', 1003),
(3031, 'Maya Green', 'photo_3031', '4234567891', 'Parent Green', '3987654322', 'School D', 1003),
(3032, 'Isla Baker', 'photo_3032', '4234567892', 'Parent Baker', '3987654323', 'School D', 1003),
(3033, 'Theo Price', 'photo_3033', '4234567893', 'Parent Price', '3987654324', 'School D', 1003),
(3034, 'Aria Collins', 'photo_3034', '4234567894', 'Parent Collins', '3987654325', 'School D', 1003),
(3035, 'Logan Russell', 'photo_3035', '4234567895', 'Parent Russell', '3987654326', 'School D', 1003),
(3036, 'Chloe Bryant', 'photo_3036', '4234567896', 'Parent Bryant', '3987654327', 'School D', 1003),
(3037, 'Luca Hayes', 'photo_3037', '4234567897', 'Parent Hayes', '3987654328', 'School D', 1003),
(3038, 'Ruby Gray', 'photo_3038', '4234567898', 'Parent Gray', '3987654329', 'School D', 1003),
(3039, 'Ollie Perry', 'photo_3039', '4234567899', 'Parent Perry', '3987654330', 'School D', 1003);

-- Insert 10 students for Class E (student_id starting from 3040)
INSERT INTO student_table (id, student_name, photo_id, student_phone, parent_name, parent_phone, school_name, stream_id) VALUES
(3040, 'Sophie Foster', 'photo_3040', '5234567890', 'Parent Foster', '4987654321', 'School E', 1004),
(3041, 'Jacob Watson', 'photo_3041', '5234567891', 'Parent Watson', '4987654322', 'School E', 1004),
(3042, 'Eva Peterson', 'photo_3042', '5234567892', 'Parent Peterson', '4987654323', 'School E', 1004),
(3043, 'Elijah Cook', 'photo_3043', '5234567893', 'Parent Cook', '4987654324', 'School E', 1004),
(3044, 'Hazel Bennett', 'photo_3044', '5234567894', 'Parent Bennett', '4987654325', 'School E', 1004),
(3045, 'Owen Reed', 'photo_3045', '5234567895', 'Parent Reed', '4987654326', 'School E', 1004),
(3046, 'Scarlett Phillips', 'photo_3046', '5234567896', 'Parent Phillips', '4987654327', 'School E', 1004),
(3047, 'Mason Powell', 'photo_3047', '5234567897', 'Parent Powell', '4987654328', 'School E', 1004),
(3048, 'Luna Howard', 'photo_3048', '5234567898', 'Parent Howard', '4987654329', 'School E', 1004),
(3049, 'James Barnes', 'photo_3049', '5234567899', 'Parent Barnes', '4987654330', 'School E', 1004);
''';
