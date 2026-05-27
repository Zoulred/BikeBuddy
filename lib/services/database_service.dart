import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bike.dart';
import '../models/ride.dart';
import '../models/maintenance_record.dart';
import '../models/goal.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bikebuddy_ph.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // Bikes table
    await db.execute('''
      CREATE TABLE bikes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type INTEGER,
        imagePath TEXT,
        purchaseDate TEXT,
        totalKilometers REAL,
        maintenanceStatus TEXT
      )
    ''');

    // Rides table
    await db.execute('''
      CREATE TABLE rides(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bikeId INTEGER,
        title TEXT,
        route TEXT,
        distance REAL,
        duration INTEGER,
        averageSpeed REAL,
        maxSpeed REAL,
        elevation REAL,
        calories INTEGER,
        dateTime TEXT,
        weather TEXT,
        FOREIGN KEY (bikeId) REFERENCES bikes (id) ON DELETE CASCADE
      )
    ''');

    // Maintenance table
    await db.execute('''
      CREATE TABLE maintenance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bikeId INTEGER,
        type TEXT,
        date TEXT,
        description TEXT,
        nextServiceDate TEXT,
        FOREIGN KEY (bikeId) REFERENCES bikes (id) ON DELETE CASCADE
      )
    ''');

    // Goals table
    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER,
        target REAL,
        current REAL,
        startDate TEXT,
        endDate TEXT
      )
    ''');
  }

  // --- Bike Operations ---
  Future<int> insertBike(Bike bike) async {
    final db = await database;
    return await db.insert('bikes', bike.toMap());
  }

  Future<List<Bike>> getBikes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('bikes');
    return List.generate(maps.length, (i) => Bike.fromMap(maps[i]));
  }

  Future<int> updateBike(Bike bike) async {
    final db = await database;
    return await db.update(
      'bikes',
      bike.toMap(),
      where: 'id = ?',
      whereArgs: [bike.id],
    );
  }

  Future<int> deleteBike(int id) async {
    final db = await database;
    return await db.delete('bikes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Ride Operations ---
  Future<int> insertRide(Ride ride) async {
    final db = await database;
    return await db.insert('rides', ride.toMap());
  }

  Future<List<Ride>> getRides() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rides',
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) => Ride.fromMap(maps[i]));
  }

  // --- Maintenance Operations ---
  Future<int> insertMaintenance(MaintenanceRecord record) async {
    final db = await database;
    return await db.insert('maintenance', record.toMap());
  }

  Future<List<MaintenanceRecord>> getMaintenanceForBike(int bikeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'maintenance',
      where: 'bikeId = ?',
      whereArgs: [bikeId],
    );
    return List.generate(
      maps.length,
      (i) => MaintenanceRecord.fromMap(maps[i]),
    );
  }

  // --- Goal Operations ---
  Future<int> insertGoal(Goal goal) async {
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  Future<List<Goal>> getGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('goals');
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }
}
