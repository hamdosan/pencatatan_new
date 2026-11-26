import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import 'expense_form_page.dart';
import 'history_page.dart';
import 'theme/app_theme.dart';
import 'widgets/expense_tile.dart';
import 'widgets/glass.dart';
import 'widgets/formatters.dart';
import 'widgets/month_selector.dart';

/// Tab "Pencatatan": ringkasan + daftar pengeluaran bulan terpilih.
/// Scaffold (AppBar, FAB, navigasi) disediakan oleh MainShell.
class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  void _openForm(BuildContext context, {Expense? expense}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExpenseFormPage(expense: expense)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ExpenseController>();

    return Builder(builder: (_) {
      if (c.error != null) {
        return Center(child: Text(c.error!));
      }
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: MonthSelector(controller: c)),
          SliverToBoxAdapter(child: _SummaryCard(controller: c)),
          if (c.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (c.expenses.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Belum ada pengeluaran bulan ini')),
            )
          else
            SliverList.builder(
              itemCount: c.expenses.length,
              itemBuilder: (context, i) {
                final e = c.expenses[i];
                return ExpenseTile(
                  expense: e,
                  onTap: () => _openForm(context, expense: e),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});
  final ExpenseController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = controller.totalAmount;
    final breakdown = controller.totalByCategory;

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HistoryPage()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total pengeluaran',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: AppPalette.of(context).muted)),
          const SizedBox(height: 4),
          Text(
            formatRupiah(total),
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final entry in breakdown.take(4))
              _CategoryBar(
                controller: controller,
                categoryId: entry.key,
                amount: entry.value,
                total: total,
              ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Lihat riwayat bulan ini',
                  style: theme.textTheme.labelMedium),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.controller,
    required this.categoryId,
    required this.amount,
    required this.total,
  });

  final ExpenseController controller;
  final int categoryId;
  final int amount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cat = controller.categoryOf(categoryId);
    final color = Color(cat?.colorValue ?? 0xFF607D8B);
    final ratio = total == 0 ? 0.0 : amount / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cat?.name ?? '-'),
              Text(formatRupiah(amount)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: color,
              backgroundColor: AppPalette.of(context).glass,
            ),
          ),
        ],
      ),
    );
  }
}
