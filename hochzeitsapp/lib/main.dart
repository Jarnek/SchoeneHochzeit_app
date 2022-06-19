import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Startup Name Generator",
      home: const RandomWords(),
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <int>[];
  final _biggerFont = const TextStyle(fontSize: 18);
  final _found = <int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('QR Codes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: _scanCode,
              tooltip: 'Scan a code',
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: 39,
          padding: const EdgeInsets.all(16.0),
          itemBuilder: (context, i) {
            if (i.isOdd) return const Divider();
            final index = i ~/ 2;
            if (index >= _suggestions.length) {
              _suggestions.add(index);
            }
            final alreadySaved = _found.contains(index);
            return ListTile(
              title: Text(
                index.toString(),
                style: _biggerFont,
              ),
              trailing: Icon(
                alreadySaved ? Icons.favorite : Icons.favorite_border,
                color: alreadySaved ? Colors.red : null,
                semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
              ),
            );
          },
        ));
  }

  void _scanCode() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Mobile Scanner')),
          body: MobileScanner(
              allowDuplicates: false,
              controller: MobileScannerController(
                  facing: CameraFacing.front, torchEnabled: true),
              onDetect: (barcode, args) {
                if (barcode.rawValue == null) {
                  debugPrint('Failed to scan Barcode');
                } else {
                  final String code = barcode.rawValue!;
                  debugPrint('Barcode found! $code');
                }
              }),
        );
      },
    ));
  }
}
