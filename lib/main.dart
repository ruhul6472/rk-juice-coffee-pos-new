
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RKPosApp());
}

class RKPosApp extends StatelessWidget {
  const RKPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RK Juice & Coffee POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16833B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8F5),
        useMaterial3: true,
      ),
      home: const PosHome(),
    );
  }
}

class PosHome extends StatefulWidget {
  const PosHome({super.key});

  @override
  State<PosHome> createState() => _PosHomeState();
}

class _PosHomeState extends State<PosHome> {
  String shopName = 'RK Juice & Coffee Shop';
  String selectedCategory = 'সব পণ্য';
  List<String> categories = ['জুস', 'কফি', 'চা', 'ফাস্ট ফুড'];
  List<Map<String, dynamic>> products = [];
  Map<String, int> cart = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    shopName = prefs.getString('shopName') ?? shopName;

    final savedCategories = prefs.getString('categories');
    if (savedCategories != null) {
      categories = List<String>.from(jsonDecode(savedCategories));
    }

    final savedProducts = prefs.getString('products');
    if (savedProducts != null) {
      products = List<Map<String, dynamic>>.from(
        (jsonDecode(savedProducts) as List).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      );
    } else {
      products = [
        {'id': '1', 'name': 'লাল চা / Red Tea', 'price': 20.0, 'category': 'চা'},
        {'id': '2', 'name': 'দুধ চা / Milk Tea', 'price': 30.0, 'category': 'চা'},
        {'id': '3', 'name': 'মালাই চা / Malai Tea', 'price': 40.0, 'category': 'চা'},
        {'id': '4', 'name': 'কোল্ড কফি / Cold Coffee', 'price': 100.0, 'category': 'কফি'},
        {'id': '5', 'name': 'কমলার জুস / Orange Juice', 'price': 80.0, 'category': 'জুস'},
      ];
      await saveData();
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopName', shopName);
    await prefs.setString('categories', jsonEncode(categories));
    await prefs.setString('products', jsonEncode(products));
  }

  double get total {
    double value = 0;
    for (final item in products) {
      value += (item['price'] as num).toDouble() *
          (cart[item['id']] ?? 0);
    }
    return value;
  }

  List<Map<String, dynamic>> get visibleProducts {
    if (selectedCategory == 'সব পণ্য') return products;
    return products
        .where((p) => p['category'] == selectedCategory)
        .toList();
  }

  void addToCart(String id) {
    setState(() => cart[id] = (cart[id] ?? 0) + 1);
  }

  void changeQuantity(String id, int change) {
    setState(() {
      final next = (cart[id] ?? 0) + change;
      if (next <= 0) {
        cart.remove(id);
      } else {
        cart[id] = next;
      }
    });
  }

  Future<void> editShopName() async {
    final controller = TextEditingController(text: shopName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('দোকানের নাম / Shop Name'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল / Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('সংরক্ষণ / Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => shopName = result);
      await saveData();
    }
  }

  Future<void> editProduct({Map<String, dynamic>? product}) async {
    final name = TextEditingController(
      text: product?['name']?.toString() ?? '',
    );
    final price = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    String category = product?['category']?.toString() ??
        (categories.isNotEmpty ? categories.first : '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(product == null
              ? 'নতুন পণ্য / New Product'
              : 'পণ্য পরিবর্তন / Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'পণ্যের নাম / Product Name',
                  ),
                ),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'দাম / Price (৳)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categories.contains(category) ? category : null,
                  decoration: const InputDecoration(
                    labelText: 'ক্যাটাগরি / Category',
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (v) => refresh(() => category = v ?? ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () {
                final parsedPrice = double.tryParse(price.text);
                if (name.text.trim().isEmpty ||
                    parsedPrice == null ||
                    parsedPrice < 0 ||
                    category.isEmpty) return;
                Navigator.pop(context, {
                  'name': name.text.trim(),
                  'price': parsedPrice,
                  'category': category,
                });
              },
              child: const Text('সংরক্ষণ / Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      if (product == null) {
        products.add({
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          ...result,
        });
      } else {
        final index = products.indexWhere((p) => p['id'] == product['id']);
        if (index >= 0) products[index] = {
          'id': product['id'],
          ...result,
        };
      }
    });
    await saveData();
  }

  Future<void> manageCategories() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('ক্যাটাগরি / Categories'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'নতুন ক্যাটাগরির নাম',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isNotEmpty &&
                            !categories.contains(value)) {
                          setState(() => categories.add(value));
                          controller.clear();
                          refresh(() {});
                          saveData();
                        }
                      },
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: categories.map((category) {
                      return ListTile(
                        title: Text(category),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final used = products.any(
                              (p) => p['category'] == category,
                            );
                            if (used) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'এই ক্যাটাগরিতে পণ্য আছে। আগে পণ্য সরান।',
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() => categories.remove(category));
                            if (selectedCategory == category) {
                              selectedCategory = 'সব পণ্য';
                            }
                            refresh(() {});
                            await saveData();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বন্ধ / Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> checkout() async {
    if (cart.isEmpty) return;
    final amount = total;
    final payment = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('পেমেন্ট পদ্ধতি / Payment'),
        children: [
          for (final method in ['Cash', 'bKash', 'Nagad'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, method),
              child: Text(method),
            ),
        ],
      ),
    );
    if (payment == null) return;

    setState(() => cart.clear());
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('বিক্রি সম্পন্ন / Sale Complete'),
        content: Text(
          'মোট বিল: ৳${amount.toStringAsFixed(2)}\nপেমেন্ট: $payment',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ঠিক আছে / OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF16833B),
        foregroundColor: Colors.white,
        title: Text(shopName),
        actions: [
          IconButton(
            onPressed: editShopName,
            icon: const Icon(Icons.store),
            tooltip: 'দোকানের নাম পরিবর্তন',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'products') editProduct();
              if (value == 'categories') manageCategories();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'products',
                child: Text('নতুন পণ্য / Add Product'),
              ),
              PopupMenuItem(
                value: 'categories',
                child: Text('ক্যাটাগরি পরিচালনা / Categories'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                'সব পণ্য',
                ...categories,
              ].map((category) {
                final selected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.all(6),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => selectedCategory = category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: visibleProducts.isEmpty
                ? const Center(child: Text('কোনো পণ্য নেই / No products'))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: visibleProducts.length,
                    itemBuilder: (context, index) {
                      final p = visibleProducts[index];
                      return Card(
                        child: ListTile(
                          title: Text(p['name'].toString()),
                          subtitle: Text(
                            '${p['category']} • ৳${p['price']}',
                          ),
                          trailing: Wrap(
                            spacing: 2,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => editProduct(product: p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Color(0xFF16833B)),
                                onPressed: () => addToCart(p['id'].toString()),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  setState(() {
                                    products.removeWhere(
                                      (item) => item['id'] == p['id'],
                                    );
                                    cart.remove(p['id'].toString());
                                  });
                                  await saveData();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              children: [
                if (cart.isNotEmpty)
                  ...cart.entries.map((entry) {
                    final p = products.firstWhere(
                      (item) => item['id'] == entry.key,
                    );
                    return Row(
                      children: [
                        Expanded(child: Text(p['name'].toString())),
                        IconButton(
                          onPressed: () => changeQuantity(entry.key, -1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('${entry.value}'),
                        IconButton(
                          onPressed: () => changeQuantity(entry.key, 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    );
                  }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'মোট / Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '৳${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF16833B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: cart.isEmpty ? null : checkout,
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('বিক্রি সম্পন্ন / Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
