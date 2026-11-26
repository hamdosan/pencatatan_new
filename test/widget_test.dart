import 'package:catatan_keuangan/app.dart';
import 'package:catatan_keuangan/controllers/settings_controller.dart';
import 'package:catatan_keuangan/controllers/transaction_controller.dart';
import 'package:catatan_keuangan/models/settings_repository.dart';
import 'package:catatan_keuangan/models/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  await initializeDateFormatting('id_ID');
  final transactions = TransactionController(TransactionRepository());
  final settings = SettingsController(SettingsRepository());
  await transactions.load();
  await settings.load();
  await transactions.loadSampleData();

  await tester.pumpWidget(CatatanKeuanganApp(
    transactionController: transactions,
    settingsController: settings,
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ponsel: memakai NavigationBar', (tester) async {
    await _pumpApp(tester, const Size(390, 844));

    expect(find.text('Total Saldo'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('tablet: memakai NavigationRail', (tester) async {
    await _pumpApp(tester, const Size(800, 1100));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('desktop: tata letak lebar tanpa overflow', (tester) async {
    await _pumpApp(tester, const Size(1400, 900));

    expect(find.text('Transaksi Baru'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
