// import 'package:sqflite/sqflite.dart';
import 'dart:ffi';

import 'package:one_zero/constants.dart';
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
    await db.execute(cretateQuery);
    // await db.execute(insertQuery);
  }

  Future<int> insertToTable(
      String tableName, Map<String, dynamic> values) async {
    final db = await database;
    try {
      return await db.insert(tableName, values);
    } catch (e) {
      print("Error occurred while inserting data: $e");
      return 0;
    }
  }

  Future<List<String>> getStreamNames() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> result = await db.query('stream_table');
      List<String> ss = result.map((e) => e['stream_name'] as String).toList();

      print(ss);
      return ss;
    } catch (e) {
      print("Error occurred while fetching stream names: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getClasses(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  // Assuming you already have an instance of your database (db)
  Future<void> insertTest(Map<String, dynamic> newTest) async {
    // Step 1: Fetch the subject_id using the subject_name
    final db = await database;
    final List<Map<String, dynamic>> subjectList = await db.query(
      'subject_table',
      columns: ['id'],
      where: 'subject_name = ?',
      whereArgs: [newTest['subject_name']],
    );

    if (subjectList.isNotEmpty) {
      final int subjectId = subjectList.first['id'];

      // Step 2: Prepare the data for insertion into the test_table
      Map<String, dynamic> test = {
        'id': newTest['test_id'],
        'subject_id': subjectId,
        'topic': newTest['topic'],
        'max_mark': int.parse(newTest['maxMark']),
        'test_date': newTest['date'],
      };

      // Step 3: Insert the data into the test_table
      await db.insert('test_table', test);

      print('Test data inserted successfully');
    } else {
      print('Subject not found');
    }
  }

  Future<Map<String, dynamic>> addNewTest(Map<String, dynamic> newTest) async {
    final db = await database;
    Map<String, dynamic> test = {
      'subject_id': newTest['subject_id'],
      'topic': newTest['topic'],
      'max_mark': newTest['max_mark'],
      'test_date': newTest['test_date']
    };
    return test;
  }

  Future<List<Map<String, dynamic>>> getStudentIdsAndNamesByTestId(
      int testId) async {
    print("test id in getStudentIdsAndNamesByTestId function $testId");
    final db = await database;

    // Get the subject_id from the test_id
    final List<Map<String, dynamic>> subjectIdResult = await db.rawQuery('''
      SELECT subject_id FROM test_table WHERE id = ?
    ''', [testId]);

    if (subjectIdResult.isEmpty) return [];

    final subjectId = subjectIdResult.first['subject_id'];
    print("subject id in getStudentIdsAndNamesByTestId function $subjectId");

    // Get students related to that subject
    final List<Map<String, dynamic>> studentResult = await db.rawQuery('''
      SELECT DISTINCT s.id AS student_id, s.student_name
      FROM student_table s
      INNER JOIN stream_subjects_table ss ON s.stream_id = ss.stream_id
      WHERE ss.subject_id = ?
    ''', [subjectId]);
    print(
        "students list result in getStudentIdsAndNamesByTestId function $studentResult");
    return studentResult;
  }

  Future<int?> getStudentId(String studentName) async {
    final db = await database;

    // Check if studentName is null or empty
    if (studentName.isEmpty) {
      throw ArgumentError("Student name cannot be empty");
    }

    String query = '''
    SELECT id FROM student_table WHERE   LOWER(student_name) = LOWER(?);;
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

  Future<List<String>?> getClassSubjects(String className) async {
    final db = await database;
    String query = '''
    SELECT 
      sub.subject_name,
      c.id AS class_id
    FROM 
      subject_table sub
    JOIN 
      stream_subjects_table ss ON sub.id = ss.subject_id
    JOIN 
      stream_table st ON ss.stream_id = st.id
    JOIN 
      class_table c ON st.class_id = c.id
    WHERE 
     LOWER(c.class_name) = LOWER('?');
  ''';

    try {
      // Execute the query and get the result
      List<Map<String, dynamic>> result = await db.rawQuery(query, [className]);

      // Check if the result is empty and return null if no subjects are found
      if (result.isEmpty) {
        print("No subjects found for class: $className");
        return null;
      }

      // Return the list of subjects
      List<String> subjects =
          result.map((e) => e['subject_name'] as String).toList();
      return subjects;
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred while fetching subjects: $e");
      throw Exception("Failed to retrieve subjects. Please try again later.");
    }
  }

// fetch students of a subject
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
        'SELECT id FROM student_table WHERE LOWER(student_name) = LOWER(?);',
        [studentName]);

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
    print("getmaxid function $result");
    // Check if the result is not empty and contains the 'max_id' key
    if (result.isNotEmpty && result[0]['max_id'] != null) {
      // Return the maximum ID as an integer
      print("max id fetch sucessfull for $tableName ");
      return result[0]['max_id'] as int;
    } else {
      int maxId = 0;

      if (tableName == 'class_table') {
        maxId = 1000;
      } else if (tableName == 'subject_table') {
        maxId = 2000;
      } else if (tableName == 'stream_table') {
        maxId = 3000;
      } else if (tableName == 'student_table') {
        maxId = 4000;
      } else if (tableName == 'test_table') {
        maxId = 5000;
      } else if (tableName == 'test_score_table') {
        maxId = 6000;
      } else if (tableName == 'stream_subjects_table') {
        maxId = 7000;
      } else {
        maxId = 0;
      }
      print("max id fetch failed for $tableName \n returning $maxId");
      return maxId;
    }
  }

  Future<int> getSubjectId(String subjectName) async {
    final db = await database;

    // Ensure that subjectName is not null or empty
    if (subjectName.isEmpty) {
      throw ArgumentError("Subject name cannot be empty");
    }

    // Query to get the subject ID
    String query = '''
    SELECT id FROM subject_table WHERE subject_name = ?;
  ''';

    try {
      // Execute the query and get the result
      List<Map<String, dynamic>> result =
          await db.rawQuery(query, [subjectName]);

      // Check if the result is empty and return null if no subject is found
      if (result.isEmpty) {
        return 0; // Return 0 if no subject is found
      }

      // Return the subject ID
      return result[0]['id'] as int;
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred while fetching subject ID: $e");
      throw Exception("Failed to retrieve subject ID. Please try again later.");
    }
  }

  Future<int> getStreamId(String streamName) async {
    final db = await database;

    // Ensure that streamName is not null or empty
    if (streamName.isEmpty) {
      throw ArgumentError("Stream name cannot be empty");
    }

    // Query to get the stream ID
    String query = '''
    SELECT id FROM stream_table WHERE stream_name = ?;
  ''';

    try {
      // Execute the query and get the result
      List<Map<String, dynamic>> result =
          await db.rawQuery(query, [streamName]);

      // Check if the result is empty and return null if no stream is found
      if (result.isEmpty) {
        return 0; // Return 0 if no stream is found
      }

      // Return the stream ID
      return result[0]['id'] as int;
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred while fetching stream ID: $e");
      throw Exception("Failed to retrieve stream ID. Please try again later.");
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
