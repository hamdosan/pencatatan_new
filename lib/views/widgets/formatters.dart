import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String formatRupiah(num value) => _rupiah.format(value);

String formatDate(DateTime d) => DateFormat('EEE, d MMM y', 'id_ID').format(d);

String formatMonth(DateTime d) => DateFormat('MMMM y', 'id_ID').format(d);

final _nonDigit = RegExp(r'\D');

/// Sisipkan titik pemisah ribuan pada deret angka, mis. 1000 -> 1.000.
String groupThousands(String digits) => digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+$)'),
      (_) => '.',
    );

/// Baca nominal berformat ribuan, mis. 1.000 -> 1000. Null jika tidak valid.
int? parseThousands(String? text) =>
    int.tryParse((text ?? '').replaceAll('.', ''));

/// Format input nominal dengan pemisah ribuan saat mengetik.
class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    var cursor = newValue.selection.end;
    if (cursor < 0 || cursor > text.length) cursor = text.length;

    final deletedSeparator = text.length < oldValue.text.length &&
        text.replaceAll(_nonDigit, '') ==
            oldValue.text.replaceAll(_nonDigit, '');
    if (deletedSeparator && cursor > 0) {
      text = text.replaceRange(cursor - 1, cursor, '');
      cursor--;
    }

    final digitsAfterCursor =
        text.substring(cursor).replaceAll(_nonDigit, '').length;
    final digits = text
        .replaceAll(_nonDigit, '')
        .replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = groupThousands(digits);

    var offset = formatted.length;
    var remaining = digitsAfterCursor;
    while (offset > 0 && remaining > 0) {
      offset--;
      if (formatted[offset] != '.') remaining--;
    }
    if (offset > 0 && formatted[offset - 1] == '.') offset--;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
