import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/theme_controller.dart';
import '../services/auto_update_checker.dart';
import 'dashboard_page.dart';
import 'expense_form_page.dart';
import 'history_page.dart';
import 'recap_page.dart';
import 'records_page.dart';
import 'theme/app_theme.dart';
import 'widgets/glass.dart';
import 'widgets/update_dialog.dart';

/// Kerangka utama: latar gradasi, judul besar, drawer menu, navigasi bawah
/// (Home / Pencatatan) dan tombol "Tambah".
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

  static const _titles = ['Dashboard', 'Pencatatan'];
  static const _tabs = ['Home', 'Pencatatan'];
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
    final text = Theme.of(context).textTheme;

    return PopScope(
      // Tombol back di tab Pencatatan kembali ke Dashboard dulu.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: AppBackground(
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          extendBody: true,
          onDrawerChanged: (open) => open ? _menu.forward() : _menu.reverse(),
          appBar: AppBar(
            toolbarHeight: 72,
            leading: IconButton(
              tooltip: 'Menu',
              onPressed: _toggleDrawer,
              icon: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _menuProgress,
              ),
            ),
            titleSpacing: 4,
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _titles[_index],
                key: ValueKey(_index),
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            actions: [
              GlassIconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: isDark ? 'Mode terang' : 'Mode gelap',
                onPressed: () =>
                    context.read<ThemeController>().toggle(brightness),
              ),
              const SizedBox(width: 12),
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
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _AddButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpenseFormPage()),
            ),
          ),
          bottomNavigationBar: _DotNavBar(
            labels: _tabs,
            selected: _index,
            onSelect: _select,
          ),
        ),
      ),
    );
  }
}

/// Tombol pil terang "Tambah Pengeluaran" (seperti "Send Money").
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    const navy = Color(0xFF17304F);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [p.panelTop, const Color(0xFFE3DDF7)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 24, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: navy.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.add, color: navy, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tambah Pengeluaran',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: navy,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigasi bawah berupa teks dengan titik di bawah tab aktif.
class _DotNavBar extends StatelessWidget {
  const _DotNavBar({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bgBottom.withValues(alpha: 0), p.bgBottom],
          stops: const [0, 0.45],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: (text.labelLarge ?? const TextStyle())
                              .copyWith(
                            color: i == selected
                                ? scheme.onSurface
                                : p.muted,
                            fontWeight: i == selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          child: Text(labels[i]),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == selected ? 5 : 0,
                          height: 5,
                          decoration: BoxDecoration(
                            color: scheme.onSurface,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
