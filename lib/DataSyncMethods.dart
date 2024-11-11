import 'dart:io';

import 'package:one_zero/constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

Future<void> logToFile(String message) async {
  final directory = Directory.current; // Get the current directory
  final logFile =
      File('${directory.path}/app_log.txt'); // Specify log file path

  // Prepare the log entry with timestamp
  final timestamp = DateTime.now().toIso8601String();
  final logEntry = '[$timestamp] $message\n';

  // Append the log entry to the log file
  await logFile.writeAsString(logEntry, mode: FileMode.append);
}

Future<void> syncDatabase(Database db) async {
  await logToFile('Starting database sync...');

  // Capture the start time
  final startTime = DateTime.now();

  try {
    // Perform sync tasks
    await fetchCloudChanges(db);
    await pushLocalChangesToCloud(db);
  } catch (e) {
    await logToFile('Error pushing local changes to cloud: $e');
  } finally {
    await storeLastSyncTime(DateTime.now().toUtc());

    // Calculate and log the total sync duration
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    await logToFile('Total sync duration: ${duration.inSeconds} seconds');
  }
}

Future<bool> _checkFirstTime() async {
  final prefs = await SharedPreferences.getInstance();
  // Check if 'firstTime' key exists
  bool? firstTime = prefs.getBool('firstTime');

  if (firstTime == null || firstTime) {
    // This is the first time opening the app

    // Set the 'firstTime' flag to false
    await prefs.setBool('firstTime', false);
    return true;
  } else {
    // Not the first time opening the app
    return false;
  }
}

Future<void> storeLastSyncTime(DateTime time) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('lastSyncTime', time.toIso8601String());
  await logToFile('Stored last sync time: $time');
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

  final connection = await MySqlConnection.connect(dbSettingLocal);

  for (var table in tables) {
    await logToFile('Pushing local changes for $table...');

    final List<Map<String, dynamic>> pendingRecords =
        await db.rawQuery('SELECT * FROM $table WHERE sync_pending = 1');

    if (pendingRecords.isEmpty) {
      await logToFile('No local changes found for $table');
      continue;
    }

    await connection.transaction((trans) async {
      for (var record in pendingRecords) {
        final mutableRecord = Map<String, dynamic>.from(record);

        // Remove fields that shouldn't be inserted into the cloud database
        mutableRecord.remove('sync_pending');

        // Set last_modified to current UTC time before inserting
        mutableRecord['last_modified'] =
            DateTime.now().toUtc().toIso8601String();

        // Prepare fields and values for the INSERT statement
        final nonNullFields = mutableRecord.keys
            .where((key) => mutableRecord[key] != null)
            .join(', ');
        final nonNullPlaceholders = mutableRecord.keys
            .where((key) => mutableRecord[key] != null)
            .map((_) => '?')
            .join(', ');
        final updateFields = mutableRecord.keys
            .where((key) => mutableRecord[key] != null)
            .map((key) => '$key = VALUES($key)')
            .join(', ');

        final nonNullValues = mutableRecord.values
            .where((value) => value != null)
            .map((value) => value as Object)
            .toList();

        // Construct and execute the INSERT ON DUPLICATE KEY UPDATE query
        final query =
            'INSERT INTO $table ($nonNullFields) VALUES ($nonNullPlaceholders) '
            'ON DUPLICATE KEY UPDATE $updateFields';

        var check = await trans.query(query, nonNullValues);

        // Update sync_pending status in the local database based on query result
        if (check.insertId != 0) {
          await db.rawUpdate('UPDATE $table SET sync_pending = 0 WHERE id = ?',
              [record['id']]);
        } else {
          await db.rawUpdate('UPDATE $table SET sync_pending = 1 WHERE id = ?',
              [record['id']]);
        }
      }
    });

    await logToFile('Successfully pushed local changes for $table.');

    // Handle deleted rows
    final List<Map<String, dynamic>> deletedRecords = await db.rawQuery(
        'SELECT * FROM deleted_records WHERE table_name = ?', [table]);

    for (var deletedRecord in deletedRecords) {
      await connection
          .query('DELETE FROM $table WHERE id = ?', [deletedRecord['id']]);

      await db.rawDelete(
          'DELETE FROM deleted_records WHERE id = ?', [deletedRecord['id']]);
      await logToFile('Deleted record from $table: ${deletedRecord['id']}');
    }
  }

  await connection.close();
  await logToFile('Finished pushing local changes.');
}

Future<void> fetchCloudChanges(Database db) async {
  try {
    final lastSyncTime = await getLastSyncTime();
    await logToFile('Last sync time: $lastSyncTime');

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
      try {
        bool firstTime = await _checkFirstTime();
        var results;
        if (firstTime) {
          await logToFile('First time sync for $table');
          results = await connection.query(
            'SELECT * FROM $table',
            [],
          );
        } else {
          results = await connection.query(
            'SELECT * FROM $table WHERE last_modified > ?',
            [lastSyncTime.toUtc().toIso8601String()],
          );
        }

        if (results.isEmpty) {
          await logToFile('No new records found for $table');
        } else {
          await logToFile('Syncing $table: ${results.length} records');
        }

        for (var row in results) {
          try {
            Map<String, dynamic> record = {'id': row['id'], ...row.fields};

            // Convert DateTime fields to ISO8601 strings for compatibility with sqflite
            record = record.map((key, value) {
              if (value is DateTime) {
                return MapEntry(key, value.toIso8601String());
              } else {
                return MapEntry(key, value);
              }
            });

            record.remove('sync_pending');
            record.remove('last_modified');

            final localRecord = await db
                .rawQuery('SELECT * FROM $table WHERE id = ?', [record['id']]);

            if (localRecord.isEmpty) {
              await db.insert(table, record);
              await logToFile(
                  'Inserted new record into $table: ${record['id']}');
            } else {
              await db.update(
                table,
                record,
                where: 'id = ?',
                whereArgs: [record['id']],
              );
              await logToFile('Updated record in $table: ${record['id']}');
            }
          } catch (e) {
            await logToFile('Error processing record for $table: $e');
          }
        }

        try {
          final cloudDeletedRecords = await connection.query(
              'SELECT * FROM deleted_records WHERE table_name = ?', [table]);

          for (var deletedRecord in cloudDeletedRecords) {
            await db.rawDelete(
                'DELETE FROM $table WHERE id = ?', [deletedRecord['id']]);
            await logToFile(
                'Deleted record from $table: ${deletedRecord['id']}');
          }
        } catch (e) {
          await logToFile('Error processing deleted records for $table: $e');
        }
      } catch (e) {
        await logToFile('Error syncing table $table: $e');
      }
    }

    await logToFile('Last sync time updated to: ${DateTime.now().toUtc()}');

    await connection.close();
  } catch (e) {
    await logToFile('Error connecting to MySQL or syncing data: $e');
  }
}
