import 'package:catatan_keuangan/controllers/transaction_controller.dart';
import 'package:catatan_keuangan/models/transaction_model.dart';
import 'package:catatan_keuangan/models/transaction_repository.dart';
import 'package:catatan_keuangan/models/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TransactionController controller;
  final now = DateTime.now();

  TransactionModel make(
    String id,
    double amount,
    TransactionType type,
    String categoryId,
  ) =>
      TransactionModel(
        id: id,
        title: id,
        amount: amount,
        type: type,
        categoryId: categoryId,
        date: now,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    controller = TransactionController(TransactionRepository());
    await controller.load();
  });

  test('menghitung saldo dan ringkasan bulanan', () async {
    await controller.add(make('gaji', 5000000, TransactionType.income, 'salary'));
    await controller.add(make('makan', 50000, TransactionType.expense, 'food'));
    await controller.add(make('ojek', 25000, TransactionType.expense, 'transport'));

    expect(controller.totalBalance, 4925000);

    final summary = controller.summaryForMonth(DateTime(now.year, now.month));
    expect(summary.income, 5000000);
    expect(summary.expense, 75000);
    expect(summary.transactionCount, 3);

    final categories = controller.categorySummaries(
      month: DateTime(now.year, now.month),
      type: TransactionType.expense,
    );
    expect(categories.first.category.id, 'food');
    expect(categories.first.percentage, closeTo(2 / 3, 0.001));
  });

  test('hapus lalu pulihkan transaksi', () async {
    await controller.add(make('a', 10000, TransactionType.expense, 'food'));

    final removed = controller.delete('a');
    expect(removed, isNotNull);
    expect(controller.isEmpty, isTrue);

    await controller.restore(removed!);
    expect(controller.transactions.single.id, 'a');
  });

  test('filter dan pencarian', () async {
    await controller.add(make('Gaji Oktober', 1, TransactionType.income, 'salary'));
    await controller.add(make('Kopi', 1, TransactionType.expense, 'food'));

    controller.setFilter(TransactionFilter.income);
    expect(controller.filteredTransactions.map((t) => t.id), ['Gaji Oktober']);

    controller
      ..setFilter(TransactionFilter.all)
      ..setSearchQuery('makan'); // cocok dengan nama kategori "Makanan"
    expect(controller.filteredTransactions.map((t) => t.id), ['Kopi']);
  });

  test('data tersimpan dan dimuat ulang', () async {
    await controller.add(make('x', 20000, TransactionType.expense, 'bills'));

    final reloaded = TransactionController(TransactionRepository());
    await reloaded.load();
    expect(reloaded.transactions.single.amount, 20000);
  });
}
