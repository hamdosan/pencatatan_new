import 'package:flutter_test/flutter_test.dart';

import 'package:catatan_keuangan/models/category.dart';
import 'package:catatan_keuangan/models/expense.dart';

void main() {
  test('Expense toMap/fromMap round-trip', () {
    final expense = Expense(
      id: 1,
      title: 'Makan siang',
      amount: 25000,
      categoryId: 2,
      date: DateTime(2026, 3, 7),
      note: 'Nasi padang',
    );

    final map = expense.toMap();
    expect(map['date'], '2026-03-07');

    final restored = Expense.fromMap(map);
    expect(restored.id, 1);
    expect(restored.title, 'Makan siang');
    expect(restored.amount, 25000);
    expect(restored.categoryId, 2);
    expect(restored.date, DateTime(2026, 3, 7));
    expect(restored.note, 'Nasi padang');
  });

  test('Category toMap/fromMap round-trip', () {
    const category = Category(
      id: 3,
      name: 'Transport',
      icon: 'transport',
      colorValue: 0xFF2196F3,
    );

    final restored = Category.fromMap(category.toMap());
    expect(restored.id, 3);
    expect(restored.name, 'Transport');
    expect(restored.icon, 'transport');
    expect(restored.colorValue, 0xFF2196F3);
  });
}
