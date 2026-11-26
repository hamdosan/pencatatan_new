import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/expense.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'expense_tracker.db';
  static const _dbVersion = 3;

  static Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (final c in _v2Categories) {
        await db.insert(
          'categories',
          c.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    if (oldVersion < 3) {
      for (final c in _v3Categories) {
        await db.insert(
          'categories',
          c.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        name  TEXT    NOT NULL UNIQUE,
        icon  TEXT    NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT    NOT NULL,
        amount      INTEGER NOT NULL CHECK (amount > 0),
        category_id INTEGER NOT NULL,
        date        TEXT    NOT NULL,
        note        TEXT,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (category_id) REFERENCES categories (id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('CREATE INDEX idx_expenses_date ON expenses (date)');

    final batch = db.batch();
    for (final c in _defaultCategories) {
      batch.insert('categories', c.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  static const _defaultCategories = <Category>[
    Category(name: 'Makanan', icon: 'food', colorValue: 0xFFFF9800),
    Category(name: 'Transportasi', icon: 'transport', colorValue: 0xFF2196F3),
    ..._v2Categories,
    ..._v3Categories,
    Category(name: 'Belanja', icon: 'shopping', colorValue: 0xFFE91E63),
    Category(name: 'Tagihan', icon: 'bill', colorValue: 0xFFF44336),
    Category(name: 'Hiburan', icon: 'entertainment', colorValue: 0xFF9C27B0),
    Category(name: 'Kesehatan', icon: 'health', colorValue: 0xFF4CAF50),
    Category(name: 'Pendidikan', icon: 'education', colorValue: 0xFF3F51B5),
    Category(name: 'Lainnya', icon: 'other', colorValue: 0xFF607D8B),
  ];

  static const _v2Categories = <Category>[
    Category(name: 'QR', icon: 'qr', colorValue: 0xFF009688),
    Category(name: 'Biaya Admin', icon: 'admin_fee', colorValue: 0xFF795548),
  ];

  static const _v3Categories = <Category>[
    Category(name: 'Game', icon: 'game', colorValue: 0xFF00BCD4),
  ];

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'id ASC');
    return inDisplayOrder(rows.map(Category.fromMap));
  }

  static List<Category> inDisplayOrder(Iterable<Category> categories) {
    final rank = {
      for (var i = 0; i < _defaultCategories.length; i++)
        _defaultCategories[i].name: i,
    };
    final unknown = _defaultCategories.length;
    final indexed = categories.indexed.toList()
      ..sort((a, b) {
        final byRank = (rank[a.$2.name] ?? unknown)
            .compareTo(rank[b.$2.name] ?? unknown);
        return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
      });
    return [for (final (_, category) in indexed) category];
  }

  Future<List<Expense>> getExpensesByMonth(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1);
    final next = DateTime(year, month + 1, 1);
    final rows = await db.query(
      'expenses',
      where: 'date >= ? AND date < ?',
      whereArgs: [Expense.dateToDb(start), Expense.dateToDb(next)],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  /// Total pengeluaran per bulan dalam rentang [from] (inklusif) sampai
  /// [to] (eksklusif). Kunci map: 'yyyy-MM'.
  Future<Map<String, int>> getMonthlyTotals(DateTime from, DateTime to) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT substr(date, 1, 7) AS ym, SUM(amount) AS total FROM expenses '
      'WHERE date >= ? AND date < ? GROUP BY ym',
      [Expense.dateToDb(from), Expense.dateToDb(to)],
    );
    return {
      for (final r in rows) r['ym'] as String: (r['total'] as num).toInt(),
    };
  }

  /// Jumlah transaksi per bulan dalam rentang [from] (inklusif) sampai
  /// [to] (eksklusif). Kunci map: 'yyyy-MM'.
  Future<Map<String, int>> getMonthlyCounts(DateTime from, DateTime to) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT substr(date, 1, 7) AS ym, COUNT(*) AS n FROM expenses '
      'WHERE date >= ? AND date < ? GROUP BY ym',
      [Expense.dateToDb(from), Expense.dateToDb(to)],
    );
    return {for (final r in rows) r['ym'] as String: (r['n'] as num).toInt()};
  }

  /// Semua pengeluaran dalam rentang [from] (inklusif) sampai [to]
  /// (eksklusif), urut tanggal naik.
  Future<List<Expense>> getExpensesInRange(DateTime from, DateTime to) async {
    final db = await database;
    final rows = await db.query(
      'expenses',
      where: 'date >= ? AND date < ?',
      whereArgs: [Expense.dateToDb(from), Expense.dateToDb(to)],
      orderBy: 'date ASC, id ASC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insertExpense(Expense e) async {
    final db = await database;
    return db.insert('expenses', e.toMap()..remove('id'));
  }

  Future<int> updateExpense(Expense e) async {
    final db = await database;
    return db.update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
