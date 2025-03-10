// -------------------------------------importacoes-------------------------------------
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';

import 'package:get/get.dart';
import 'package:myflutterapp/view/view_scan.dart';
import 'dart:developer';
import 'package:permission_handler/permission_handler.dart';
import '../controller/controller_bluetooth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final controller = Get.find<RequirementStateController>();
  StreamSubscription<BluetoothState> _streamBluetooth;
  int currentIndex = 0;
  String retorno = ' ';

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    esperaEstadoBluetooth();
  }

  esperaEstadoBluetooth() async {
    _streamBluetooth = flutterBeacon
        .bluetoothStateChanged()
        .listen((BluetoothState state) async {
      controller.atualizaEstadoBluetooth(state);
      await verificaParametroApp();
    });
  }

  verificaParametroApp() async {
    final bluetoothState = await flutterBeacon.bluetoothState;
    controller.atualizaEstadoBluetooth(bluetoothState);
    _streamBluetooth.printInfo();

    final authorizationStatus = await flutterBeacon.authorizationStatus;
    controller.updateAuthorizationStatus(authorizationStatus);

    final locationServiceEnabled =
        await flutterBeacon.checkLocationServicesIfEnabled;
    controller.updateLocationService(locationServiceEnabled);
   
    if (controller.bluetoothEnabled &&
        controller.authorizationStatusOk &&
        controller.locationServiceEnabled) {
      if (currentIndex == 0) {
        controller.iniciaEscaneamento();
      } else {
        controller.pausaEscaneamento();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (_streamBluetooth != null) {
        if (_streamBluetooth.isPaused) {
          _streamBluetooth?.resume();
        }
      }
      await verificaParametroApp();
    } else if (state == AppLifecycleState.paused) {
      _streamBluetooth?.pause();
    }
  }

  @override
  void dispose() {
    _streamBluetooth?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projeto'),
        centerTitle: false,
        actions: <Widget>[
          Obx(() {
            if (!controller.locationServiceEnabled)
              return IconButton(
                tooltip: 'Not Determined',
                icon: Icon(Icons.portable_wifi_off),
                color: Colors.grey,
                onPressed: () {},
              );

            if (!controller.authorizationStatusOk)
              return IconButton(
                tooltip: 'Not Authorized',
                icon: Icon(Icons.portable_wifi_off),
                color: Colors.red,
                onPressed: () async {
                  await flutterBeacon.requestAuthorization;
                },
              );

            return IconButton(
              tooltip: 'Authorized',
              icon: Icon(Icons.wifi_tethering),
              color: Colors.blue,
              onPressed: () async {
                await flutterBeacon.requestAuthorization;
              },
            );
          }),
          Obx(() {
            return IconButton(
              tooltip: controller.locationServiceEnabled
                  ? 'Location Service ON'
                  : 'Location Service OFF',
              icon: Icon(
                controller.locationServiceEnabled
                    ? Icons.location_on
                    : Icons.location_off,
              ),
              color:
                  controller.locationServiceEnabled ? Colors.blue : Colors.red,
              onPressed: controller.locationServiceEnabled
                  ? () {}
                  : handleOpenLocationSettings,
            );
          }),
          Obx(() {
            final state = controller.bluetoothState.value;

            if (state == BluetoothState.stateOn) {
              return IconButton(
                tooltip: 'Bluetooth ligado',
                icon: const Icon(Icons.bluetooth_connected),
                onPressed: () {},
                color: Colors.lightBlueAccent,
              );
            }

            if (state == BluetoothState.stateOff) {
              return IconButton(
                tooltip: 'Bluetooth desligado',
                icon: const Icon(Icons.bluetooth),
                onPressed: handleOpenBluetooth,
                color: Colors.red,
              );
            }

            return IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              tooltip: 'Bluetooth não disponível',
              onPressed: () {},
              color: Colors.grey,
            );
          }),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: const [
          TabScanning(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          if (currentIndex == 0) {
            controller.iniciaEscaneamento();
          } else {
            controller.pausaEscaneamento();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Escanear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pause),
            label: 'Pausar',
          ),
        ],
      ),
    );
  }

  handleOpenLocationSettings() async {
    if (Platform.isAndroid) {
      await flutterBeacon.openLocationSettings;
    } 
  }

  handleOpenBluetooth() async {
    if (Platform.isAndroid) {
      try {
        await flutterBeacon.openBluetoothSettings;
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }
}
