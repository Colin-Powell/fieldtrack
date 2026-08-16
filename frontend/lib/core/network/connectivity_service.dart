import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectionStatus { online, offline, poor, reconnecting }

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectionStatus> _controller =
      StreamController.broadcast();

  factory ConnectivityService() => _instance;

  ConnectionStatus currentStatus = ConnectionStatus.online;

  ConnectivityService._internal() {
    _connectivity.onConnectivityChanged.listen((result) async {
      // result is List<ConnectivityResult> in connectivity_plus ^6.0.0
      if (result.contains(ConnectivityResult.none) || result.isEmpty) {
        currentStatus = ConnectionStatus.offline;
        _controller.add(ConnectionStatus.offline);
      } else {
        currentStatus = ConnectionStatus.online;
        _controller.add(ConnectionStatus.online);
      }
    });
    // Initial check
    _checkInitial();
  }

  Stream<ConnectionStatus> get onStatusChange => _controller.stream;

  Future<void> _checkInitial() async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none) || result.isEmpty) {
      currentStatus = ConnectionStatus.offline;
      _controller.add(ConnectionStatus.offline);
    } else {
      currentStatus = ConnectionStatus.online;
      _controller.add(ConnectionStatus.online);
    }
  }

  void dispose() {
    _controller.close();
  }
}
