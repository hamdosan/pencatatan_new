import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../../services/update_service.dart';

/// Tampilkan dialog cek & pasang update.
///
/// Jika [release] diberikan (dari cek otomatis), dialog langsung menawarkan
/// update dan menampilkan tombol "Lewati versi ini". Mengembalikan `true`
/// jika user memilih melewati versi tersebut.
Future<bool?> showUpdateDialog(
  BuildContext context, {
  AppRelease? release,
  String? currentVersion,
}) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDialog(
        initialRelease: release,
        currentVersion: currentVersion,
      ),
    );

enum _Stage { checking, upToDate, available, downloading, installing, error }

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({this.initialRelease, this.currentVersion});

  final AppRelease? initialRelease;
  final String? currentVersion;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  final _service = UpdateService();
  _Stage _stage = _Stage.checking;
  String _current = '';
  AppRelease? _release;
  String? _error;
  double? _progress;
  StreamSubscription<OtaEvent>? _sub;

  bool get _isAuto => widget.initialRelease != null;

  @override
  void initState() {
    super.initState();
    if (_isAuto) {
      _release = widget.initialRelease;
      _current = widget.currentVersion ?? '';
      _stage = _Stage.available;
    } else {
      _check();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _stage = _Stage.checking;
      _error = null;
    });
    try {
      _current = await UpdateService.currentVersion();
      final latest = await _service.fetchLatest();
      if (!mounted) return;
      setState(() {
        _release = latest;
        _stage = UpdateService.isNewer(latest.version, _current)
            ? _Stage.available
            : _Stage.upToDate;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _stage = _Stage.error;
      });
    }
  }

  void _install() {
    setState(() {
      _stage = _Stage.downloading;
      _progress = null;
    });
    _sub = _service.install(_release!).listen(
      (event) {
        if (!mounted) return;
        setState(() {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final p = double.tryParse(event.value ?? '');
              _progress = p == null ? null : p / 100;
            case OtaStatus.INSTALLING:
            case OtaStatus.INSTALLATION_DONE:
              _stage = _Stage.installing;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              _error = 'Izin "Instal aplikasi tidak dikenal" belum diberikan. '
                  'Aktifkan di pengaturan lalu coba lagi.';
              _stage = _Stage.error;
            case OtaStatus.CANCELED:
              _stage = _Stage.available;
            default:
              _error = 'Gagal update: ${event.status.name} ${event.value ?? ''}';
              _stage = _Stage.error;
          }
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _error = 'Gagal update: $e';
          _stage = _Stage.error;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _stage == _Stage.checking || _stage == _Stage.downloading;

    final Widget content = switch (_stage) {
      _Stage.checking => const _Busy(text: 'Mengecek versi terbaru...'),
      _Stage.upToDate => Text('Aplikasi sudah versi terbaru ($_current).'),
      _Stage.available => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versi baru tersedia: ${_release!.version}\n'
                'Versi terpasang: $_current'),
            if (_release!.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Perubahan:', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(child: Text(_release!.notes)),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Data catatan tidak akan hilang.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      _Stage.downloading => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_progress == null
                ? 'Mengunduh...'
                : 'Mengunduh ${(_progress! * 100).round()}%'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress),
          ],
        ),
      _Stage.installing =>
        const Text('Unduhan selesai. Ikuti layar pemasangan Android.'),
      _Stage.error => Text(_error ?? 'Terjadi kesalahan.'),
    };

    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: const Text('Update Aplikasi'),
        content: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: content,
        ),
        actions: [
          if (_isAuto && _stage == _Stage.available)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lewati versi ini'),
            ),
          if (!busy)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_stage == _Stage.available ? 'Nanti' : 'Tutup'),
            ),
          if (_stage == _Stage.error)
            FilledButton(onPressed: _check, child: const Text('Coba lagi')),
          if (_stage == _Stage.available)
            FilledButton.icon(
              onPressed: _install,
              icon: const Icon(Icons.system_update),
              label: const Text('Update'),
            ),
        ],
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      );
}
