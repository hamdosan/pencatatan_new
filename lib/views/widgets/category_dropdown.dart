import 'package:flutter/material.dart';

import '../../models/category.dart';
import 'category_icons.dart';

/// Pilihan kategori yang membuka daftar secara animasi di bawah field.
/// Maksimal [_visibleItems] item terlihat, sisanya di-scroll.
class CategoryDropdown extends StatefulWidget {
  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.value,
    required this.onChanged,
    this.validator,
    this.allOption,
  });

  final List<Category> categories;
  final int? value;
  final ValueChanged<int?> onChanged;
  final FormFieldValidator<int>? validator;

  /// Label opsi tanpa filter (nilai null). Null = opsi ini tidak ditampilkan.
  final String? allOption;

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  static const _visibleItems = 5;
  static const _itemHeight = 48.0;
  static const _duration = Duration(milliseconds: 250);

  final _scrollCtrl = ScrollController();
  bool _open = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    // Tutup keyboard agar daftar tidak tertutup olehnya.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _open = !_open);
  }

  void _select(FormFieldState<int> field, int? id) {
    field.didChange(id);
    if (field.hasError) field.validate();
    widget.onChanged(id);
    setState(() => _open = false);
  }

  Category? _categoryById(int? id) {
    for (final c in widget.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Widget _label(Category cat) => Row(
        children: [
          Icon(iconFor(cat.icon), color: Color(cat.colorValue), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(cat.name, overflow: TextOverflow.ellipsis)),
        ],
      );

  Widget _optionLabel(Category? cat) =>
      cat == null ? Text(widget.allOption ?? '') : _label(cat);

  Widget _list(FormFieldState<int> field) {
    final colors = Theme.of(context).colorScheme;
    final options = <Category?>[
      if (widget.allOption != null) null,
      ...widget.categories,
    ];
    final count = options.length;
    final visible = count < _visibleItems ? count : _visibleItems;

    return Container(
      height: visible * _itemHeight,
      margin: const EdgeInsets.only(top: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Scrollbar(
        controller: _scrollCtrl,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: EdgeInsets.zero,
          itemExtent: _itemHeight,
          itemCount: count,
          itemBuilder: (_, i) {
            final cat = options[i];
            return InkWell(
              onTap: () => _select(field, cat?.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                color: cat?.id == field.value
                    ? colors.primaryContainer.withValues(alpha: 0.5)
                    : null,
                child: _optionLabel(cat),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (field) {
        final selected = _categoryById(field.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _toggle,
              child: InputDecorator(
                isEmpty: selected == null && widget.allOption == null,
                isFocused: _open,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: const OutlineInputBorder(),
                  errorText: field.errorText,
                  suffixIcon: AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: _duration,
                    child: const Icon(Icons.arrow_drop_down),
                  ),
                ),
                child: _optionLabel(selected),
              ),
            ),
            AnimatedSize(
              duration: _duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open ? _list(field) : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
