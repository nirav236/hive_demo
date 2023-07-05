import 'package:flutter/material.dart';

import 'package:hive_flutter/adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox("shopping_box");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  @override
  void initState() {
    super.initState();
    refreshItem();
  }

  List<Map<String, dynamic>> items = [];

  final shoppingbox = Hive.box("shopping_box");

  void refreshItem() {
    final data = shoppingbox.keys.map((key) {
      final item = shoppingbox.get(key);
      return {"key": key, "name": item["name"], "quantity": item['quantity']};
    }).toList();

    setState(() {
      items = data.reversed.toList();
      print(items.length);
    });
  }

  Future<void> createitem(Map<String, dynamic> newItem) async {
    await shoppingbox.add(newItem);
    refreshItem();
  }

  Future<void> updateitem(int itemKey, Map<String, dynamic> item) async {
    await shoppingbox.put(itemKey, item);
    refreshItem();
  }

  Future<void> deleteitem(int itemKey) async {
    await shoppingbox.delete(itemKey);
    refreshItem();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("item has been deleted")));
  }

  void showform(BuildContext context, int? itemKey) async {
    if (itemKey != null) {
      final existingItem =
          items.firstWhere((element) => element['key'] == itemKey);
      nameController.text = existingItem['name'];
      quantityController.text = existingItem['quantity'];
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 15,
                  left: 15,
                  right: 15),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: "Name"),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: "Quantity"),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (itemKey == null) {
                          createitem({
                            "name": nameController.text,
                            "quantity": quantityController.text
                          });
                        }

                        if (itemKey != null) {
                          updateitem(itemKey, {
                            "name": nameController.text.trim(),
                            "quantity": quantityController.text.trim()
                          });
                        }

                        nameController.text = '';
                        quantityController.text = '';
                        Navigator.of(context).pop();
                      },
                      child: const Text("Create New"),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                  ]),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Hive"),
      ),
      body: ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) {
            final currentitem = items[index];
            return Card(
              color: Colors.orange.shade100,
              margin: EdgeInsets.all(10),
              elevation: 3,
              child: ListTile(
                title: Text(currentitem['name']),
                subtitle: Text(currentitem['quantity'].toString()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        onPressed: () => showform(context, currentitem['key']),
                        icon: Icon(Icons.edit)),
                    IconButton(
                        onPressed: () => deleteitem(currentitem['key']),
                        icon: Icon(Icons.delete))
                  ],
                ),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showform(context, null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
