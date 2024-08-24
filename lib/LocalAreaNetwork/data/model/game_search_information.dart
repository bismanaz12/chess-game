

import 'package:chess_game/LocalAreaNetwork/data/model/address_and_port.dart';

class GameSearchInformation {
  final AddressAndPort addressAndPort;
  final bool ableToConnect;

  GameSearchInformation({
    required this.addressAndPort,
    required this.ableToConnect,
  });

  String get name => addressAndPort.toString();

  @override
  String toString() {
    return '$addressAndPort | ableToConnect: $ableToConnect';
  }
}