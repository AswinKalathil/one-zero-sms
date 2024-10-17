import 'package:mysql1/mysql1.dart';
import 'package:one_zero/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static MySqlConnection? _connection;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<MySqlConnection> get connection async {
    if (_connection != null) return _connection!;

    _connection = await _initDatabase();
    return _connection!;
  }

  Future<MySqlConnection> _initDatabase() async {
    var settings = ConnectionSettings(
      host: 'localhost', // Update with your host
      port: 3306, // Default MySQL port
      user: 'your_username', // Update with your MySQL username
      password: 'your_password', // Update with your MySQL password
      db: 'your_database_name', // Update with your MySQL database name
    );

    return await MySqlConnection.connect(settings);
  }

  String _academicYear = DateTime.now().year.toString() +
      "-" +
      (DateTime.now().year + 1).toString().substring(2);

  void setAcademicYear(String academicYear) {
    _academicYear = academicYear;
    print("New Academic year private: $_academicYear");
  }

  Future<void> _onCreate(MySqlConnection conn) async {
    await conn.query(createQuery); // Use your create table query here
    // Other table creation queries can be executed here
  }

  Future<int?> insertToTable(
      String tableName, Map<String, dynamic> values) async {
    final conn = await connection;
    try {
      var result = await conn.query('INSERT INTO $tableName SET ?', [values]);
      return result.insertId; // returns the ID of the inserted row
    } catch (e) {
      print("Error occurred while inserting data: $e");
      return 0; // Return 0 or an error code if insertion fails
    }
  }

  Future<List<String>> getAcademicYears() async {
    final conn = await connection;
    try {
      var results =
          await conn.query('SELECT DISTINCT academic_year FROM class_table;');
      List<String> years = results.map((row) => row[0] as String).toList();
      print(years);
      return years;
    } catch (e) {
      print("Error occurred while fetching academic years: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getTestDetails(int testId) async {
    final conn = await connection;
    try {
      var results = await conn.query(
          'SELECT s.subject_name, tt.test_date, tt.topic, tt.max_mark '
          'FROM test_table tt '
          'JOIN subject_table s ON tt.subject_id = s.id '
          'WHERE tt.id = ?',
          [testId]);
      if (results.isNotEmpty) {
        return {
          'subject_name': results.first[0],
          'test_date': results.first[1],
          'topic': results.first[2],
          'max_mark': results.first[3],
        };
      }
      return {};
    } catch (e) {
      print("Error occurred while fetching test details: $e");
      return {};
    }
  }

  Future<List<String>> getStreamNames(int classId) async {
    print("class id in getStreamNames function $classId");
    final conn = await connection;
    try {
      var results = await conn.query(
          'SELECT stream_name FROM stream_table WHERE class_id = ?;',
          [classId]);
      return results.map((row) => row[0] as String).toList();
    } catch (e) {
      print("Error occurred while fetching stream names: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getClasses(String tableName) async {
    final conn = await connection;

    var results = await conn.query(
      'SELECT * FROM $tableName WHERE academic_year = ?',
      [_academicYear],
    );

    return results.map((row) {
      return {
        'column1': row[0], // replace 'column1' with actual column names
        'column2': row[1],
        // Add other columns here
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getStudentIdsAndNamesByTestId(
      int testId) async {
    final conn = await connection;

    // Get the subject_id from the test_id
    var subjectIdResult = await conn.query(
      'SELECT subject_id FROM test_table WHERE id = ?',
      [testId],
    );

    if (subjectIdResult.isEmpty) return [];

    final subjectId = subjectIdResult.first[0]; // Access the subject_id

    // Get students related to that subject
    var studentResult = await conn.query('''
      SELECT DISTINCT s.id AS student_id, s.student_name
      FROM student_table s
      INNER JOIN stream_subjects_table ss ON s.stream_id = ss.stream_id
      WHERE ss.subject_id = ?
      ORDER BY s.student_name ASC;
    ''', [subjectId]);

    return studentResult.map((row) {
      return {
        'student_id': row[0],
        'student_name': row[1],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTestDataSheetForUpdate(
      int testId) async {
    final conn = await connection;

    // Get the test data sheet
    var testDataSheet = await conn.query('''
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
      ON ts.student_id = s.id
      ORDER BY s.student_name ASC;
    ''', [testId]);

    return testDataSheet.map((row) {
      return {
        'student_name': row[0],
        'student_id': row[1],
        'test_id': row[2],
        'test_score_id': row[3],
        'score': row[4],
      };
    }).toList();
  }

  Future<int> updateTestScore(int id, Map<String, dynamic> testScore) async {
    final conn = await connection;

    // Prepare the values for the update
    var result = await conn.query(
      'UPDATE test_score_table SET score = ? WHERE id = ?',
      [testScore['score'], id],
    );

    return result.affectedRows ?? 0; // Return the number of affected rows
  }

  Future<int?> getStudentId(String studentName) async {
    final conn = await connection;

    // Check if studentName is null or empty
    if (studentName.isEmpty) {
      throw ArgumentError("Student name cannot be empty");
    }

    String query = '''
    SELECT id FROM student_table WHERE LOWER(student_name) = LOWER(?);
  ''';

    try {
      // Execute the query and get the result
      var result = await conn.query(query, [studentName]);

      // Check if the result is empty and return null if no student is found
      if (result.isEmpty) {
        return null;
      }

      // Return the student ID
      return result.first[0] as int; // Access the first column
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred while fetching student ID: $e");
      throw Exception("Failed to retrieve student ID. Please try again later.");
    }
  }

  Future<List<String>?> getClassSubjects(int classId) async {
    final conn = await connection;
    String query = '''
    SELECT 
      DISTINCT sub.id AS subject_id, sub.subject_name,
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
      c.id = ?;
  ''';

    try {
      // Execute the query and get the result
      var results = await conn.query(query, [classId]);

      // Check if the result is empty and return null if no subjects are found
      if (results.isEmpty) {
        print("No subjects found for class: $classId");
        return [];
      }

      // Return the list of subjects
      List<String> subjects = results
          .map((row) => row[1] as String)
          .toList(); // Use index 1 for subject_name
      return subjects;
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred while fetching subjects: $e");
      throw Exception("Failed to retrieve subjects. Please try again later.");
    }
  }

  // Fetch students of a subject
  Future<List<Map<String, dynamic>>> getStudentsOfSubject(
      String subjectName) async {
    final conn = await connection;

    try {
      print("Subject Name: $subjectName");

      // Query to get the subject ID
      final queryResults = await conn.query(
          'SELECT id FROM subject_table WHERE LOWER(subject_name) = LOWER(?);',
          [subjectName]);

      // Check if the query returned any results
      if (queryResults.isEmpty) {
        print("No subject found with name: $subjectName");
        return []; // Return an empty list if no subject is found
      }

      // Get the subject ID from the result
      int subjectId = queryResults.first[0] as int; // Use index 0 for id
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
        sub.id = ?;
    ''';

      final result = await conn.query(query, [subjectId]);
      return result
          .map((row) => {
                'id': row[0],
                'student_name': row[1],
                'gender': row[2],
                'photo_id': row[3],
                'stream_name': row[4],
              })
          .toList();
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred: $e");
      return []; // Return an empty list or handle the error as needed
    }
  }

  Future<List<Map<String, dynamic>>> getSubjectsOfStudentID(
      int studentId) async {
    try {
      final conn = await connection;

      String query = '''
      SELECT 
        sub.id AS subject_id, 
        sub.subject_name 
      FROM 
        stream_subjects_table ss
      JOIN 
        subject_table sub ON ss.subject_id = sub.id
      WHERE 
        ss.stream_id = (SELECT stream_id FROM student_table WHERE id = ?);
    ''';

      final result = await conn.query(query, [studentId]);
      return result
          .map((row) => {
                'subject_id': row[0],
                'subject_name': row[1],
              })
          .toList();
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred: $e");
      return []; // Return an empty list or handle the error as needed
    }
  }

  Future<List<Map<String, dynamic>>> getTestHistoryForSubjectOfStudentID(
      int studentId, int subjectId) async {
    final conn = await connection;

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

    ORDER BY t.test_date DESC;
  ''';

    final result = await conn.query(query, [studentId, subjectId]);

    return result
        .map((row) => {
              'test_id': row[0],
              'topic': row[1],
              'max_mark': row[2],
              'test_date': row[3],
              'score': row[4],
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStudentsOfNameAndClass(
      String studentName, int classId) async {
    final conn = await connection;

    try {
      print("Student Name: $studentName");

      // Query to get the student ID
      final queryResults = await conn.query(''' SELECT 
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
       LOWER(s.student_name) LIKE LOWER(?) AND c.id = ?
    ORDER BY 
    CASE 
      WHEN LOWER(s.student_name) LIKE LOWER(?) THEN 1  
      ELSE 2                      
    END, 
    s.student_name;   
       ''', ['%$studentName%', classId, '$studentName%']);

      // Check if the query returned any results
      if (queryResults.isEmpty) {
        print("No student found with name: $studentName");
        return []; // Return an empty list if no student is found
      }
      print("Results of class with name $queryResults");

      return queryResults
          .map((row) => {
                'id': row[0],
                'student_name': row[1],
                'gender': row[2],
                'photo_id': row[3],
                'stream_name': row[4],
              })
          .toList();
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred: $e");
      return []; // Return an empty list or handle the error as needed
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsOfName(
      String studentName) async {
    final conn = await connection;

    try {
      print("Student Name: $studentName");

      // Query to get the student ID
      final queryResults = await conn.query(''' SELECT 
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
      WHEN LOWER(s.student_name) LIKE LOWER(?) THEN 1  
      ELSE 2                      
    END, 
    s.student_name;   
       ''', ['%$studentName%', _academicYear, '$studentName%']);

      // Check if the query returned any results
      if (queryResults.isEmpty) {
        print("No student found with name: $studentName");
        return []; // Return an empty list if no student is found
      }

      return queryResults
          .map((row) => {
                'id': row[0],
                'student_name': row[1],
                'gender': row[2],
                'photo_id': row[3],
                'stream_name': row[4],
              })
          .toList();
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred: $e");
      return []; // Return an empty list or handle the error as needed
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsOfClass(int classId) async {
    print("Class id : $classId academic year: $_academicYear");
    final conn = await connection;

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
      c.id = ?
    ORDER BY s.student_name ASC;  
  ''';

    // Execute the query
    try {
      var results = await conn.query(query, [classId]);
      print("result of getStudentsOfClass: $results");

      return results
          .map((row) => {
                'id': row[0],
                'student_name': row[1],
                'gender': row[2],
                'photo_id': row[3],
                'stream_name': row[4],
              })
          .toList();
    } catch (e) {
      print("Error occurred while fetching students: $e");
      return []; // Return an empty list or handle the error as needed
    }
  }

  Future<List<Map<String, dynamic>>> getStudentData(int studentId) async {
    final conn = await connection;

    print("student id: $studentId");

    String query = '''
    SELECT 
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
      s.id = ?;''';

    try {
      // Execute the query and get the result
      var results = await conn.query(query, [studentId]);

      // Check if the result is empty
      if (results.isEmpty) {
        throw ArgumentError("No student found with the given ID");
      }

      return results
          .map((row) => {
                'student_name': row[0],
                'photo_path': row[1],
                'gender': row[2],
                'school_name': row[3],
                'class_name': row[4],
                'academic_year': row[5],
                'stream_name': row[6],
              })
          .toList();
    } catch (e) {
      // Handle any exceptions that occur
      print("Error occurred while fetching student data: $e");
      throw Exception(
          "Failed to retrieve student data. Please try again later.");
    }
  }

  Future<List<Map<String, dynamic>>> getGradeCard(int studentId) async {
    final conn = await connection;

    String query = '''
  SELECT 
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
          ts.student_id, t.subject_id
  ) latest_test ON latest_test.subject_id = t.subject_id 
                AND latest_test.latest_test_date = t.test_date
  WHERE 
      s.id = ?
      AND c.academic_year = ?
  ORDER BY 
      sub.id; ''';

    try {
      // Execute the query and get the result
      var results =
          await conn.query(query, [studentId, studentId, _academicYear]);

      // Check if the result is empty
      if (results.isEmpty) {
        throw ArgumentError("No student found with the given ID");
      }

      return results
          .map((row) => {
                'student_name': row[0],
                'photo_path': row[1],
                'gender': row[2],
                'class_name': row[3],
                'academic_year': row[4],
                'subject_name': row[5],
                'score': row[6],
                'max_mark': row[7],
                'test_date': row[8],
                'test_id': row[9],
              })
          .toList();
    } catch (e) {
      print("Error occurred while fetching grade card: $e");
      throw Exception(
          "Failed to retrieve grade card data. Please try again later.");
    }
  }

  Future<int> getMaxId(String tableName) async {
    final conn = await connection;

    String query = 'SELECT MAX(id) AS max_id FROM $tableName;';

    var results = await conn.query(query);

    if (results.isNotEmpty && results.first[0] != null) {
      return results.first[0] as int;
    } else {
      // Define base max IDs for different tables
      int maxId = 0;
      switch (tableName) {
        case 'class_table':
          maxId = 1000;
          break;
        case 'subject_table':
          maxId = 2000;
          break;
        case 'stream_table':
          maxId = 3000;
          break;
        case 'student_table':
          maxId = 4000;
          break;
        case 'test_table':
          maxId = 5000;
          break;
        case 'test_score_table':
          maxId = 6000;
          break;
        case 'stream_subjects_table':
          maxId = 7000;
          break;
        default:
          maxId = 0;
      }
      return maxId;
    }
  }

  Future<int> getMaxIdTX(dynamic txn, String tableName) async {
    var results = await txn.query('SELECT MAX(id) AS max_id FROM $tableName');
    return results.isNotEmpty
        ? results.first['max_id'] ?? 0
        : 0; // Returns 0 if there are no rows
  }

  Future<int> getSubjectId(String subjectName, int classId) async {
    final conn = await connection;

    // Ensure that subjectName is not null or empty
    if (subjectName.isEmpty) {
      throw ArgumentError("Subject name cannot be empty");
    }

    // Query to get the subject ID
    String query = '''
  SELECT id FROM subject_table WHERE subject_name = ? AND class_id = ?;
  ''';

    try {
      // Execute the query and get the result
      var results = await conn.query(query, [subjectName, classId]);

      // Check if the result is empty and return 0 if no subject is found
      if (results.isEmpty) {
        return 0; // Return 0 if no subject is found
      }

      // Return the subject ID
      return results.first['id'] as int;
    } catch (e) {
      print("Error occurred while fetching subject ID: $e");
      throw Exception("Failed to retrieve subject ID. Please try again later.");
    }
  }

  Future<int> getStreamId(String streamName) async {
    final conn = await connection;

    // Ensure that streamName is not null or empty
    if (streamName.isEmpty) {
      throw ArgumentError("Stream name cannot be empty");
    }

    // Query to get the stream ID
    String query = '''
  SELECT st.id FROM stream_table st 
  JOIN class_table c ON st.class_id = c.id 
  WHERE st.stream_name = ? AND c.academic_year = ?;
  ''';

    try {
      // Execute the query and get the result
      var results = await conn.query(query, [streamName, _academicYear]);

      // Check if the result is empty and return 0 if no stream is found
      if (results.isEmpty) {
        return 0; // Return 0 if no stream is found
      }

      // Return the stream ID
      return results.first['id'] as int;
    } catch (e) {
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
      final conn = await connection;

      await conn.transaction((txn) async {
        Map<int, int> classIdMap = {}; // Maps class_id to generated id
        Map<int, int> subjectIdMap = {}; // Maps subject_id to generated id
        Map<int, int> streamIdMap = {}; // Maps stream_id to generated id

        // Insert classes and store their IDs
        for (var classData in classDataList) {
          int classId = (await getMaxIdTX(txn, 'class_table')) + 1;
          await txn.query(
              'INSERT INTO class_table (id, class_name, academic_year, section) VALUES (?, ?, ?, ?)',
              [
                classId,
                classData['class_name'],
                classData['academic_year'],
                classData['section']
              ]);
          classIdMap[classData['class_id']] = classId;
        }

        // Insert subjects and store their IDs
        for (var subjectData in subjectDataList) {
          int classId = classIdMap[subjectData['class_id']] ?? 0;
          int subjectId = (await getMaxIdTX(txn, 'subject_table')) + 1;
          await txn.query(
              'INSERT INTO subject_table (id, subject_name, class_id) VALUES (?, ?, ?)',
              [
                subjectId,
                subjectData['subject_name'],
                classId,
              ]);
          subjectIdMap[subjectData['subject_id']] = subjectId;
        }

        // Insert streams and store their IDs
        for (var streamData in streamDataList) {
          int classId = classIdMap[streamData['class_id']] ?? 0;
          int streamId = (await getMaxIdTX(txn, 'stream_table')) + 1;
          await txn.query(
              'INSERT INTO stream_table (id, stream_name, class_id) VALUES (?, ?, ?)',
              [
                streamId,
                streamData['stream_name'],
                classId,
              ]);
          streamIdMap[streamData['stream_id']] = streamId;
        }

        // Insert stream-subject mappings
        for (var streamSubjectData in streamSubjectDataList) {
          int streamId = streamIdMap[streamSubjectData['stream_id']] ?? 0;
          int subjectId = subjectIdMap[streamSubjectData['subject_id']] ?? 0;
          int streamSubjectId =
              (await getMaxIdTX(txn, 'stream_subjects_table')) + 1;
          await txn.query(
              'INSERT INTO stream_subjects_table (id, stream_id, subject_id) VALUES (?, ?, ?)',
              [
                streamSubjectId,
                streamId,
                subjectId,
              ]);
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
    var conn = await connection;
    try {
      await conn.transaction((txn) async {
        List<Map<String, dynamic>> classDataList = [
          // ... (same class data as before)
        ];

        List<Map<String, dynamic>> subjectDataList = [
          // ... (same subject data as before)
        ];

        List<Map<String, dynamic>> streamDataList = [
          // ... (same stream data as before)
        ];

        List<Map<String, dynamic>> streamSubjectDataList = [
          // ... (same stream subject data as before)
        ];

        // Insert class data
        for (var classData in classDataList) {
          await txn.query(
              'INSERT INTO class_table (class_id, class_name, academic_year, section) VALUES (?, ?, ?, ?)',
              [
                classData['class_id'],
                classData['class_name'],
                academicYear,
                classData['section']
              ]);
        }

        // Insert subject data
        for (var subjectData in subjectDataList) {
          await txn.query(
              'INSERT INTO subject_table (subject_id, subject_name, class_id) VALUES (?, ?, ?)',
              [
                subjectData['subject_id'],
                subjectData['subject_name'],
                subjectData['class_id']
              ]);
        }

        // Insert stream data
        for (var streamData in streamDataList) {
          await txn.query(
              'INSERT INTO stream_table (stream_id, stream_name, class_id) VALUES (?, ?, ?)',
              [
                streamData['stream_id'],
                streamData['stream_name'],
                streamData['class_id']
              ]);
        }

        // Insert stream-subject mapping
        for (var streamSubjectData in streamSubjectDataList) {
          await txn.query(
              'INSERT INTO stream_subjects_table (stream_id, subject_id) VALUES (?, ?)',
              [
                streamSubjectData['stream_id'],
                streamSubjectData['subject_id']
              ]);
        }
      });
      return 1; // Return success
    } catch (e) {
      print('Error during transaction: $e');
      return 0; // Return failure
    } finally {
      await conn.close();
    }
  }

  Future<List<Map<String, dynamic>>> getTestHistory(int class_id) async {
    var conn = await connection;
    try {
      String query = '''
        SELECT DISTINCT
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
        WHERE 
          c.id = ?
        ORDER BY 
          t.id DESC;
      ''';

      Results results = await conn.query(query, [class_id]);
      return results.map((row) {
        return {
          'test_id': row[0],
          'subject_name': row[1],
          'topic': row[2],
          'class_name': row[3],
          'test_date': row[4],
        };
      }).toList();
    } catch (e) {
      print('Error retrieving test history: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  Future<int> deleteFromTable(String tablename, int id) async {
    var conn = await connection;
    try {
      String query = 'DELETE FROM $tablename WHERE id = ?';
      var result = await conn.query(query, [id]);
      return result.affectedRows ?? 0; // Return number of affected rows
    } catch (e) {
      print('Error deleting from table: $e');
      return 0; // Return failure
    } finally {
      await conn.close();
    }
  }
}
