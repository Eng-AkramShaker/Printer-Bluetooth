// ignore_for_file: avoid_unnecessary_containers

import 'dart:io';

import 'package:ams_printer/printer_manager.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scan_bluetooth/flutter_scan_bluetooth.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PrintersView(),
    );
  }
}

class PrintersView extends StatefulWidget {
  const PrintersView({Key? key}) : super(key: key);

  @override
  State<PrintersView> createState() => _PrintersViewState();
}

class _PrintersViewState extends State<PrintersView> {
  late FlutterScanBluetooth _scanBluetooth;
  late List<BluetoothDevice> _devices;
  BluetoothDevice? _selectedDevice;

  late File imgFile;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _devices = [];
    _scanBluetooth = FlutterScanBluetooth();
    _startScan();
    _initImg();
  }

  _startScan() async {
    setState(() {
      isScanning = true;
    });
    await _scanBluetooth.startScan();

    _scanBluetooth.devices.listen((dev) {
      if (!_isDeviceAdded(dev)) {
        setState(() {
          _devices.add(dev);
        });
      }
    });

    await Future.delayed(const Duration(seconds: 10));
    _stopScan();
  }

  _stopScan() {
    _scanBluetooth.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  bool _isDeviceAdded(BluetoothDevice device) => _devices.contains(device);

  _initImg() async {
    try {
      ByteData byteData = await rootBundle.load("images/flutter.png");
      Uint8List buffer = byteData.buffer.asUint8List();
      String path = (await getTemporaryDirectory()).path;
      imgFile = File("$path/img.png");
      imgFile.writeAsBytes(buffer);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 0.0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 100),

          // ---------------------------------------------------------------------------------------------------
          ConditionalBuilder(
            condition: _selectedDevice != null,
            builder: (context) => Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 175, 224, 177),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(_selectedDevice!.name,
                          style: const TextStyle(
                              color: Colors.lightBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(_selectedDevice!.address,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14))
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MaterialButton(
                      onPressed: () {
                        PrinterManager.printImg(imgFile.path);
                      },
                      color: Colors.lightBlue,
                      child: const Text(
                        "إطبع",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    MaterialButton(
                      onPressed: () {
                        PrinterManager.connect(_selectedDevice!.address);
                      },
                      color: Colors.lightBlue,
                      child: const Text(
                        "أتصال",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            ),
            fallback: (context) => Container(
              child: const Text("لم يتم تحديد طابعة"),
            ),
          ),

          // ---------------------------------------------------------------------------------------------------

          const SizedBox(
            height: 15,
          ),
          Container(
            height: 7,
            width: double.infinity,
            color: Colors.red,
          ),
          const SizedBox(
            height: 15,
          ),

          // =======================================================================================================

          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  builder: (context) {
                    return SizedBox(
                      height: 700,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ..._devices.map((dev) => _buildDev(dev)),
                        ],
                      ),
                    );
                  });
            },
            child: const Text("بحث"),
          )
        ],
      ),
    );
  }

  Widget _buildDev(BluetoothDevice dev) => GestureDetector(
        onTap: () {
          setState(() {
            _selectedDevice = dev;
            Navigator.pop(context);
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 175, 224, 177),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(dev.name,
                  style: const TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 10,
              ),
              Text(dev.address,
                  style: const TextStyle(color: Colors.grey, fontSize: 14))
            ],
          ),
        ),
      );
}
