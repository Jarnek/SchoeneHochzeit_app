import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'secrets.dart';

void main() {
  runApp(MaterialApp(
      title: "Coole Hochzeitsapp", home: Hochzeitsapp(storage: Storage())));
}

class Storage {
  Future<File> get _localFile async {
    final metapath = await getExternalStorageDirectory();
    final path = metapath!.path;
    if (!File("$path/gamestate.txt").existsSync()) {
      File("$path/gamestate.txt").createSync(recursive: true);
    }
    return File('$path/gamestate.txt');
  }

  Future<String> readState() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      return contents;
    } catch (e) {
      return "";
    }
  }

  Future<File> writeState(found) async {
    final file = await _localFile;
    String output = "";
    for (String line in found) {
      output = "$output;$line";
    }
    return file.writeAsString(output);
  }
}

class Hochzeitsapp extends StatefulWidget {
  const Hochzeitsapp({super.key, required this.storage});
  final Storage storage;

  @override
  State<Hochzeitsapp> createState() => _HochzeitsappState();
}

class _HochzeitsappState extends State<Hochzeitsapp>
    with WidgetsBindingObserver {
  final _suggestions = <String>[];
  final _biggerFont = const TextStyle(fontSize: 18);
  final _found = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.storage.readState().then(((value) {
      setState(() {
        _found.addAll(value.split(';'));
      });
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.storage.writeState(_found);
    }
  }

  @override
  void dispose() {
    widget.storage.writeState(_found);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
                widget.storage.writeState(_found);
              },
              tooltip: 'Scan a code',
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: 40,
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
              enabled: _found.contains(index.toString()) ? true : false,
              onTap: () => {
                if (_found.contains(index.toString()))
                  {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                              title: Text(getTitle(index.toString())),
                              content: Image.asset(
                                "images/${index.toString()}${(index < 12 ? ".jpg" : ".gif")}",
                                width: 200,
                                height: 200,
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.pop(context, "OK"),
                                  child: const Text("Nice"),
                                )
                              ],
                            ))
                  }
              },
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
    final scanned = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const scanner()),
    );
    String result = scanned.toString().split('/').last;

    if (result != "null") {
      var response_parsed = json.decode('{"ok": true}');
      if (!_found.contains(result)) {
        Uri url = Uri(
            scheme: "https",
            host: "api.telegram.org",
            path: "/bot$bot_token/sendMessage",
            queryParameters: {
              'text': 'user found code $result',
              'chat_id': chat_id
            });
        final response = await http.get(url);
        response_parsed = json.decode(response.body);
      }

      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(response_parsed['ok'] == true
            ? SnackBar(
                content: Text(_found.contains(result)
                    ? 'Congrats, you found code number $result... again'
                    : 'Congrats, you found code number $result'))
            : SnackBar(
                content:
                    Text("error when transmitting to server: $response_parsed"),
              ));
      if (response_parsed['ok'] == true) {
        setState(() {
          _found.add(result);
        });
        final int? number = int.tryParse(result);
        if (number != null) {
          showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                    title: Text(getTitle(result)),
                    content: Image.asset(
                      "images/$result${(int.tryParse(result)! < 12 ? ".jpg" : ".gif")}",
                      width: 200,
                      height: 200,
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, "OK"),
                        child: const Text("Nice"),
                      )
                    ],
                  ));
        }
      }
    }
  }
}

String getTitle(String id) {
  String ret = "";
  switch (id) {
    case "0":
      ret =
          "Vitamine für die Gesundheit, damit ihr jung und schön bleibt \n 12,99€";
      break;
    case "1":
      ret = "Für die Grundbedürfnisse\n 6,99€";
      break;
    case "2":
      ret = "Anzahlung\n 64,06€";
      break;
    case "3":
      ret = "Für die süßen Momente\n 44,99€";
      break;
    case "4":
      ret = "Damit das Kochen euch beiden Spaß macht\n 99,00€";
      break;
    case "5":
      ret = "Spaß muss sein\n 2,99€";
      break;
    case "6":
      ret = "Das Bier soll euch niemals aus gehen\n35,00€";
      break;
    case "7":
      ret = "Gönnt euch mal was besonders romantisches\n 70,00€";
      break;
    case "8":
      ret =
          "Wer spült und wer abtrocknet, müsst ihr unter euch ausmachen\n 4,50€";
      break;
    case "9":
      ret = "Damit das Feiern nicht zu kurz kommt\n 20,00€";
      break;
    case "10":
      ret = "Damit euer gemeinsames Leben wunderbar und prickelnd wird\n 2,99€";
      break;
    case "11":
      ret = "Dieses Geschenk ist wirklich für'n A...\n 1,49€";
      break;
    case "12":
      ret = "Niete – nein nicht ihr, nur kein Geschenk";
      break;
    case "13":
      ret = "Leider nichts gewonnen";
      break;
    case "14":
      ret = "Kein Geschenk, aber lustig, oder?";
      break;
    case "15":
      ret = "Leider nichts gewonnen";
      break;
    case "16":
      ret =
          "Liebe auf den ersten Blick ist unbezahlbar, deshalb hier kein Geschenk.";
      break;
    case "17":
      ret = "Leider nichts gewonnen";
      break;
    case "18":
      ret = "Leider nichts gewonnen";
      break;
    case "19":
      ret = "Leider nichts gewonnen";
      break;
    default:
      ret = "error";
  }
  return ret;
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
