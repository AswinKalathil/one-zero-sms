// import 'package:sqflite/sqflite.dart';
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
  class_id VARCHAR(20) NOT NULL,
  class_name VARCHAR(128) NOT NULL,
  academic_year VARCHAR(20) NOT NULL,
  PRIMARY KEY (class_id)
);

CREATE TABLE stream_table 
(
  stream_id varchar(20) NOT NULL,
  class_id varchar(20),
  PRIMARY KEY (stream_id),
  FOREIGN key (class_id) REFERENCES class(class_id)
);

CREATE TABLE subject_table 
(
  subject_id varchar(20) NOT NULL,
  subject_name varchar(128) NOT NULL,
  class_id varchar(20),
  PRIMARY KEY (subject_id),
  FOREIGN key (class_id) REFERENCES class_table(class_id)
  
);
CREATE TABLE stream_subjects_table  (
  stream_id varchar(20),
  subject_id varchar(20),
  PRIMARY KEY (stream_id, subject_id),
  FOREIGN KEY (stream_id) REFERENCES stream(stream_id),
  FOREIGN KEY (subject_id) REFERENCES subject(subject_id)
);

CREATE TABLE student_table 
(
  student_id varchar(20) NOT NULL,
  student_name varchar(255) NOT NULL,
  photo_id varchar(128),
  student_phone varchar(20),
  parent_name varchar(255),
  parent_phone varchar(20),
  school_name varchar(255),
  stream_id varchar(20) NOT NULL,
  primary KEY (student_id),
  FOREIGN key (stream_id) REFERENCES stream(stream_id)
);
CREATE TABLE test_table 
(
  test_id varchar(20) NOT NULL,
  subject_id varchar(20),
  max_mark int,
  test_date DATETIME NOT NULL,
  PRIMARY KEY (test_id),
  FOREIGN key (subject_id) REFERENCES subject(subject_id)
);
CREATE TABLE test_score_table 
(
  test_score_id varchar(20) NOT NULL,
	score int ,
  student_id varchar(20),
  test_id varchar(20),
  PRIMARY key (test_score_id),
  FOREIGN key (student_id) REFERENCES student(student_id),
  FOREIGN KEY (test_id) REFERENCES test(test_id)
);
 
CREATE VIEW latest_scores_view AS
WITH LatestTests AS (
  SELECT
    t.subject_id,
    t.test_id
  FROM test_table  t
  JOIN (
    SELECT
      subject_id,
      MAX(test_date) AS latest_date
    FROM test_table 
    GROUP BY subject_id
  ) lt
  ON t.subject_id = lt.subject_id
  AND t.test_date = lt.latest_date
)
SELECT
  s.student_id,
  s.student_name,
  sub.subject_name,
  lt.test_id,
  ts.score
FROM LatestTests lt
JOIN subject_table  sub ON lt.subject_id = sub.subject_id
JOIN test_score_table  ts ON lt.test_id = ts.test_id
JOIN student_table  s ON ts.student_id = s.student_id;
 

 

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
// }
