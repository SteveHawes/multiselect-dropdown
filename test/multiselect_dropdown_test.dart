import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

ThemeData _theme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
    brightness: brightness,
  ),
);

List<DropdownItem<String>> _items() => <DropdownItem<String>>[
  DropdownItem<String>(label: 'Bar', value: 'bar'),
  DropdownItem<String>(label: 'Club', value: 'club'),
  DropdownItem<String>(
    label: 'Restaurant',
    value: 'restaurant',
    selected: true,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required ThemeData theme,
  bool enabled = true,
  ChipDecoration chipDecoration = const ChipDecoration(),
  DropdownDecoration dropdownDecoration = const DropdownDecoration(),
  DropdownItemDecoration dropdownItemDecoration =
      const DropdownItemDecoration(),
  ValueChanged<List<String>>? onSelectionChange,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MultiDropdown<String>(
            items: _items(),
            enabled: enabled,
            chipDecoration: chipDecoration,
            dropdownDecoration: dropdownDecoration,
            dropdownItemDecoration: dropdownItemDecoration,
            onSelectionChange: onSelectionChange,
            fieldDecoration: const FieldDecoration(labelText: 'Venue type'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The colour [text] is painted in.
Color _ink(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(text).text.style!.color!;

/// The chip label for [label], in the field rather than the open list.
Finder _chipLabel(String label) => find.descendant(
  of: find.byType(InputDecorator),
  matching: find.text(label),
);

/// The fill of the chip around [label].
Color _chipFill(WidgetTester tester, String label) {
  final chip = tester.widget<Container>(
    find
        .ancestor(of: _chipLabel(label), matching: find.byType(Container))
        .first,
  );
  return (chip.decoration! as BoxDecoration).color!;
}

/// The list option for [label], in the open list rather than the field.
Finder _optionLabel(String label) =>
    find.descendant(of: find.byType(ListTile), matching: find.text(label));

void main() {
  for (final brightness in Brightness.values) {
    final name = brightness.name;

    group('$name theme', () {
      for (final enabled in <bool>[true, false]) {
        final state = enabled ? 'enabled' : 'disabled';

        testWidgets('$state: a chip label reaches 4.5:1 on its chip', (
          tester,
        ) async {
          await _pump(tester, theme: _theme(brightness), enabled: enabled);

          final ratio = _contrast(
            _ink(tester, _chipLabel('Restaurant')),
            _chipFill(tester, 'Restaurant'),
          );
          expect(ratio, greaterThanOrEqualTo(4.5));
        });
      }

      testWidgets('the open list paints no debug assertion', (tester) async {
        await _pump(tester, theme: _theme(brightness));

        await tester.tap(find.byType(MultiDropdown<String>));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(_optionLabel('Bar'), findsOneWidget);
      });

      testWidgets("the open list's values reach 4.5:1", (tester) async {
        await _pump(tester, theme: _theme(brightness));
        await tester.tap(find.byType(MultiDropdown<String>));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        // A failure to paint the list is reported by the test above.
        tester.takeException();

        // The panel is the nearest Material above the options.
        final panel = tester
            .widget<Material>(
              find
                  .ancestor(
                    of: find.byType(ListTile).first,
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color!;
        expect(
          _contrast(_ink(tester, _optionLabel('Bar')), panel),
          greaterThanOrEqualTo(4.5),
          reason: 'an unchosen value on the panel',
        );

        final chosen = tester.widget<ListTile>(
          find.ancestor(
            of: _optionLabel('Restaurant'),
            matching: find.byType(ListTile),
          ),
        );
        // The selected fill is painted only while the tile is selected.
        expect(chosen.selected, isTrue);
        expect(
          _contrast(
            _ink(tester, _optionLabel('Restaurant')),
            chosen.selectedTileColor!,
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'a chosen value on its selected fill',
        );
      });
    });
  }

  testWidgets('a disabled field offers no way to remove a chip', (
    tester,
  ) async {
    await _pump(tester, theme: _theme(Brightness.dark), enabled: false);

    expect(_chipLabel('Restaurant'), findsOneWidget);
    expect(
      find.descendant(
        of: find
            .ancestor(of: _chipLabel('Restaurant'), matching: find.byType(Row))
            .first,
        matching: find.byIcon(Icons.close),
      ),
      findsNothing,
    );
  });

  testWidgets('a disabled field offers no way to clear its values', (
    tester,
  ) async {
    final changes = <List<String>>[];
    await _pump(
      tester,
      theme: _theme(Brightness.dark),
      enabled: false,
      onSelectionChange: changes.add,
    );

    expect(find.byIcon(Icons.clear), findsNothing);

    // Tapping where the clear icon sits on an enabled field changes nothing.
    await tester.tapAt(
      tester
          .getCenter(find.byType(InputDecorator))
          .translate(
            tester.getSize(find.byType(InputDecorator)).width / 2 - 24,
            0,
          ),
    );
    await tester.pump();
    expect(_chipLabel('Restaurant'), findsOneWidget);
    expect(changes, isEmpty);
  });

  testWidgets('an enabled field still offers its clear icon', (tester) async {
    final changes = <List<String>>[];
    await _pump(
      tester,
      theme: _theme(Brightness.dark),
      onSelectionChange: changes.add,
    );

    expect(find.byIcon(Icons.clear), findsOneWidget);
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(_chipLabel('Restaurant'), findsNothing);
    expect(changes.last, isEmpty);
  });

  testWidgets('colours the caller gives still win', (tester) async {
    const chipFill = Color(0xFF123456);
    const chipInk = Color(0xFFFEDCBA);
    const panel = Color(0xFF223344);
    await _pump(
      tester,
      theme: _theme(Brightness.light),
      chipDecoration: const ChipDecoration(
        backgroundColor: chipFill,
        labelStyle: TextStyle(color: chipInk),
      ),
      dropdownDecoration: const DropdownDecoration(backgroundColor: panel),
    );

    expect(_chipFill(tester, 'Restaurant'), chipFill);
    expect(_ink(tester, _chipLabel('Restaurant')), chipInk);

    await tester.tap(find.byType(MultiDropdown<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    tester.takeException();
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.byType(ListTile).first,
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, panel);
  });

  testWidgets("a disabled chip's caller colour still wins", (tester) async {
    const disabledFill = Color(0xFF345612);
    await _pump(
      tester,
      theme: _theme(Brightness.dark),
      enabled: false,
      chipDecoration: const ChipDecoration(
        disabledBackgroundColor: disabledFill,
      ),
    );

    expect(_chipFill(tester, 'Restaurant'), disabledFill);
  });

  testWidgets("the list's caller colours still win", (tester) async {
    const selectedFill = Color(0xFF441122);
    const selectedInk = Color(0xFFEEDDCC);
    const ink = Color(0xFF112244);
    await _pump(
      tester,
      theme: _theme(Brightness.light),
      dropdownItemDecoration: const DropdownItemDecoration(
        selectedBackgroundColor: selectedFill,
        selectedTextColor: selectedInk,
        textColor: ink,
      ),
    );
    await tester.tap(find.byType(MultiDropdown<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    tester.takeException();

    final chosen = tester.widget<ListTile>(
      find.ancestor(
        of: _optionLabel('Restaurant'),
        matching: find.byType(ListTile),
      ),
    );
    expect(chosen.selectedTileColor, selectedFill);
    expect(_ink(tester, _optionLabel('Restaurant')), selectedInk);
    expect(_ink(tester, _optionLabel('Bar')), ink);
  });
}
