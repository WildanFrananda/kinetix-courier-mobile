import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/state/session_end.dart';

abstract interface class ConnectionRepository {
  Stream<ConnectionStatus> get statusStream;
  Stream<SessionEnd> get sessionEnded;
  Future<void> connect(DriverSession session);
  Future<void> disconnect();
  void onResume();
  Future<void> dispose();
}
