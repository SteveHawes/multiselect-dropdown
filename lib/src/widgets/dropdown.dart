part of '../multi_dropdown.dart';

/// Dropdown widget for the multiselect dropdown.
///
class _Dropdown<T> extends StatelessWidget {
  /// Creates a dropdown widget.
  const new({
    required this.decoration,
    required this.width,
    required this.searchEnabled,
    required this.dropdownItemDecoration,
    required this.searchDecoration,
    required this.maxSelections,
    required this.items,
    required this.onItemTap,
    super.key,
    this.onSearchChange,
    this.itemBuilder,
    this.itemSeparator,
    this.singleSelect = false,
    this.scrollToSelected = false,
    this.disableSelected = false,
  });

  /// The decoration of the dropdown.
  final DropdownDecoration decoration;

  /// Whether the search field is enabled.
  final bool searchEnabled;

  /// The width of the dropdown.
  final double width;

  /// The decoration of the dropdown items.
  final DropdownItemDecoration dropdownItemDecoration;

  /// Dropdown item builder, if not provided, the default ListTile will be used.
  final DropdownItemBuilder<T>? itemBuilder;

  /// The separator between the dropdown items.
  final Widget? itemSeparator;

  /// The decoration of the search field.
  final SearchFieldDecoration searchDecoration;

  /// The maximum number of selections allowed.
  final int maxSelections;

  /// The list of dropdown items.
  final List<DropdownItem<T>> items;

  /// The callback when an item is tapped.
  final ValueChanged<DropdownItem<T>> onItemTap;

  /// The callback when the search field value changes.
  final ValueChanged<String>? onSearchChange;

  /// Whether the selection is single.
  final bool singleSelect;

  /// Whether to scroll to the selected item.
  final bool scrollToSelected;

  /// Whether to disable selected items.
  final bool disableSelected;

  int get _selectedCount => items.where((element) => element.selected).length;

  static const Map<ShortcutActivator, Intent> _webShortcuts =
      <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
          TraversalDirection.down,
        ),
        SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
          TraversalDirection.up,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelColor =
        decoration.backgroundColor ?? theme.colorScheme.surfaceContainer;

    // The Material alone paints the panel (and clips it to its radius). A
    // coloured box between it and the options would hide their selected fill
    // and ink splashes, which ListTile asserts against in debug builds.
    final child = Material(
      elevation: decoration.elevation,
      borderRadius: decoration.borderRadius,
      clipBehavior: Clip.antiAlias,
      color: panelColor,
      surfaceTintColor: panelColor,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: decoration.maxHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (searchEnabled)
                _SearchField(
                  decoration: searchDecoration,
                  onChanged: _onSearchChange,
                ),
              if (decoration.header != null)
                Flexible(child: decoration.header!),
              Flexible(
                child: ScrollablePositionedList.separated(
                  itemCount: items.length,
                  itemBuilder: (_, index) => _buildOption(index, theme),
                  shrinkWrap: true,
                  separatorBuilder: (_, _) =>
                      itemSeparator ?? const SizedBox.shrink(),
                  initialScrollIndex: scrollToSelected
                      ? items.indexWhere((element) => element.selected)
                      : 0,
                ),
              ),
              if (items.isEmpty && searchEnabled)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No items found',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              if (decoration.footer != null)
                Flexible(child: decoration.footer!),
            ],
          ),
        ),
      ),
    );

    if (kIsWeb || Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return Shortcuts(shortcuts: _webShortcuts, child: child);
    }

    return child;
  }

  Widget _buildOption(int index, ThemeData theme) {
    if (index < 0) {
      return const SizedBox.shrink();
    }
    final option = items[index];

    if (itemBuilder != null) {
      return itemBuilder!(option, index, () => onItemTap(option));
    }

    final disabledColor =
        dropdownItemDecoration.disabledBackgroundColor ??
        dropdownItemDecoration.backgroundColor?.withAlpha(100);

    final tileColor = option.disabled
        ? disabledColor
        : option.selected
        ? dropdownItemDecoration.selectedBackgroundColor
        : dropdownItemDecoration.backgroundColor;

    final trailing = option.disabled
        ? dropdownItemDecoration.disabledIcon
        : option.selected
        ? dropdownItemDecoration.selectedIcon
        : option.unselectedIcon;

    final disabled = option.disabled || (disableSelected && option.selected);
    final colorScheme = theme.colorScheme;
    final panelColor =
        decoration.backgroundColor ?? colorScheme.surfaceContainer;
    // A fill the caller gives without a text colour gets whichever ink reads
    // on it, so a light panel or fill in a dark theme keeps readable text.
    final selectedFill = dropdownItemDecoration.selectedBackgroundColor;
    final selectedInk =
        dropdownItemDecoration.selectedTextColor ??
        (selectedFill == null
            ? colorScheme.onSecondaryContainer
            : _readableInk(selectedFill, colorScheme, base: panelColor));
    final ink =
        dropdownItemDecoration.textColor ??
        _readableInk(
          dropdownItemDecoration.backgroundColor ?? Colors.transparent,
          colorScheme,
          base: panelColor,
        );
    return Ink(
      child: ListTile(
        title: Text(option.label, style: option.textStyle),
        trailing: trailing,
        dense: true,
        selected: option.selected,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        focusColor: dropdownItemDecoration.backgroundColor?.withAlpha(100),
        selectedColor: selectedInk,
        textColor: disabled
            ? dropdownItemDecoration.disabledTextColor ?? ink
            : ink,
        tileColor: tileColor ?? Colors.transparent,
        selectedTileColor:
            dropdownItemDecoration.selectedBackgroundColor ??
            theme.colorScheme.secondaryContainer,
        onTap: disabled
            ? null
            : () {
                if (singleSelect || !_reachedMaxSelection(option)) {
                  onItemTap(option);
                  return;
                }
              },
      ),
    );
  }

  void _onSearchChange(String value) => onSearchChange?.call(value);

  bool _reachedMaxSelection(DropdownItem<dynamic> option) {
    return !option.selected &&
        maxSelections > 0 &&
        _selectedCount >= maxSelections;
  }
}

class _SearchField extends StatelessWidget {
  const new({required this.decoration, required this.onChanged});

  final SearchFieldDecoration decoration;

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: InputDecoration(
          isDense: true,
          hintText: decoration.hintText,
          border: decoration.border,
          focusedBorder: decoration.focusedBorder,
          suffixIcon: decoration.searchIcon,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
