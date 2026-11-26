import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../services/location_service.dart';
import 'widgets/category_dropdown.dart';
import 'widgets/delete_dialog.dart';
import 'widgets/formatters.dart';
import 'widgets/glass.dart';

/// Form tambah / ubah pengeluaran. [expense] null = mode tambah.
class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({super.key, this.expense});
  final Expense? expense;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  int? _categoryId;
  late DateTime _date;
  bool _saving = false;
  double? _lat;
  double? _lng;
  String? _address;
  bool _locating = false;

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
      text: e == null ? '' : groupThousands(e.amount.toString()),
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _categoryId = e?.categoryId;
    _date = e?.date ?? DateTime.now();
    _lat = e?.latitude;
    _lng = e?.longitude;
    _address = e?.address;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickLocation() async {
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final loc = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _lat = loc.latitude;
        _lng = loc.longitude;
        _address = loc.address;
      });
    } on LocationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mengambil lokasi: $e')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _clearLocation() => setState(() {
        _lat = null;
        _lng = null;
        _address = null;
      });

  Widget _buildLocationField(BuildContext context) {
    final hasLocation = _lat != null && _lng != null;
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Lokasi (opsional)',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLocation) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_address ?? 'Alamat tidak diketahui'),
                      Text(
                        LocationService.formatCoordinates(_lat!, _lng!),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _locating || _saving ? null : _pickLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_locating
                    ? 'Mencari lokasi...'
                    : hasLocation
                        ? 'Perbarui lokasi'
                        : 'Ambil lokasi saat ini'),
              ),
              if (hasLocation) ...[
                TextButton.icon(
                  onPressed: () =>
                      LocationService.instance.openInMaps(_lat!, _lng!),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Peta'),
                ),
                TextButton.icon(
                  onPressed: _locating ? null : _clearLocation,
                  icon: const Icon(Icons.close),
                  label: const Text('Hapus'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final controller = context.read<ExpenseController>();
    final note = _noteCtrl.text.trim();
    final expense = Expense(
      id: widget.expense?.id,
      title: _titleCtrl.text.trim(),
      amount: parseThousands(_amountCtrl.text)!,
      categoryId: _categoryId!,
      date: _date,
      note: note.isEmpty ? null : note,
      latitude: _lat,
      longitude: _lng,
      address: _lat == null ? null : _address,
    );

    if (_isEdit) {
      await controller.updateExpense(expense);
    } else {
      await controller.addExpense(expense);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final expense = widget.expense!;
    final confirmed = await confirmDeleteExpense(context, expense.title);
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await context.read<ExpenseController>().deleteExpense(expense.id!);
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Pengeluaran dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.read<ExpenseController>().categories;

    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Pengeluaran' : 'Tambah Pengeluaran'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus',
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: const [ThousandsInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  final n = parseThousands(v);
                  if (n == null || n <= 0) {
                    return 'Masukkan nominal lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CategoryDropdown(
                categories: categories,
                value: _categoryId,
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(formatDate(_date)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              _buildLocationField(context),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
