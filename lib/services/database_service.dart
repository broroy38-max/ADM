import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/download_task.dart';
import '../models/site_profile.dart';
import '../models/smart_rule.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'adm_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE downloads (
        id TEXT PRIMARY KEY,
        url TEXT NOT NULL,
        filename TEXT NOT NULL,
        savePath TEXT NOT NULL,
        category INTEGER NOT NULL,
        status INTEGER NOT NULL,
        totalBytes INTEGER NOT NULL,
        downloadedBytes INTEGER NOT NULL,
        connections INTEGER NOT NULL,
        segments TEXT,
        priority INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        completedAt INTEGER,
        etag TEXT,
        lastModified TEXT,
        supportsRange INTEGER NOT NULL,
        retryCount INTEGER NOT NULL,
        failureReason TEXT,
        failureDetails TEXT,
        suggestedAction TEXT,
        checksumExpected TEXT,
        checksumActual TEXT,
        checksumType TEXT,
        customHeaders TEXT,
        speedLimitBytesPerSec INTEGER,
        isScheduled INTEGER NOT NULL,
        scheduledTime INTEGER,
        wifiOnly INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE site_profiles (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        maxConnections INTEGER NOT NULL,
        customHeaders TEXT,
        cookies TEXT,
        userAgent TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE smart_rules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        domainPattern TEXT,
        fileExtension TEXT,
        targetCategory INTEGER,
        customSubfolder TEXT,
        connections INTEGER,
        priority INTEGER,
        wifiOnly INTEGER,
        isEnabled INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_bandwidth (
        date TEXT PRIMARY KEY,
        bytesDownloaded INTEGER NOT NULL
      )
    ''');
  }

  // --- Downloads CRUD ---
  Future<void> insertTask(DownloadTask task) async {
    final db = await database;
    await db.insert(
      'downloads',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(DownloadTask task) async {
    final db = await database;
    await db.update(
      'downloads',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DownloadTask>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('downloads', orderBy: 'createdAt DESC');
    return maps.map((m) => DownloadTask.fromMap(m)).toList();
  }

  Future<DownloadTask?> getTaskById(String id) async {
    final db = await database;
    final maps = await db.query('downloads', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return DownloadTask.fromMap(maps.first);
    }
    return null;
  }

  // --- Daily Bandwidth Stats ---
  Future<void> addDownloadedBytesToday(int bytes) async {
    if (bytes <= 0) return;
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.rawInsert('''
      INSERT INTO daily_bandwidth (date, bytesDownloaded)
      VALUES (?, ?)
      ON CONFLICT(date) DO UPDATE SET bytesDownloaded = bytesDownloaded + ?
    ''', [today, bytes, bytes]);
  }

  Future<int> getTodayDownloadedBytes() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final res = await db.query('daily_bandwidth', where: 'date = ?', whereArgs: [today]);
    if (res.isNotEmpty) {
      return res.first['bytesDownloaded'] as int? ?? 0;
    }
    return 0;
  }

  // --- Site Profiles CRUD ---
  Future<void> saveSiteProfile(SiteProfile profile) async {
    final db = await database;
    await db.insert('site_profiles', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SiteProfile>> getAllSiteProfiles() async {
    final db = await database;
    final maps = await db.query('site_profiles');
    return maps.map((m) => SiteProfile.fromMap(m)).toList();
  }

  Future<void> deleteSiteProfile(String id) async {
    final db = await database;
    await db.delete('site_profiles', where: 'id = ?', whereArgs: [id]);
  }

  // --- Smart Rules CRUD ---
  Future<void> saveSmartRule(SmartRule rule) async {
    final db = await database;
    await db.insert('smart_rules', rule.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SmartRule>> getAllSmartRules() async {
    final db = await database;
    final maps = await db.query('smart_rules');
    return maps.map((m) => SmartRule.fromMap(m)).toList();
  }

  Future<void> deleteSmartRule(String id) async {
    final db = await database;
    await db.delete('smart_rules', where: 'id = ?', whereArgs: [id]);
  }
}
