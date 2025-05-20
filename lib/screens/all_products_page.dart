import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:invent_app_redesign/screens/login_screen.dart';

class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});

  Future<void> _cacheProducts(List<QueryDocumentSnapshot> products) async {
    final box = Hive.box('products');
    await box.clear();
    for (var product in products) {
      final data = product.data() as Map<String, dynamic>;
      data['id'] = product.id;
      data['isSynced'] = true;
      await box.put(product.id, data);
    }
  }

  Future<void> _syncDrafts(BuildContext context) async {
    if (!(await NetworkService.isOnline())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    final draftBox = Hive.box('drafts');
    final productBox = Hive.box('products');
    for (var key in draftBox.keys) {
      final draft = draftBox.get(key) as Map<dynamic, dynamic>;
      if (!(draft['isSynced'] ?? false)) {
        try {
          final docRef = await FirebaseFirestore.instance.collection('products').add({
            'name': draft['name'],
            'company': draft['company'],
            'quantity': draft['quantity'],
            'wholesale_price': draft['wholesale_price'],
            'barcode': draft['barcode'],
            'imageUrl': draft['imageUrl'],
            'timestamp': FieldValue.serverTimestamp(),
          });
          draft['id'] = docRef.id;
          draft['isSynced'] = true;
          await productBox.put(docRef.id, draft);
          await draftBox.delete(key);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error syncing: $e')),
          );
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Drafts synced')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Products"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _syncDrafts(context),
            tooltip: 'Sync Drafts',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            final box = Hive.box('products');
            if (box.isNotEmpty) {
              return _buildProductList(context, box.values.cast<Map<dynamic, dynamic>>().toList());
            }
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final box = Hive.box('products');
            if (box.isNotEmpty) {
              return _buildProductList(context, box.values.cast<Map<dynamic, dynamic>>().toList());
            }
            return const Center(child: Text("Error loading products"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            final box = Hive.box('products');
            if (box.isNotEmpty) {
              return _buildProductList(context, box.values.cast<Map<dynamic, dynamic>>().toList());
            }
            return const Center(child: Text("No products available"));
          }

          _cacheProducts(snapshot.data!.docs);
          return _buildProductList(context, snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
        },
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<Map<dynamic, dynamic>> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final data = products[index];
        final bgColor = index % 2 == 0 ? Colors.white : const Color(0xFFF3F4F6);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: bgColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['name'] ?? 'No name',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Компания: ${data['company'] ?? '-'}'),
                  Text('Штрихкод: ${data['barcode'] ?? '-'}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Кол-во: ${data['quantity'] ?? 0}'),
                  const SizedBox(width: 16),
                  Text('Цена: ${data['wholesale_price'] ?? 0} ₸'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}