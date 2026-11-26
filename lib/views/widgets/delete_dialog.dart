import 'package:flutter/material.dart';

/// Minta konfirmasi sebelum menghapus pengeluaran berjudul [title].
Future<bool> confirmDeleteExpense(BuildContext context, String title) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus pengeluaran?'),
          content: Text('"$title" akan dihapus permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ) ??
      false;
}
