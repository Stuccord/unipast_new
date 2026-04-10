import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { isConnected, isDisconnected, isConnecting }

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  ConnectivityNotifier() : super(ConnectivityStatus.isConnecting) {
    _init();
  }

  void _init() async {
    final List<ConnectivityResult> results =
        await Connectivity().checkConnectivity();
    _handleResult(results);

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _handleResult(results);
    });
  }

  void _handleResult(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      state = ConnectivityStatus.isDisconnected;
    } else {
      state = ConnectivityStatus.isConnected;
    }
  }

  bool get isConnected => state == ConnectivityStatus.isConnected;
}
