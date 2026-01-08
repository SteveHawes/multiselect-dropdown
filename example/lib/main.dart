import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Multiselect dropdown demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      routerConfig: GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return const MyHomePage();
          },
        ),
      ]),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class User {
  final String name;
  final int id;

  User({required this.name, required this.id});

  @override
  String toString() {
    return 'User(name: $name, id: $id)';
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  final controller = MultiSelectController<User>();

  @override
  Widget build(BuildContext context) {
    var items = [
      DropdownItem(
        label: 'Nepal', 
        value: User(name: 'Nepal', id: 1),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        unselectedIcon: const Icon(Icons.flag, color: Colors.blue),
      ),
      DropdownItem(
        label: 'Australia', 
        value: User(name: 'Australia', id: 6),
        textStyle: const TextStyle(fontStyle: FontStyle.italic),
      ),
      DropdownItem(
        label: 'India', 
        value: User(name: 'India', id: 2),
        unselectedIcon: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward, size: 16, color: Colors.green),
            SizedBox(width: 4),
            Text('Select', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
      ),
      DropdownItem(label: 'China', value: User(name: 'China', id: 3)),
      DropdownItem(
        label: 'USA', 
        value: User(name: 'USA', id: 4),
        textStyle: const TextStyle(fontSize: 18, letterSpacing: 1.2),
        unselectedIcon: const Icon(Icons.star, color: Colors.red),
      ),
      DropdownItem(label: 'UK', value: User(name: 'UK', id: 5)),
      DropdownItem(label: 'Germany', value: User(name: 'Germany', id: 7)),
      DropdownItem(
        label: 'France', 
        value: User(name: 'France', id: 8),
        textStyle: const TextStyle(decoration: TextDecoration.underline),
        unselectedIcon: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('FR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    ];
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(
                        height: 4,
                      ),
                      MultiDropdown<User>(
                        items: items,
                        controller: controller,
                        enabled: true,
                        searchEnabled: true,
                        chipDecoration: const ChipDecoration(
                          backgroundColor: Colors.yellow,
                          wrap: true,
                          runSpacing: 2,
                          spacing: 10,
                        ),
                        fieldDecoration: FieldDecoration(
                          hintText: 'Countries',
                          hintStyle: const TextStyle(color: Colors.black87),
                          prefixIcon: const Icon(CupertinoIcons.flag),
                          showClearIcon: false,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        dropdownDecoration: const DropdownDecoration(
                          marginTop: 2,
                          maxHeight: 500,
                          header: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Select countries from the list',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        dropdownItemDecoration: DropdownItemDecoration(
                          selectedIcon:
                              const Icon(Icons.check_box, color: Colors.green),
                          disabledIcon:
                              Icon(Icons.lock, color: Colors.grey.shade300),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a country';
                          }
                          return null;
                        },
                        onSelectionChange: (selectedItems) {
                          debugPrint("OnSelectionChange: $selectedItems");
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                final selectedItems = controller.selectedItems;

                                debugPrint(selectedItems.toString());
                              }
                            },
                            child: const Text('Submit'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              controller.selectAll();
                            },
                            child: const Text('Select All'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              controller.clearAll();
                            },
                            child: const Text('Unselect All'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              controller.addItems([
                                DropdownItem(
                                  label: 'Japan',
                                  value: User(name: 'Japan', id: 9),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                  unselectedIcon: const Icon(Icons.travel_explore, color: Colors.purple),
                                ),
                              ]);
                            },
                            child: const Text('Add Items'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              controller.selectWhere((element) =>
                                  element.value.id == 1 ||
                                  element.value.id == 2 ||
                                  element.value.id == 3);
                            },
                            child: const Text('Select Where'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              controller.selectAtIndex(0);
                            },
                            child: const Text('Select At Index'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              controller.openDropdown();
                            },
                            child: const Text('Open/Close dropdown'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
