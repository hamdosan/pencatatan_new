import 'package:flutter/material.dart';

const Map<String, IconData> categoryIcons = {
  'food': Icons.restaurant,
  'transport': Icons.directions_car,
  'qr': Icons.qr_code_2,
  'admin_fee': Icons.account_balance,
  'game': Icons.sports_esports,
  'education': Icons.school,
  'shopping': Icons.shopping_bag,
  'bill': Icons.receipt_long,
  'entertainment': Icons.movie,
  'health': Icons.favorite,
  'other': Icons.more_horiz,
};

IconData iconFor(String key) => categoryIcons[key] ?? Icons.category;
