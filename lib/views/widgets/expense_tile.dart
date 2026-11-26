import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/expense_controller.dart';
import '../../models/expense.dart';
import '../theme/app_theme.dart';
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
    final p = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Dismissible(
        key: ValueKey('expense_${expense.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: radius,
          ),
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
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: p.glass,
              borderRadius: radius,
              border: Border.all(color: p.glassBorder),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconFor(cat?.icon ?? 'other'),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${cat?.name ?? '-'} • ${formatDate(expense.date)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall?.copyWith(
                                    color: p.muted,
                                  ),
                                ),
                              ),
                              if (expense.hasLocation) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.place, size: 13, color: p.muted),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatRupiah(expense.amount),
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
