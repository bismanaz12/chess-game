import 'package:chess_game/LocalAreaNetwork/data/model/turn_model.dart';
import 'package:chess_game/LocalAreaNetwork/data/presentation/features/host_game/find_ip_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'host_bloc.dart';
import 'host_redoable_cubit.dart';
import 'host_state.dart';
import 'host_turn_cubit.dart';
import 'host_event.dart';
import 'host_board.dart';

class ScreenHostGame extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ScreenHostGameState();
}

class _ScreenHostGameState extends State<ScreenHostGame> {
  static const int _MENU_RESTART = 0x100;
  static const int _MENU_UNDO = 0x101;
  static const int _MENU_REDO = 0x102;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async {
        context.read<HostBloc>().add(HostStopEvent());
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('CHESS'),
          centerTitle: true,
          actions: [
            BlocBuilder<HostRedoableCubit, bool>(
              builder: (_, bool redoable) {
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
              }
            ),
          ],
        ),
        body: Column(
          children: [
            HostBoard(size: width,),
            BlocBuilder<HostTurnCubit, TurnModel>(
              builder: (_, TurnModel turnModel) {
                final bool isWhiteTurn = turnModel.isWhiteTurn;
                final bool checkmate = turnModel.checkmate;
                if (checkmate) return Container(
                  child: Text(
                    'checkmate, ${isWhiteTurn ? 'black' : 'white'} is winner',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                );
                return Container(
                  child: Text(
                    isWhiteTurn ? 'white turn' : 'black turn',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<FindIpCubit, String>(
              builder: (_, String hostName) {
                return Text(
                  hostName,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                );
              },
            ),
            BlocBuilder<HostBloc, HostState>(
              builder: (_, state) {
                if (state is HostLoadedState) {
                  return _clientInformationText(context, state.clientInformation);
                }
                else {
                  return Container();
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                context.read<HostBloc>().add(HostKickGuestEvent());
              },
              child: Text('Kick guest'),
            ),
          ],
        ),
        backgroundColor: Colors.black45,
      ),
    );
  }

  Widget _clientInformationText(BuildContext context, String? data) {
    return Text(
      data ?? 'no guest connected',
      style: TextStyle(
        color: Colors.white,
      ),
    );
  }

  void _onMenuItemSelected(int choice) {
    switch (choice) {
      case _MENU_RESTART:
        _showSureDialog(context, 'Are you sure to restart game', '', () {
          context.read<HostBloc>().add(HostLoadEvent(restart: true));
        });
        break;
      case _MENU_UNDO:
        context.read<HostBloc>().add(HostUndoEvent());
        break;
      case _MENU_REDO:
        context.read<HostBloc>().add(HostRedoEvent());
        break;
      default: break; 
    }
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