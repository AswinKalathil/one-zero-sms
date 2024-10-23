import 'package:one_zero/constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// void main() async {
//   // Initialize SQLite
//   sqfliteFfiInit();
//   var db = await openDatabase('my_database.db');

//   // Sync database
//   await syncDatabase(db);
// }

Future<void> syncDatabase(Database db) async {
  // Push local changes to cloud
  await pushLocalChangesToCloud(db);

  // Fetch changes from cloud
  // await fetchCloudChanges(db);

  // Store the current time as the last sync time
  await storeLastSyncTime(DateTime.now());
}

Future<void> storeLastSyncTime(DateTime time) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('lastSyncTime', time.toIso8601String());
}

Future<DateTime> getLastSyncTime() async {
  final prefs = await SharedPreferences.getInstance();
  final lastSyncTimeString = prefs.getString('lastSyncTime');

  if (lastSyncTimeString != null) {
    return DateTime.parse(lastSyncTimeString);
  }

  // Return a default value if no sync time is stored
  return DateTime.now().subtract(Duration(days: 1)); // Default to 1 day ago
}

Future<void> pushLocalChangesToCloud(Database db) async {
  final List<String> tables = [
    'class_table',
    'stream_table',
    'subject_table',
    'stream_subjects_table',
    'student_table',
    'test_table',
    'test_score_table'
  ];

  // Create a MySQL connection
  final connection = await MySqlConnection.connect(dbSettingLocal);

  for (var table in tables) {
    // Push new and updated records
    final List<Map<String, dynamic>> pendingRecords =
        await db.rawQuery('SELECT * FROM $table WHERE sync_pending = 1');

    // Use a transaction for batch inserts/updates
    await connection.transaction((trans) async {
      for (var record in pendingRecords) {
        record.remove('sync_pending'); // Remove sync_pending

        // Use a prepared statement for insert/update
        await trans.query('INSERT INTO $table SET ? ON DUPLICATE KEY UPDATE ?',
            [record, record]);

        // Mark record as synced
        await db.rawUpdate(
            'UPDATE $table SET sync_pending = 0 WHERE id = ?', [record['id']]);
      }
    });

    // Handle deleted rows
    final List<Map<String, dynamic>> deletedRecords = await db.rawQuery(
        'SELECT * FROM deleted_records WHERE table_name = ?', [table]);

    for (var deletedRecord in deletedRecords) {
      await connection
          .query('DELETE FROM $table WHERE id = ?', [deletedRecord['id']]);

      // Remove from local deleted_records
      await db.rawDelete(
          'DELETE FROM deleted_records WHERE id = ?', [deletedRecord['id']]);
    }
  }

  await connection.close();
}

Future<void> fetchCloudChanges(Database db) async {
  // Get the last sync time
  final lastSyncTime = await getLastSyncTime();

  // Connect to MySQL

  final MySqlConnection connection =
      await MySqlConnection.connect(dbSettingLocal);
  final List<String> tables = [
    'class_table',
    'stream_table',
    'subject_table',
    'stream_subjects_table',
    'student_table',
    'test_table',
    'test_score_table'
  ];

  for (var table in tables) {
    // Fetch only updated records since the last sync
    final results = await connection
        .query('SELECT * FROM $table WHERE updated_at > ?', [lastSyncTime]);

    for (var row in results) {
      Map<String, dynamic> record = {'id': row['id'], ...row.fields};

      // Check if the record exists locally
      final localRecord = await db
          .rawQuery('SELECT * FROM $table WHERE id = ?', [record['id']]);

      if (localRecord.isEmpty) {
        // Insert new record
        await db.insert(table, record);
      } else {
        // Resolve conflicts
        if (localRecord.first['updated_at'] != row['updated_at']) {
          // Example: Prefer cloud changes
          await db.update(
            table,
            record,
            where: 'id = ?',
            whereArgs: [record['id']],
          );
        }
      }
    }

    // Handle deletions from the cloud
    final cloudDeletedRecords = await connection
        .query('SELECT * FROM deleted_records WHERE table_name = ?', [table]);

    for (var deletedRecord in cloudDeletedRecords) {
      await db
          .rawDelete('DELETE FROM $table WHERE id = ?', [deletedRecord['id']]);
    }
  }

  await connection.close();
}
