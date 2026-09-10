import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService instance = NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  final StreamController<List<ConnectivityResult>> _connectivityController =
      StreamController<List<ConnectivityResult>>.broadcast();
  final StreamController<int> _batteryController = StreamController<int>.broadcast();

  List<ConnectivityResult> _currentConnectivity = [ConnectivityResult.none];
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;

  NetworkService._internal() {
    _initListeners();
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivityController.stream;
  Stream<int> get onBatteryChanged => _batteryController.stream;

  List<ConnectivityResult> get currentConnectivity => _currentConnectivity;
  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;

  bool get isWifiConnected => _currentConnectivity.contains(ConnectivityResult.wifi);
  bool get isMobileDataConnected => _currentConnectivity.contains(ConnectivityResult.mobile);
  bool get hasNetworkConnection =>
      !_currentConnectivity.contains(ConnectivityResult.none) && _currentConnectivity.isNotEmpty;
  bool get isCharging =>
      _batteryState == BatteryState.charging || _batteryState == BatteryState.full;

  void _initListeners() async {
    try {
      _currentConnectivity = await _connectivity.checkConnectivity();
    } catch (_) {}

    _connectivity.onConnectivityChanged.listen((results) {
      _currentConnectivity = results;
      _connectivityController.add(results);
    });

    try {
      _batteryLevel = await _battery.batteryLevel;
      _batteryState = await _battery.batteryState;
    } catch (_) {}

    _battery.onBatteryStateChanged.listen((state) async {
      _batteryState = state;
      try {
        _batteryLevel = await _battery.batteryLevel;
        _batteryController.add(_batteryLevel);
      } catch (_) {}
    });
  }

  Future<bool> checkDnsResolution(String host) async {
    try {
      final lookup = await InternetAddress.lookup(host).timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkHostReachable(String host, {int port = 443}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 4));
      socket.destroy();
      return true;
    } catch (_) {
      try {
        final socketHttp = await Socket.connect(host, 80, timeout: const Duration(seconds: 4));
        socketHttp.destroy();
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}
