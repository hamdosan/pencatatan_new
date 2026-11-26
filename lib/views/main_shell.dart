import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/theme_controller.dart';
import '../services/auto_update_checker.dart';
import 'dashboard_page.dart';
import 'expense_form_page.dart';
import 'history_page.dart';
import 'recap_page.dart';
import 'widgets/update_dialog.dart';
import 'records_page.dart';

/// Kerangka utama: AppBar dengan tombol hamburger beranimasi, drawer menu,
/// dan navigasi bawah (Home / Pencatatan).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final AnimationController _menu = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _menuProgress = CurvedAnimation(
    parent: _menu,
    curve: Curves.easeInOutCubic,
  );

  int _index = 0;

  static const _titles = ['Dashboard', 'Catatan Pengeluaran'];
  static const _pages = [DashboardPage(), RecordsPage()];

  @override
  void initState() {
    super.initState();
    // Cek update otomatis setelah layar pertama tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AutoUpdateChecker.run(context);
    });
  }

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    final scaffold = _scaffoldKey.currentState!;
    if (scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    } else {
      // Mulai animasi ikon langsung saat ditekan agar terasa responsif.
      _menu.forward();
      scaffold.openDrawer();
    }
  }

  void _select(int i) {
    if (i != _index) setState(() => _index = i);
  }

  void _onDrawerSelect(int i) {
    _scaffoldKey.currentState!.closeDrawer();
    if (i < _pages.length) {
      _select(i);
    } else if (i == _pages.length) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HistoryPage()),
      );
    } else if (i == _pages.length + 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RecapPage()),
      );
    } else {
      showUpdateDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return PopScope(
      // Tombol back di tab Pencatatan kembali ke Dashboard dulu.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        onDrawerChanged: (open) => open ? _menu.forward() : _menu.reverse(),
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Menu',
            onPressed: _toggleDrawer,
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _menuProgress,
            ),
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(_titles[_index], key: ValueKey(_index)),
          ),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              tooltip: isDark ? 'Mode terang' : 'Mode gelap',
              onPressed: () =>
                  context.read<ThemeController>().toggle(brightness),
            ),
          ],
        ),
        drawer: NavigationDrawer(
          selectedIndex: _index,
          onDestinationSelected: _onDrawerSelect,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
              child: Text(
                'Catatan Pengeluaran',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: Text('Pencatatan'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.history),
              label: Text('Riwayat'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.calendar_view_month_outlined),
              selectedIcon: Icon(Icons.calendar_view_month),
              label: Text('Rekap Bulanan'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Divider(),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.system_update_outlined),
              selectedIcon: Icon(Icons.system_update),
              label: Text('Cek Update'),
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExpenseFormPage()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Pencatatan',
            ),
          ],
        ),
      ),
    );
  }
}
