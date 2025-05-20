import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invent_app_redesign/screens/login_screen.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});

  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  bool isScanning = true;
  String? lastScannedCode;

  void _onBarcodeScanned(String code) async {
    setState(() {
      isScanning = false;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: code)
          .get();

      if (query.docs.isNotEmpty) {
        final product = query.docs.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        ).then((_) {
          setState(() {
            isScanning = true;
            lastScannedCode = null;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар не найден')),
        );
        setState(() {
          isScanning = true;
          lastScannedCode = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
      setState(() {
        isScanning = true;
        lastScannedCode = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<bool>(
        future: NetworkService.isOnline(),
        builder: (context, snapshot) {
          if (snapshot.hasData && !snapshot.data!) {
            return const Center(
              child: Text(
                'Barcode scanning unavailable offline',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }
          return isScanning
              ? MobileScanner(
            controller: MobileScannerController(),
            onDetect: (BarcodeCapture capture) {
              final Barcode? barcode = capture.barcodes.firstOrNull;
              final String? code = barcode?.rawValue;
              if (code != null && code != lastScannedCode) {
                lastScannedCode = code;
                _onBarcodeScanned(code);
              }
            },
          )
              : const Center(
            child: Text(
              'Пожалуйста, подождите...',
              style: TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot product;
  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final data = product.data() as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(title: Text(data['name'] ?? 'Товар')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (data['imageUrl'] != null)
              Image.network(data['imageUrl']),
            const SizedBox(height: 20),
            Text('Название: ${data['name'] ?? ''}'),
            Text('Компания: ${data['company'] ?? ''}'),
            Text('Количество: ${data['quantity']?.toString() ?? ''}'),
            Text('Оптовая цена: ${data['wholesalePrice']?.toString() ?? ''}'),
            Text('Штрихкод: ${data['barcode'] ?? ''}'),
          ],
        ),
      ),
    );
  }
}