import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/expense_controller.dart';
import '../services/excel_export_service.dart';
import 'history_page.dart';
import 'widgets/formatters.dart';
import 'widgets/month_selector.dart' show kFirstYear;

/// Rekap pencatatan per bulan dalam satu tahun.
class RecapPage extends StatefulWidget {
  const RecapPage({super.key});

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
  late int _year;
  late Future<List<MonthRecap>> _future;
  late ExpenseController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<ExpenseController>();
    _year = _controller.selectedMonth.year;
    _controller.addListener(_reload);
    _load();
  }

  @override
  void dispose() {
    _controller.removeListener(_reload);
    super.dispose();
  }

  void _load() => _future = _controller.recapOfYear(_year);

  /// Muat ulang saat data berubah (mis. setelah edit di halaman riwayat).
  void _reload() {
    if (mounted) setState(_load);
  }

  void _changeYear(int delta) => setState(() {
        _year += delta;
        _load();
      });

  Future<void> _openMonth(DateTime month) async {
    await _controller.selectMonth(month.year, month.month);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
  }

  bool _exporting = false;

  /// Tampilkan pilihan bulan, lalu ekspor bulan yang dipilih.
  Future<void> _chooseMonthsAndDownload() async {
    final recaps = await _future;
    if (!mounted) return;
    final now = DateTime.now();
    final available = [
      for (final r in recaps)
        if (!r.month.isAfter(DateTime(now.year, now.month))) r,
    ];
    final selected = _controller.selectedMonth;
    final months = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MonthExportSheet(
        year: _year,
        recaps: available,
        initial: {
          if (selected.year == _year &&
              available.any((r) => r.month.month == selected.month && r.count > 0))
            selected.month,
        },
      ),
    );
    if (months != null && months.isNotEmpty) await _downloadExcel(months);
  }

  Future<void> _downloadExcel(Set<int> months) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final recaps = await _controller.recapOfYear(_year);
      final expenses = await _controller.expensesOfYear(_year);
      final bytes = ExcelExportService.build(
        year: _year,
        months: months,
        recaps: recaps,
        expenses: expenses,
        categoryOf: _controller.categoryOf,
      );
      final name = ExcelExportService.fileName(_year, months);
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Simpan rekap Excel',
        fileName: name,
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (uri != null) {
        messenger.showSnackBar(SnackBar(content: Text('$name tersimpan')));
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal membuat Excel: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Bulanan'),
        actions: [
          _exporting
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Download Excel',
                  onPressed: _chooseMonthsAndDownload,
                ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Tahun sebelumnya',
                  onPressed: _year <= kFirstYear ? null : () => _changeYear(-1),
                ),
                Text('$_year', style: theme.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Tahun berikutnya',
                  onPressed: _year >= now.year ? null : () => _changeYear(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MonthRecap>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Gagal memuat rekap: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Bulan di masa depan tidak ditampilkan.
                final months = [
                  for (final r in snap.data!)
                    if (!r.month.isAfter(DateTime(now.year, now.month))) r,
                ].reversed.toList();
                final yearTotal = months.fold(0, (s, r) => s + r.total);
                final yearCount = months.fold(0, (s, r) => s + r.count);
                final maxTotal = months.fold(0, (m, r) => r.total > m ? r.total : m);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total tahun $_year',
                                style: theme.textTheme.labelLarge),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(yearTotal),
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('$yearCount transaksi',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final r in months)
                      _MonthRecapTile(
                        recap: r,
                        maxTotal: maxTotal,
                        onTap: r.count == 0 ? null : () => _openMonth(r.month),
                        onDownload: r.count == 0 || _exporting
                            ? null
                            : () => _downloadExcel({r.month.month}),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthRecapTile extends StatelessWidget {
  const _MonthRecapTile({
    required this.recap,
    required this.maxTotal,
    this.onTap,
    this.onDownload,
  });

  final MonthRecap recap;
  final int maxTotal;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final change = recap.changePercent;
    final ratio = maxTotal == 0 ? 0.0 : recap.total / maxTotal;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(formatMonth(recap.month),
                              style: theme.textTheme.titleSmall),
                        ),
                        Text(
                          formatRupiah(recap.total),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recap.count == 0
                                ? 'Belum ada catatan'
                                : '${recap.count} transaksi',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        if (change != null && recap.total > 0)
                          Text(
                            '${change >= 0 ? '▲' : '▼'} '
                            '${change.abs().toStringAsFixed(0)}% vs bln lalu',
                            style: theme.textTheme.bodySmall?.copyWith(
                              // Pengeluaran naik = merah, turun = hijau.
                              color: change > 0
                                  ? scheme.error
                                  : Colors.green.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDownload != null)
                IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: 'Download Excel ${formatMonth(recap.month)}',
                  onPressed: onDownload,
                )
              else
                const SizedBox(width: 48),
              Icon(
                Icons.chevron_right,
                color: onTap == null ? scheme.outlineVariant : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Bottom sheet pilih bulan yang akan diekspor ke Excel.
class _MonthExportSheet extends StatefulWidget {
  const _MonthExportSheet({
    required this.year,
    required this.recaps,
    required this.initial,
  });

  final int year;

  /// Bulan yang sudah lewat/berjalan pada [year], urut Jan -> Des.
  final List<MonthRecap> recaps;
  final Set<int> initial;

  @override
  State<_MonthExportSheet> createState() => _MonthExportSheetState();
}

class _MonthExportSheetState extends State<_MonthExportSheet> {
  late final Set<int> _selected = {...widget.initial};

  List<int> get _withData => [
        for (final r in widget.recaps)
          if (r.count > 0) r.month.month,
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withData = _withData;
    final allSelected =
        withData.isNotEmpty && withData.every(_selected.contains);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Pilih bulan untuk diunduh (${widget.year})',
                  style: theme.textTheme.titleMedium),
            ),
            CheckboxListTile(
              title: const Text('Pilih semua'),
              value: allSelected,
              onChanged: withData.isEmpty
                  ? null
                  : (v) => setState(() {
                        v == true
                            ? _selected.addAll(withData)
                            : _selected.clear();
                      }),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final r in widget.recaps)
                    CheckboxListTile(
                      title: Text(formatMonth(r.month)),
                      subtitle: Text(r.count == 0
                          ? 'Belum ada catatan'
                          : '${r.count} transaksi · ${formatRupiah(r.total)}'),
                      value: _selected.contains(r.month.month),
                      onChanged: r.count == 0
                          ? null
                          : (v) => setState(() {
                                v == true
                                    ? _selected.add(r.month.month)
                                    : _selected.remove(r.month.month);
                              }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, _selected),
                icon: const Icon(Icons.download),
                label: Text(_selected.isEmpty
                    ? 'Pilih minimal 1 bulan'
                    : 'Download ${_selected.length} bulan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}