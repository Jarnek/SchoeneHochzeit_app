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
  final _suggestions = <String>[];
  final _biggerFont = const TextStyle(fontSize: 18);
  final _found = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('QR Codes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () {
                _scanQrCode(context);
              },
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
              _suggestions.add(index.toString());
            }
            final alreadySaved = _found.contains(index.toString());
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

  Future<void> _scanQrCode(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => scanner()),
    );
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text('Congrats, you found code number $result')));

    setState(() {
      if (!_found.contains(result)) {
        _found.add(result);
      }
    });
  }
}

class scanner extends StatefulWidget {
  const scanner({Key? key}) : super(key: key);

  @override
  State<scanner> createState() => _scannerState();
}

class _scannerState extends State<scanner> {
  MobileScannerController cameraController = MobileScannerController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Mobile Scanner'),
          actions: [
            IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder(
                valueListenable: cameraController.torchState,
                builder: (context, state, child) {
                  switch (state as TorchState) {
                    case TorchState.off:
                      return const Icon(Icons.flash_off, color: Colors.grey);
                    case TorchState.on:
                      return const Icon(Icons.flash_on, color: Colors.yellow);
                  }
                },
              ),
              iconSize: 32.0,
              onPressed: () => cameraController.toggleTorch(),
            ),
            IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder(
                valueListenable: cameraController.cameraFacingState,
                builder: (context, state, child) {
                  switch (state as CameraFacing) {
                    case CameraFacing.front:
                      return const Icon(Icons.camera_front);
                    case CameraFacing.back:
                      return const Icon(Icons.camera_rear);
                  }
                },
              ),
              iconSize: 32.0,
              onPressed: () => cameraController.switchCamera(),
            ),
          ],
        ),
        body: MobileScanner(
            allowDuplicates: false,
            controller: cameraController,
            onDetect: (barcode, args) {
              if (barcode.rawValue == null) {
                debugPrint('Failed to scan Barcode');
              } else {
                final String code = barcode.rawValue!;
                Navigator.pop(context, code);
              }
            }));
  }
}
