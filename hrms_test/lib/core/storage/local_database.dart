import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Database? _db;
  final bool _isTest;

  LocalDatabase() : _isTest = false;
  LocalDatabase._test() : _isTest = true;

  static LocalDatabase forTesting() => LocalDatabase._test();

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = _isTest
        ? ':memory:'
        : join(await getDatabasesPath(), 'rebs_hrms.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''CREATE TABLE IF NOT EXISTS pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(table_name, record_id)
      )''');
      await db.execute('''CREATE TABLE IF NOT EXISTS leave_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        reason TEXT NOT NULL,
        days INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        is_synced INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        created_at TEXT NOT NULL
      )''');
      try {
        await db.execute(
          'ALTER TABLE attendance_events ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''CREATE TABLE attendance_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id TEXT NOT NULL UNIQUE,
      type TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      sync_status TEXT NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      error_message TEXT
    )''');
    await db.execute('''CREATE TABLE cache (
      cache_key TEXT PRIMARY KEY,
      payload TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE pending_sync (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      created_at TEXT NOT NULL,
      UNIQUE(table_name, record_id)
    )''');
    await db.execute('''CREATE TABLE leave_requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      request_id TEXT NOT NULL UNIQUE,
      type TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      reason TEXT NOT NULL,
      days INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      is_synced INTEGER NOT NULL DEFAULT 0,
      error_message TEXT,
      created_at TEXT NOT NULL
    )''');
  }

  // ── Cache ─────────────────────────────────────────────
  Future<void> cache(String key, String value) async {
    final db = await database;
    await db.insert('cache', {
      'cache_key': key,
      'payload': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> readCache(String key) async {
    final rows = await (await database).query(
      'cache',
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['payload'] as String;
  }

  // ── Attendance Events ─────────────────────────────────
  Future<void> addEvent(Map<String, dynamic> event) async {
    final db = await database;
    await db.insert(
      'attendance_events',
      event,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    if ((event['sync_status'] as String?) == 'pending') {
      await db.insert('pending_sync', {
        'table_name': 'attendance_events',
        'record_id': event['event_id'],
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<Map<String, dynamic>>> events({String? status}) async {
    return (await database).query(
      'attendance_events',
      where: status == null ? null : 'sync_status = ?',
      whereArgs: status == null ? null : [status],
      orderBy: 'id ASC',
    );
  }

  Future<void> updateEvent(String id, String status, [String? message]) async {
    final db = await database;
    final isSynced = status == 'synced' ? 1 : 0;
    await db.update(
      'attendance_events',
      {'sync_status': status, 'is_synced': isSynced, 'error_message': message},
      where: 'event_id = ?',
      whereArgs: [id],
    );
    if (status == 'synced' || status == 'rejected') {
      await db.delete(
        'pending_sync',
        where: 'table_name = ? AND record_id = ?',
        whereArgs: ['attendance_events', id],
      );
    }
  }

  Future<bool> hasEvent(String date, String type) async {
    final rows = await (await database).query(
      'attendance_events',
      where:
          "substr(timestamp,1,10)=? AND type=? AND sync_status != 'rejected'",
      whereArgs: [date, type],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ── Pending Sync ──────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPendingSync() async {
    return (await database).query('pending_sync', orderBy: 'id ASC');
  }

  Future<int> pendingSyncCount() async {
    final rows = await (await database).query('pending_sync');
    return rows.length;
  }

  // ── Leave Requests ────────────────────────────────────
  Future<void> addLeaveRequest(Map<String, dynamic> req) async {
    final db = await database;
    await db.insert(
      'leave_requests',
      req,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if ((req['is_synced'] as int?) == 0) {
      await db.insert('pending_sync', {
        'table_name': 'leave_requests',
        'record_id': req['request_id'],
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveRequests() async {
    return (await database).query('leave_requests', orderBy: 'created_at DESC');
  }

  Future<void> updateLeaveRequest(
    String id, {
    required int isSynced,
    String? status,
    String? errorMessage,
  }) async {
    final db = await database;
    final update = <String, dynamic>{'is_synced': isSynced};
    if (status != null) update['status'] = status;
    if (errorMessage != null) update['error_message'] = errorMessage;
    await db.update(
      'leave_requests',
      update,
      where: 'request_id = ?',
      whereArgs: [id],
    );
    if (isSynced == 1) {
      await db.delete(
        'pending_sync',
        where: 'table_name = ? AND record_id = ?',
        whereArgs: ['leave_requests', id],
      );
    }
  }
}
