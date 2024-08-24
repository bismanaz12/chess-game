import 'package:chess_game/agents/base_agent.dart';
import 'package:chess_game/controller/chess_controller.dart';
import 'package:chess_game/controller/enums.dart';


class RandomAgent extends BaseAgent {
  RandomAgent(
      {required ChessController controller,
      required PieceColor playingColor,
      this.delaySeconds = 1})
      : super(controller: controller, playingColor: playingColor);

  final int delaySeconds;

  @override
  Future<List<String>> sendMove() async {
    if (playingColor == controller.currentTurnColor) {
      await Future.delayed(Duration(seconds: delaySeconds));
      return (controller.legalMovesForCurrentPlayer..shuffle()).first;
    }
    return [];
  }
}
