import 'package:chess_game/LocalAreaNetwork/data/model/turn_model.dart';
import 'package:chess_game/LocalAreaNetwork/data/presentation/features/local_game/redoable_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'board_bloc.dart';
import 'board_event.dart';
import 'local_board.dart';
import 'turn_cubit.dart';

class ScreenLocalGame extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ScreenLocalGameState();
}

class _ScreenLocalGameState extends State<ScreenLocalGame> {
  static const int _MENU_RESTART = 0x00;
  static const int _MENU_UNDO = 0x01;
  static const int _MENU_REDO = 0x02;

  void _onMenuItemSelected(int choice) {
    switch (choice) {
      case _MENU_RESTART:
        _showSureDialog(context, 'Are you sure to restart game', '', () {
          context.read<BoardBloc>().add(BoardLoadEvent(restart: true));
        });
        break;
      case _MENU_UNDO:
        context.read<BoardBloc>().add(BoardUndoEvent());
        break;
      case _MENU_REDO:
        context.read<BoardBloc>().add(BoardRedoEvent());
        break;
      default: break; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('CHESS'),
        centerTitle: true,
        actions: [
          BlocBuilder<RedoableCubit, bool>(
            builder: (BuildContext _, bool redoable) {
              return PopupMenuButton<int>(
                onSelected: _onMenuItemSelected,
                itemBuilder: (_) {
                  return <PopupMenuEntry<int>>[
                    PopupMenuItem(
                      enabled: true,
                      value: _MENU_RESTART,
                      child: Text('restart'),
                    ),
                    PopupMenuItem(
                      enabled: true,
                      value: _MENU_UNDO,
                      child: Text('undo'),
                    ),
                    PopupMenuItem(
                      enabled: redoable,
                      value: _MENU_REDO,
                      child: Text('redo'),
                    ),
                  ];
                },
              );
            },
            buildWhen: (bool oldState, bool newState) {
              if (oldState != newState) return true;
              return false;
            },
          ),
        ],
      ),
      body: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LocalBoard(
              size: width,
            ),
            Container(
              width: width,
              height: 24,
              child: BlocBuilder<TurnCubit, TurnModel>(
                builder: (_, TurnModel turnModel) {
                  final bool isWhiteTurn = turnModel.isWhiteTurn;
                  final bool checkmate = turnModel.checkmate;
                  if (checkmate) {
                    return Center(
                      child: Text(
                        'checkmate, ${isWhiteTurn ? 'black' : 'white'} is winner',
                      ),
                    );
                  }
                  final Container colorTurnBar = Container(
                    width: width/3,
                    color: Colors.grey,
                  );
                  final Container transparentTurnBar = Container(
                    width: width/3,
                    color: Colors.transparent,
                  );
                  if (isWhiteTurn) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        colorTurnBar,
                        Text('white turn'),
                        transparentTurnBar,
                      ],
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        transparentTurnBar,
                        Text('black turn'),
                        colorTurnBar,
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSureDialog(BuildContext context, String title, String content, Function action) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          title: title == '' ? null : Text(title),
          content: content == '' ? null : Text(content),
          actions: [
            TextButton(
              onPressed: () {
                action();
                Navigator.pop(_);
              },
              child: Text('yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(_);
              },
              child: Text('no'),
            ),
          ],
        );
      }
    );
  }

}
