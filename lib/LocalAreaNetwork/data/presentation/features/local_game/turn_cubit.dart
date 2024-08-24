import 'package:chess_game/LocalAreaNetwork/data/model/turn_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class TurnCubit extends Cubit<TurnModel> {
  TurnCubit() : super(TurnModel());

  changeState(bool isWhiteTurn, bool checkmate) {
    emit(TurnModel(
      isWhiteTurn: isWhiteTurn,
      checkmate: checkmate,
    ));
  }
}