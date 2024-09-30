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

  String _acadamicYear = DateTime.now().year.toString() +
      "-" +
      (DateTime.now().year + 1).toString().substring(2);

  void setAcadamicYear(String acadamicYear) {
    _acadamicYear = acadamicYear;
    print(" new Acadamic year private: $_acadamicYear");
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(cretateQuery);
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

  Future<List<String>> getAcadamicYears() async {
    final db = await database;
    try {
      String query = '''SELECT DISTINCT academic_year FROM class_table;''';
      final List<Map<String, dynamic>> result = await db.rawQuery(query);
      List<String> ss =
          result.map((e) => e['academic_year'] as String).toList();

      print(ss);
      return ss;
    } catch (e) {
      print("Error occurred while fetching stream names: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getTestDetails(int testId) async {
    final db = await database;
    try {
      String query =
          '''  Select s.subject_name,tt.test_date,tt.topic,tt.max_mark from test_table tt JOIN subject_table s ON tt.subject_id = s.id  where tt.id = ?''';
      final List<Map<String, dynamic>> result =
          await db.rawQuery(query, [testId]);
      return result[0];
    } catch (e) {
      print("Error occurred while fetching test details: $e");
      return {};
    }
  }

  Future<List<String>> getStreamNames(String section) async {
    // print("Acadamic year private: $_acadamicYear");
    final db = await database;
    try {
      String query =
          '''SELECT stream_name FROM stream_table st JOIN class_table c ON st.class_id = c.id WHERE  c.section = ? AND c.academic_year = ?;''';
      final List<Map<String, dynamic>> result =
          await db.rawQuery(query, [section, _acadamicYear]);
      List<String> ss = result.map((e) => e['stream_name'] as String).toList();

      return ss;
    } catch (e) {
      print("Error occurred while fetching stream names: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getClasses(String tableName) async {
    final db = await database;

    return await db.query(tableName,
        where: 'academic_year = ?', whereArgs: [_acadamicYear]);
  }

  // Assuming you already have an instance of your database (db)
  // Future<void> insertTest1(Map<String, dynamic> newTest) async {
  //   // Step 1: Fetch the subject_id using the subject_name
  //   final db = await database;
  //   final List<Map<String, dynamic>> subjectList = await db.query(
  //     'subject_table',
  //     columns: ['id'],
  //     where: 'subject_name = ?',
  //     whereArgs: [newTest['subject_name']],
  //   );

  //   if (subjectList.isNotEmpty) {
  //     final int subjectId = subjectList.first['id'];

  //     // Step 2: Prepare the data for insertion into the test_table
  //     Map<String, dynamic> test = {
  //       'id': newTest['test_id'],
  //       'subject_id': subjectId,
  //       'topic': newTest['topic'],
  //       'max_mark': int.parse(newTest['maxMark']),
  //       'test_date': newTest['date'],
  //     };

  //     // Step 3: Insert the data into the test_table
  //     await db.insert('test_table', test);

  //     print('Test data inserted successfully');
  //   } else {
  //     print('Subject not found');
  //   }
  // }

  Future<List<Map<String, dynamic>>> getStudentIdsAndNamesByTestId(
      int testId) async {
    // print("test id in getStudentIdsAndNamesByTestId function $testId");
    final db = await database;

    // Get the subject_id from the test_id
    final List<Map<String, dynamic>> subjectIdResult = await db.rawQuery('''
      SELECT subject_id FROM test_table WHERE id = ?
    ''', [testId]);

    if (subjectIdResult.isEmpty) return [];

    final subjectId = subjectIdResult.first['subject_id'];
    // print("subject id in getStudentIdsAndNamesByTestId function $subjectId");

    // Get students related to that subject
    final List<Map<String, dynamic>> studentResult = await db.rawQuery('''
      SELECT DISTINCT s.id AS student_id, s.student_name
      FROM student_table s
      INNER JOIN stream_subjects_table ss ON s.stream_id = ss.stream_id
      WHERE ss.subject_id = ?
    ''', [subjectId]);
    // print(
    //     "students list result in getStudentIdsAndNamesByTestId function $studentResult");
    return studentResult;
  }

  Future<List<Map<String, dynamic>>> getTestDataSheetForUpdate(
      int testId) async {
    // print("test id in getStudentIdsAndNamesByTestId function $testId");
    final db = await database;

    // Get the subject_id from the test_id
    final List<Map<String, dynamic>> testDataSheet = await db.rawQuery('''
      SELECT s.student_name, 
       ts.student_id, 
       ts.test_id, 
       ts.id AS test_score_id, 
       ts.score
FROM (SELECT student_id, test_id, id, score 
      FROM test_score_table 
      WHERE test_id = ?) ts
JOIN (SELECT id, student_name 
      FROM student_table) s 
  ON ts.student_id = s.id;

    ''', [testId]);

    print(testDataSheet);
    return testDataSheet;
  }

  Future<int> updateTestScore(int id, Map<String, dynamic> testScore) async {
    final db = await database;
    return await db.update('test_score_table', testScore,
        where: 'id = ?', whereArgs: [id]);
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
      Distinct sub.id as subject_id,sub.subject_name,
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
     LOWER(c.class_name) = LOWER(?) AND c.academic_year = ?;
  ''';

    try {
      // Execute the query and get the result
      List<Map<String, dynamic>> result =
          await db.rawQuery(query, [className, _acadamicYear]);

      // Check if the result is empty and return null if no subjects are found
      if (result.isEmpty) {
        print("No subjects found for class: $className");
        return [];
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

// fetch students of a subject---------------------------need check
  Future<List<Map<String, dynamic>>> getStudentsOfSubject(
      String subjectName) async {
    final db = await database;

    try {
      print("Subject Name: $subjectName");

      // Query to get the subject ID
      final queryResults = await db.rawQuery(
          'SELECT id FROM subject_table WHERE LOWER(subject_name) = (?);',
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
        s.gender,
        s.photo_id,
        st.stream_name
      FROM 
        student_table s
      JOIN 
        stream_table st ON s.stream_id = st.id
      JOIN 
        stream_subjects_table ss ON st.id = ss.stream_id
      JOIN 
        subject_table sub ON ss.subject_id = sub.id
      WHERE 
        sub.id =?;
    ''';

      final result = await db.rawQuery(query, [subjectId]);
      return result;
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred: $e");
      return []; // Return an empty list or handle the error as needed
    }
  }

  Future<List<Map<String, dynamic>>> getSubjectsOfStudentID(
      int studentId) async {
    try {
      final db = await database;

      String query = '''
      SELECT 
        sub.id as subject_id, 
        sub.subject_name 
      FROM 
        stream_subjects_table ss
      JOIN 
        subject_table sub ON ss.subject_id = sub.id
      WHERE 
        ss.stream_id = (SELECT stream_id FROM student_table WHERE id = ?);
    ''';

      final result = await db.rawQuery(query, [studentId]);
      return result;
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred: $e");
      return []; // Return an empty list or handle the error as needed
    }
  }

  Future<List<Map<String, dynamic>>> getTestHistoryForSubjectOfStudentID(
      int studentId, int subjectId) async {
    final db = await database;

    String query = '''
    SELECT 
      t.id AS test_id, 
      t.topic, 
      t.max_mark, 
      t.test_date, 
      COALESCE(ts.score, '-') AS score
    FROM 
      test_table t
    LEFT JOIN 
      test_score_table ts ON t.id = ts.test_id AND ts.student_id = ?
    WHERE 
      t.subject_id = ?

    ORDER BY t.test_date ASC;
  ''';

    final result = await db.rawQuery(query, [studentId, subjectId]);

    // print(
    // "Test history for student ID: $studentId and subject ID: $subjectId:--->   $result");

    return result;
  }

  Future<List<Map<String, dynamic>>> getStudentsOfName(
      String studentName) async {
    final db = await database;

    try {
      print("Student Name: $studentName");

      // Query to get the student ID
      final queryResults = await db.rawQuery(''' SELECT 
      s.id,
      s.student_name,
      s.gender,
      s.photo_id,
      st.stream_name
    FROM 
      student_table s
    INNER JOIN 
      stream_table st ON s.stream_id = st.id
    INNER JOIN 
      class_table c ON st.class_id = c.id
    WHERE 
       LOWER(s.student_name) LIKE LOWER(?) AND c.academic_year = ?
    ORDER BY 
    CASE 
      WHEN  LOWER(s.student_name) LIKE LOWER(?) THEN 1  
    ELSE 2                      
    END, 
    s.student_name;   
       
       ''', ['%$studentName%', _acadamicYear, '$studentName%']);

      // Check if the query returned any results
      if (queryResults.isEmpty) {
        print("No student found with name: $studentName");
        return []; // Return an empty list if no student is found
      }

      return queryResults;
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred: $e");
      return []; // Return an empty list or handle the error as needed
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsOfClass(
      String className) async {
    print("Class Name: $className acadamic year: $_acadamicYear");
    final db = await database;

    // Query to get the class ID
    final queryResults = await db.rawQuery(
        'SELECT id FROM class_table WHERE LOWER(class_name) = LOWER(?) AND academic_year = ?  ;',
        [className, _acadamicYear]);

    // Check if the query returned any results
    if (queryResults.isEmpty) {
      print("No class found with name: $className!");
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
      s.gender,

      s.photo_id,
      st.stream_name
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

    return result;
  }

  // Future<List<Map<String, dynamic>>> getGradeCard(String studentName) async {
  //   final db = await database;
  //   print("student id for grade card $studentName");
  //   // Check if studentId is correctly passed and is not empty
  //   if (studentName.isEmpty) {
  //     throw ArgumentError("Student Name cannot be empty");
  //   }
  //   final sudentIdResults = await db.rawQuery(
  //       'SELECT id FROM student_table WHERE LOWER(student_name) = LOWER(?);',
  //       [studentName]);
  //   // Check if the query returned any results
  //   if (sudentIdResults.isEmpty) {
  //     print("No student Name found with name: $studentName !");
  //     return []; // Return an empty list if no class is found
  //   }
  //   // Get the class ID from the result
  //   int studentId = sudentIdResults[0]['id'] as int;

  Future<List<Map<String, dynamic>>> getStudentData(int studentId) async {
    final db = await database;

    print("student id $studentId");

    String query = ''' SELECT 
    s.student_name,
    s.photo_id AS photo_path,
    s.gender,
    s.school_name,
    c.class_name,
    c.academic_year,
   st.stream_name
FROM 
    student_table s
LEFT JOIN 
    stream_table st ON s.stream_id = st.id
LEFT JOIN 
    class_table c ON st.class_id = c.id
WHERE 
    s.id = ?''';

    try {
      // Execute the query and get the result
      List<Map<String, dynamic>> result = await db.rawQuery(query, [
        studentId,
      ]);

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

  Future<List<Map<String, dynamic>>> getGradeCard(int studentId) async {
    final db = await database;

    String query = ''' SELECT 
    s.student_name,
    s.photo_id AS photo_path,
    s.gender,
    c.class_name,
    c.academic_year,
    sub.subject_name,
    COALESCE(ts.score, '-') AS score,
    t.max_mark,
    t.test_date,
    t.id AS test_id
FROM 
    student_table s
LEFT JOIN 
    stream_table st ON s.stream_id = st.id
LEFT JOIN 
    class_table c ON st.class_id = c.id
LEFT JOIN 
    stream_subjects_table ss ON st.id = ss.stream_id
LEFT JOIN 
    subject_table sub ON ss.subject_id = sub.id
LEFT JOIN 
    test_table t ON sub.id = t.subject_id
LEFT JOIN 
    test_score_table ts ON t.id = ts.test_id AND ts.student_id = s.id
LEFT JOIN (
    SELECT 
        ts.student_id,
        t.subject_id,
        t.id AS test_id,
        MAX(t.test_date) AS latest_test_date
    FROM 
        test_table t
    JOIN 
        test_score_table ts ON t.id = ts.test_id
    WHERE 
        ts.student_id = ?
    GROUP BY 
        ts.student_id, t.subject_id, t.id
) latest_test ON latest_test.subject_id = t.subject_id 
              AND latest_test.latest_test_date = t.test_date
WHERE 
    s.id = ?
    AND c.academic_year = ?
ORDER BY 
    sub.id; ''';

    try {
      // Execute the query and get the result
      List<Map<String, dynamic>> result =
          await db.rawQuery(query, [studentId, studentId, _acadamicYear]);

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

  Future<int> getMaxId(String tableName) async {
    final db = await database;

    String query = 'SELECT MAX(id) AS max_id FROM $tableName;';

    List<Map<String, dynamic>> result = await db.rawQuery(query);

    if (result.isNotEmpty && result[0]['max_id'] != null) {
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

      return maxId;
    }
  }

  Future<int> getMaxIdTX(Transaction txn, String tableName) async {
    final List<Map<String, dynamic>> result =
        await txn.rawQuery('SELECT MAX(id) as maxId FROM $tableName');
    return result.first['maxId'] ?? 0; // Returns 0 if there are no rows
  }

  Future<int> getSubjectId(String subjectName, int classid) async {
    final db = await database;

    // Ensure that subjectName is not null or empty
    if (subjectName.isEmpty) {
      throw ArgumentError("Subject name cannot be empty");
    }

    // Query to get the subject ID
    String query = '''
    SELECT id FROM subject_table  WHERE subject_name = ? AND class_id = ? ;
  ''';

    try {
      // Execute the query and get the result
      List<Map<String, dynamic>> result =
          await db.rawQuery(query, [subjectName, classid]);

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
    SELECT st.id FROM stream_table st join class_table c ON st.class_id = c.id WHERE st.stream_name = ? AND c.academic_year = ?;
  ''';

    try {
      // Execute the query and get the result
      List<Map<String, dynamic>> result =
          await db.rawQuery(query, [streamName, _acadamicYear]);

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

  Future<int> insertDynamicData(
      List<Map<String, dynamic>> classDataList,
      List<Map<String, dynamic>> subjectDataList,
      List<Map<String, dynamic>> streamDataList,
      List<Map<String, dynamic>> streamSubjectDataList) async {
    try {
      Database db = await database;
      await db.transaction((txn) async {
        Map<int, int> classIdMap = {}; // Maps class_id to generated id
        Map<int, int> subjectIdMap = {}; // Maps subject_id to generated id
        Map<int, int> streamIdMap = {}; // Maps stream_id to generated id

        // Insert classes and store their IDs
        for (var classData in classDataList) {
          int classId = (await getMaxIdTX(txn, 'class_table')) + 1;
          await txn.insert('class_table', {
            'id': classId,
            'class_name': classData['class_name'],
            'academic_year': classData['academic_year'],
            'section': classData['section']
          });
          classIdMap[classData['class_id']] = classId;
        }

        // Insert subjects and store their IDs
        for (var subjectData in subjectDataList) {
          int classId = classIdMap[subjectData['class_id']] ?? 0;
          int subjectId = (await getMaxIdTX(txn, 'subject_table')) + 1;
          await txn.insert('subject_table', {
            'id': subjectId,
            'subject_name': subjectData['subject_name'],
            'class_id': classId,
          });
          subjectIdMap[subjectData['subject_id']] = subjectId;
        }

        // Insert streams and store their IDs
        for (var streamData in streamDataList) {
          int classId = classIdMap[streamData['class_id']] ?? 0;
          int streamId = (await getMaxIdTX(txn, 'stream_table')) + 1;
          await txn.insert('stream_table', {
            'id': streamId,
            'stream_name': streamData['stream_name'],
            'class_id': classId,
          });
          streamIdMap[streamData['stream_id']] = streamId;
        }

        // Insert stream-subject mappings
        for (var streamSubjectData in streamSubjectDataList) {
          int streamId = streamIdMap[streamSubjectData['stream_id']] ?? 0;
          int subjectId = subjectIdMap[streamSubjectData['subject_id']] ?? 0;
          int streamSubjectId =
              (await getMaxIdTX(txn, 'stream_subjects_table')) + 1;
          await txn.insert('stream_subjects_table', {
            'id': streamSubjectId,
            'stream_id': streamId,
            'subject_id': subjectId,
          });
        }
      });

      print("Data successfully inserted into all tables.");
      return 1;
    } catch (e) {
      print("Transaction failed: $e");
      return 0;
    }
  }

  Future<int> startNewYear(String academicYear) async {
    List<Map<String, dynamic>> classDataList = [
      {
        'class_id': 1,
        'class_name': 'Plus Two STATE',
        'academic_year': academicYear,
        'section': 'HSS'
      },
      {
        'class_id': 2,
        'class_name': 'Plus Two CBSE',
        'academic_year': academicYear,
        'section': 'HSS'
      },
      {
        'class_id': 3,
        'class_name': 'Plus One STATE',
        'academic_year': academicYear,
        'section': 'HSS'
      },
      {
        'class_id': 4,
        'class_name': 'Plus One CBSE',
        'academic_year': academicYear,
        'section': 'HSS'
      },
      {
        'class_id': 5,
        'class_name': '10th STATE',
        'academic_year': academicYear,
        'section': 'HSS'
      },
      {
        'class_id': 6,
        'class_name': '10th CBSE',
        'academic_year': academicYear,
        'section': 'HS'
      },
      {
        'class_id': 7,
        'class_name': '9th STATE',
        'academic_year': academicYear,
        'section': 'HS'
      },
      {
        'class_id': 8,
        'class_name': '9th CBSE',
        'academic_year': academicYear,
        'section': 'HS'
      },
      {
        'class_id': 9,
        'class_name': '8th STATE',
        'academic_year': academicYear,
        'section': 'HS'
      },
      {
        'class_id': 10,
        'class_name': '8th CBSE',
        'academic_year': academicYear,
        'section': 'HS'
      },
    ];

    List<Map<String, dynamic>> subjectDataList = [
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
      // {'subject_id': 22, 'subject_name': 'Mathematics', 'class_id': 4},
      // {'subject_id': 23, 'subject_name': 'Physics', 'class_id': 4},
      // {'subject_id': 24, 'subject_name': 'Chemistry', 'class_id': 4},
      // {'subject_id': 25, 'subject_name': 'Botany', 'class_id': 4},
      // {'subject_id': 26, 'subject_name': 'Zoology', 'class_id': 4},
      // {'subject_id': 27, 'subject_name': 'English', 'class_id': 4},

      // 10th cbse

      // 9th state
      // 9th cbse
      // 8th state
      // 8th cbse
    ];

    List<Map<String, dynamic>> streamDataList = [
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
    ];

    List<Map<String, dynamic>> streamSubjectDataList = [
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
    ];

    return await insertDynamicData(
        classDataList, subjectDataList, streamDataList, streamSubjectDataList);
  }

  Future<List<Map<String, dynamic>>> getTestHistory() async {
    final db = await database;
    String query = '''SELECT DISTINCT
    t.id AS test_id,
    s.subject_name,
    t.topic,
    c.class_name,
    t.test_date
FROM 
    test_table t
JOIN 
    subject_table s ON t.subject_id = s.id
JOIN 
    stream_subjects_table ss ON s.id = ss.subject_id
JOIN 
    stream_table st ON ss.stream_id = st.id
JOIN 
    class_table c ON st.class_id = c.id
WHERE c.academic_year = ?
ORDER BY 
    t.id DESC;  


''';
    List<Map<String, dynamic>> results =
        await db.rawQuery(query, [_acadamicYear]);

    return results;
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
