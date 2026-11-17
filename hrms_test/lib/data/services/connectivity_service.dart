import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _connectivity = Connectivity();
  Stream<bool> get onlineChanges => _connectivity.onConnectivityChanged.map(
    (items) => items.any((item) => item != ConnectivityResult.none),
  );
  Future<bool> get isOnline async {
    final items = await _connectivity.checkConnectivity();
    return items.any((item) => item != ConnectivityResult.none);
  }
}
