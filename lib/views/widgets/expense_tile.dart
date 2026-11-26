import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/expense_controller.dart';
import '../../models/expense.dart';
import 'category_icons.dart';
import 'delete_dialog.dart';
import 'formatters.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, required this.onTap});
  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ExpenseController>();
    final cat = controller.categoryOf(expense.categoryId);
    final color = Color(cat?.colorValue ?? 0xFF607D8B);

    return Dismissible(
      key: ValueKey('expense_${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => confirmDeleteExpense(context, expense.title),
      onDismissed: (_) {
        controller.deleteExpense(expense.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengeluaran dihapus')),
        );
      },
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(iconFor(cat?.icon ?? 'other'), color: color),
        ),
        title: Text(expense.title),
        subtitle: Text('${cat?.name ?? '-'} • ${formatDate(expense.date)}'),
        trailing: Text(
          formatRupiah(expense.amount),
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
