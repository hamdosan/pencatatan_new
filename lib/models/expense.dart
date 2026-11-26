/// Model pengeluaran.
class Expense {
  final int? id;
  final String title;

  /// Nominal dalam Rupiah (bilangan bulat).
  final int amount;
  final int categoryId;
  final DateTime date;
  final String? note;

  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
  });

  Expense copyWith({
    int? id,
    String? title,
    int? amount,
    int? categoryId,
    DateTime? date,
    String? note,
  }) =>
      Expense(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        categoryId: categoryId ?? this.categoryId,
        date: date ?? this.date,
        note: note ?? this.note,
      );

  /// Tanggal disimpan sebagai teks 'yyyy-MM-dd' agar mudah difilter per bulan.
  static String dateToDb(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category_id': categoryId,
        'date': dateToDb(date),
        'note': note,
      };

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        id: map['id'] as int?,
        title: map['title'] as String,
        amount: map['amount'] as int,
        categoryId: map['category_id'] as int,
        date: DateTime.parse(map['date'] as String),
        note: map['note'] as String?,
      );
}
