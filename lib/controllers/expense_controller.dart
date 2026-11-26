import 'package:flutter/foundation.dart' hide Category;

import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../services/reminder_service.dart';

/// Ringkasan satu bulan untuk halaman rekap.
class MonthRecap {
  const MonthRecap({
    required this.month,
    required this.total,
    required this.count,
    required this.previousTotal,
  });

  final DateTime month;
  final int total;
  final int count;
  final int previousTotal;

  /// Persentase perubahan dibanding bulan sebelumnya. Null jika tidak bisa
  /// dibandingkan (bulan sebelumnya kosong).
  double? get changePercent =>
      previousTotal == 0 ? null : (total - previousTotal) * 100 / previousTotal;
}

class ExpenseController extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Expense> _expenses = [];
  List<Category> _categories = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  String? _error;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Category> get categories => List.unmodifiable(_categories);
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _loading;
  String? get error => _error;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  /// Pengeluaran bulan terpilih yang punya lokasi, terbaru lebih dulu.
  List<Expense> get locationHistory =>
      _expenses.where((e) => e.hasLocation).toList();

  int get totalAmount => _expenses.fold(0, (sum, e) => sum + e.amount);

  List<MapEntry<int, int>> get totalByCategory {
    final map = <int, int>{};
    for (final e in _expenses) {
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amount;
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  /// Total per tanggal pada bulan terpilih. Index 0 = tanggal 1.
  List<int> get dailyTotals {
    final days =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final list = List<int>.filled(days, 0);
    for (final e in _expenses) {
      list[e.date.day - 1] += e.amount;
    }
    return list;
  }

  /// Tren total 6 bulan terakhir, berakhir di bulan terpilih.
  List<(DateTime, int)> get monthlyTrend => List.unmodifiable(_trend);
  List<(DateTime, int)> _trend = [];

  static const trendMonths = 6;

  Future<void> _loadTrend() async {
    final from = DateTime(
        _selectedMonth.year, _selectedMonth.month - (trendMonths - 1));
    final to = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final totals = await _db.getMonthlyTotals(from, to);
    _trend = [
      for (var i = 0; i < trendMonths; i++)
        () {
          final m = DateTime(from.year, from.month + i);
          final key =
              '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';
          return (m, totals[key] ?? 0);
        }(),
    ];
  }

  /// Rekap 12 bulan pada [year]: total, jumlah transaksi, dan total bulan
  /// sebelumnya (untuk perbandingan; Januari dibanding Desember tahun lalu).
  Future<List<MonthRecap>> recapOfYear(int year) async {
    final from = DateTime(year - 1, 12);
    final to = DateTime(year + 1);
    final totals = await _db.getMonthlyTotals(from, to);
    final counts = await _db.getMonthlyCounts(from, to);
    String key(DateTime m) =>
        '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';
    return [
      for (var m = 1; m <= 12; m++)
        MonthRecap(
          month: DateTime(year, m),
          total: totals[key(DateTime(year, m))] ?? 0,
          count: counts[key(DateTime(year, m))] ?? 0,
          previousTotal: totals[key(DateTime(year, m - 1))] ?? 0,
        ),
    ];
  }

  /// Semua pengeluaran pada [year], urut tanggal naik.
  Future<List<Expense>> expensesOfYear(int year) =>
      _db.getExpensesInRange(DateTime(year), DateTime(year + 1));

  Category? categoryOf(int id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> init() async {
    try {
      _categories = await _db.getCategories();
      await loadExpenses();
    } catch (e) {
      _error = 'Gagal memuat data: $e';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpenses() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _expenses = await _db.getExpensesByMonth(
        _selectedMonth.year,
        _selectedMonth.month,
      );
      await _loadTrend();
    } catch (e) {
      _error = 'Gagal memuat pengeluaran: $e';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> changeMonth(int delta) async {
    final target = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    final now = DateTime.now();
    if (target.isAfter(DateTime(now.year, now.month))) return;
    _selectedMonth = target;
    await loadExpenses();
  }

  /// Pilih bulan tertentu. Bulan di masa depan dibatasi ke bulan ini.
  Future<void> selectMonth(int year, int month) async {
    final now = DateTime.now();
    var target = DateTime(year, month);
    final current = DateTime(now.year, now.month);
    if (target.isAfter(current)) target = current;
    if (target == _selectedMonth) return;
    _selectedMonth = target;
    await loadExpenses();
  }

  Future<void> addExpense(Expense expense) async {
    await _db.insertExpense(expense);
    await ReminderService.instance.markExpenseInput();
    await loadExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await _db.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _db.deleteExpense(id);
    await loadExpenses();
  }
}
