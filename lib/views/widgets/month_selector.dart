import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/expense_controller.dart';
import '../theme/app_theme.dart';

/// Tahun paling awal yang bisa dipilih.
const kFirstYear = 2000;

/// Navigasi bulan. Tap nama bulan untuk memilih bulan,
/// tap tahun untuk memilih tahun.
class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key, required this.controller});
  final ExpenseController controller;

  Future<void> _pickMonth(BuildContext context) async {
    final selected = controller.selectedMonth;
    final month = await showDialog<int>(
      context: context,
      builder: (_) => _MonthPickerDialog(
        year: selected.year,
        selectedMonth: selected.month,
      ),
    );
    if (month != null) await controller.selectMonth(selected.year, month);
  }

  Future<void> _pickYear(BuildContext context) async {
    final selected = controller.selectedMonth;
    final year = await showDialog<int>(
      context: context,
      builder: (_) => _YearPickerDialog(selectedYear: selected.year),
    );
    if (year != null) await controller.selectMonth(year, selected.month);
  }

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedMonth;
    final style = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.w600);

    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Bulan sebelumnya',
            onPressed: selected.year <= kFirstYear && selected.month == 1
                ? null
                : () => controller.changeMonth(-1),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PickerChip(
                label: DateFormat('MMMM', 'id_ID').format(selected),
                tooltip: 'Pilih bulan',
                style: style,
                onTap: () => _pickMonth(context),
              ),
              _PickerChip(
                label: '${selected.year}',
                tooltip: 'Pilih tahun',
                style: style,
                onTap: () => _pickYear(context),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Bulan berikutnya',
            onPressed:
                controller.isCurrentMonth ? null : () => controller.changeMonth(1),
          ),
        ],
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.style,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: style),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid 12 bulan pada [year]. Bulan di masa depan tidak bisa dipilih.
class _MonthPickerDialog extends StatelessWidget {
  const _MonthPickerDialog({required this.year, required this.selectedMonth});

  final int year;
  final int selectedMonth;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text('Pilih bulan ($year)'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: 320,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          childAspectRatio: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (var m = 1; m <= 12; m++)
              () {
                final enabled = DateTime(year, m)
                    .isBefore(DateTime(now.year, now.month + 1));
                final isSelected = m == selectedMonth;
                final label =
                    DateFormat('MMM', 'id_ID').format(DateTime(year, m));
                return isSelected
                    ? FilledButton(
                        onPressed: () => Navigator.pop(context, m),
                        child: Text(label),
                      )
                    : OutlinedButton(
                        onPressed:
                            enabled ? () => Navigator.pop(context, m) : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        child: Text(label),
                      );
              }(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

class _YearPickerDialog extends StatelessWidget {
  const _YearPickerDialog({required this.selectedYear});
  final int selectedYear;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AlertDialog(
      title: const Text('Pilih tahun'),
      contentPadding: const EdgeInsets.only(top: 16),
      content: SizedBox(
        width: 320,
        height: 320,
        child: YearPicker(
          firstDate: DateTime(kFirstYear),
          lastDate: DateTime(now.year),
          selectedDate: DateTime(selectedYear),
          onChanged: (d) => Navigator.pop(context, d.year),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
