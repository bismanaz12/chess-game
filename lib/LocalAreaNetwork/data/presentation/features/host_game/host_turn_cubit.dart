import 'package:chess_game/LocalAreaNetwork/data/model/turn_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class HostTurnCubit extends Cubit<TurnModel> {
  HostTurnCubit() : super(TurnModel());

  changeState(bool isWhiteTurn, bool checkmate) {
    emit(TurnModel(
      isWhiteTurn: isWhiteTurn,
      checkmate: checkmate,
    ));
  }
}