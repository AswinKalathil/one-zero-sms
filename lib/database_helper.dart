// import 'package:sqflite/sqflite.dart';
import 'dart:ffi';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'one_zero_sqlite_db_file.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    
CREATE TABLE class_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,           
  class_name TEXT NOT NULL,              
  academic_year TEXT NOT NULL             
);

CREATE TABLE stream_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,   
  class_id TEXT,                          
  FOREIGN KEY (class_id) REFERENCES class_table(id)
);

CREATE TABLE subject_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,   
  subject_name TEXT NOT NULL,            
  class_id TEXT,
  FOREIGN KEY (class_id) REFERENCES class_table(id)
);

CREATE TABLE stream_subjects_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,   
  stream_id INTEGER,
  subject_id INTEGER,
  FOREIGN KEY (stream_id) REFERENCES stream_table(id),
  FOREIGN KEY (subject_id) REFERENCES subject_table(id)
);

CREATE TABLE student_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,  
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
  id INTEGER PRIMARY KEY AUTOINCREMENT,   
  subject_id INTEGER,
  topic TEXT,
  max_mark INTEGER,
  test_date DATETIME NOT NULL,
  FOREIGN KEY (subject_id) REFERENCES subject_table(id)
);

CREATE TABLE test_score_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,   
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

-- Insert into class_table
INSERT INTO class_table (id, class_name, academic_year)
VALUES (1000, 'Class A', '2024-2025');

-- Insert into stream_table
INSERT INTO stream_table (id, class_id)
VALUES (2000, 1000);

-- Insert into subject_table
INSERT INTO subject_table (id, subject_name, class_id)
VALUES (3000, 'Mathematics', 1000);

-- Insert into stream_subjects_table
INSERT INTO stream_subjects_table (id, stream_id, subject_id)
VALUES (4000, 2000, 3000);

-- Insert into student_table
INSERT INTO student_table (id, student_name, photo_id, student_phone, parent_name, parent_phone, school_name, stream_id)
VALUES (5000, 'John Doe', 'photo_1.png', '1234567890', 'Jane Doe', '0987654321', 'Sample School', 2000);

-- Insert into test_table
INSERT INTO test_table (id, subject_id, max_mark, test_date)
VALUES (6000, 3000, 100, '2024-09-01');

-- Insert into test_score_table
INSERT INTO test_score_table (id, score, student_id, test_id)
VALUES (7000, 85, 5000, 6000);

    ''');
  }

  Future<int> insertToTable(
      String tableName, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(tableName, values);
  }

  Future<List<Map<String, dynamic>>> getClasses(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<int?> getStudentId(String studentName) async {
    final db = await database;

    // Check if studentName is null or empty
    if (studentName.isEmpty) {
      throw ArgumentError("Student name cannot be empty");
    }

    String query = '''
    SELECT id FROM student_table WHERE student_name = ?;
  ''';

    try {
      // Execute the query and get the result
      List<Map<String, dynamic>> result =
          await db.rawQuery(query, [studentName]);

      // Check if the result is empty and return null if no student is found
      if (result.isEmpty) {
        return null;
      }

      // Return the student ID
      return result[0]['id'] as int?;
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred while fetching student ID: $e");
      throw Exception("Failed to retrieve student ID. Please try again later.");
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsOfSubject(
      String subjectName) async {
    final db = await database;

    try {
      print("Subject Name: $subjectName");

      // Query to get the subject ID
      final queryResults = await db.rawQuery(
          'SELECT id FROM subject_table WHERE subject_name = ?;',
          [subjectName]);

      // Check if the query returned any results
      if (queryResults.isEmpty) {
        print("No subject found with name: $subjectName");
        return []; // Return an empty list if no subject is found
      }

      // Get the subject ID from the result
      int subjectId = queryResults[0]['id'] as int;
      print("Subject ID: $subjectId");

      // Query to get students of the subject
      String query = '''
      SELECT DISTINCT 
        s.id, 
        s.student_name, 
        s.photo_id
      FROM 
        student_table s
      JOIN 
        stream_table st ON s.stream_id = st.id
      JOIN 
        stream_subjects_table ss ON st.id = ss.stream_id
      JOIN 
        subject_table sub ON ss.subject_id = sub.id
      WHERE 
        sub.id = ?;
    ''';

      final result = await db.rawQuery(query, [subjectId]);
      return result;
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred: $e");
      return []; // Return an empty list or handle the error as needed
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsOfClass(
      String className) async {
    print("Class Name: $className");
    final db = await database;

    // Query to get the class ID
    final queryResults = await db.rawQuery(
        'SELECT id FROM class_table WHERE class_name = ?;', [className]);

    // Check if the query returned any results
    if (queryResults.isEmpty) {
      print("No class found with name: $className !");
      return []; // Return an empty list if no class is found
    }

    // Get the class ID from the result
    int classId = queryResults[0]['id'] as int;
    print("Class ID: $classId");

    // Query to get students of the class
    String query = '''
    SELECT 
      s.id,
      s.student_name,
      s.photo_id
    FROM 
      student_table s
    INNER JOIN 
      stream_table st ON s.stream_id = st.id
    INNER JOIN 
      class_table c ON st.class_id = c.id
    WHERE 
      c.id = ?;
  ''';

    // Execute the query
    final result = await db.rawQuery(query, [classId]);
    print("Result: $result");

    return result;
  }

  Future<List<Map<String, dynamic>>> getGradeCard(String studentName) async {
    final db = await database;
    print("student id for grade card $studentName");
    // Check if studentId is correctly passed and is not empty
    if (studentName.isEmpty) {
      throw ArgumentError("Student Name cannot be empty");
    }
    final queryResults = await db.rawQuery(
        'SELECT id FROM student_table WHERE student_name = ?;', [studentName]);

    // Check if the query returned any results
    if (queryResults.isEmpty) {
      print("No student Name found with name: $studentName !");
      return []; // Return an empty list if no class is found
    }

    // Get the class ID from the result
    int studentId = queryResults[0]['id'] as int;
    print("Class ID: $studentId");

    String query = '''
    SELECT 
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
    LEFT JOIN subject_table sub ON t.subject_id = sub.id
    WHERE s.id = ?;
  ''';

    try {
      // Execute the query and get the result
      List<Map<String, dynamic>> result = await db.rawQuery(query, [studentId]);

      // Check if the result is empty
      if (result.isEmpty) {
        throw ArgumentError("No student found with the given ID");
      }

      return result;
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred while fetching grade card: $e");
      throw Exception(
          "Failed to retrieve grade card data. Please try again later.");
    }
  }

  // Future<int> getMaxId(String tableName) async {
  //   final db = await database;
  //   String query = '''SELECT MAX(id) FROM ?;''';
  //   List<Map<String, dynamic>> result = await db.rawQuery(query, [tableName]);
  //   print("Result: $result");
  //   return result[0]['id'] as int;
  // }
  Future<int> getMaxId(String tableName) async {
    final db = await database;

    // Ensure that tableName is a valid identifier to prevent SQL injection.
    // Alternatively, validate and sanitize the table name before using it.

    // Correct query with direct table name insertion.
    String query = 'SELECT MAX(id) AS max_id FROM $tableName;';

    // Execute the query
    List<Map<String, dynamic>> result = await db.rawQuery(query);
    print(result);
    // Check if the result is not empty and contains the 'max_id' key
    if (result.isNotEmpty && result[0]['max_id'] != null) {
      // Return the maximum ID as an integer
      return result[0]['max_id'] as int;
    } else {
      // Return 0 or handle cases where no result is found
      return 0; // or throw an exception based on your use case
    }
  }

  // Example CRUD operations
//   Future<int> insertStudent(Map<String, dynamic> student) async {
//     final db = await database;
//     return await db.insert('students', student);
//   }

//   Future<List<Map<String, dynamic>>> getStudents() async {
//     final db = await database;
//     return await db.query('students');
//   }

//   Future<int> updateStudent(int id, Map<String, dynamic> student) async {
//     final db = await database;
//     return await db
//         .update('students', student, where: 'id = ?', whereArgs: [id]);
//   }

//   Future<int> deleteStudent(int id) async {
//     final db = await database;
//     return await db.delete('students', where: 'id = ?', whereArgs: [id]);
//   }
}
