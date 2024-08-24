import 'package:chess_game/controller/chess_controller.dart';
import 'package:chess_game/controller/enums.dart';


abstract class BaseAgent {
  BaseAgent({required this.controller, required this.playingColor});

  final PieceColor playingColor;

  final ChessController controller;

  Future<List<String>> sendMove();
}
