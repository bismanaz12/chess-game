import 'dart:io';
import 'dart:typed_data';
import 'package:chess/chess.dart' as ch;
import 'package:chess_game/LocalAreaNetwork/data/config.dart';
import 'package:chess_game/LocalAreaNetwork/data/model/last_move_model.dart';
import 'package:chess_game/LocalAreaNetwork/data/presentation/features/host_game/find_ip_cubit.dart';
import 'package:chess_game/LocalAreaNetwork/data/provider/socket_communicator.dart';
import 'package:chess_game/LocalAreaNetwork/data/storage_manager.dart';
import 'package:chess_game/utilis.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../dialogs/choose_promotion_dialog.dart';
import 'host_redoable_cubit.dart';
import 'host_turn_cubit.dart';
import 'host_event.dart';
import 'host_state.dart';

class HostBloc extends Bloc<HostEvent, HostState> {
  HostBloc(
    this.hostRedoableCubit,
    this.findIpCubit,
    this.hostTurnCubit,
  ) : super(HostInitialState()) {
    for (int i = 0; i < 8; i++) {
      pieceBoard.add([]);
      for (int j = 0; j < 8; j++) {
        pieceBoard[i].add(ch.Piece(ch.PieceType.PAWN, ch.Color.WHITE));
      }
    }
  }

  final HostRedoableCubit hostRedoableCubit;
  final FindIpCubit findIpCubit;
  final HostTurnCubit hostTurnCubit;

  ServerSocket? serverSocket;
  Socket? clientSocket;

  ch.Chess? chess;
  List<List<ch.Piece?>> pieceBoard = [];
  Set<String> movablePiecesCoors = Set();
  LastMoveModel? lastMove;
  List<String> undoStateHistory = [];
  
  HostLoadedState _state({String? focusCoordinate, Set<String>? movableCoors}) {
    return HostLoadedState(
      board: pieceBoard,
      movablePiecesCoors: movablePiecesCoors,
      isWhiteTurn: chess!.turn == ch.Color.WHITE,
      inCheck: chess!.in_check,
      lastMoveFrom: lastMove?.from,
      lastMoveTo: lastMove?.to,
      fen: chess!.fen,
      clientInformation: clientSocket?.remoteAddress.address.toString(),
      focusedCoordinate: focusCoordinate ?? null,
      movableCoors: movableCoors ?? const {},
    );
  }

  bool get isFocused {
    return state is HostLoadedState
        && (state as HostLoadedState).focusedCoordinate != null;
  }

  @override
  Stream<HostState> mapEventToState(HostEvent event) async* {

    if (event is HostLoadEvent) {
      if (event.restart || (await StorageManager().lastHostGameFen) == null) {
        await StorageManager().setLastHostGameFen(null);
        await StorageManager().setHostBoardStateHistory([]);
        lastMove = LastMoveModel(from: '', to: '');
        StorageManager().setLastHostGameLastMove(lastMove);
        chess = ch.Chess();
        undoStateHistory.clear();
        hostRedoableCubit.nonRedoable();
        if (clientSocket != null) {
          send(clientSocket!, SendBoard(
            fen: chess!.fen,
            lastMoveFrom: lastMove?.from ?? '',
            lastMoveTo: lastMove?.to ?? '',
          ));
        }
      } else {
        chess = ch.Chess.fromFEN((await StorageManager().lastHostGameFen)!);
        lastMove = (await StorageManager().lastHostGameLastMove)!;
      }
      if (chess == null) throw 'chess is not initialized';

      findMovablePiecesCoors();
      convertToPieceBoard();

      print('new loaded state');
      hostTurnCubit.changeState(chess!.turn == ch.Color.WHITE, chess!.in_checkmate);
      yield _state();
    }

    else if (event is HostStartEvent) {
      if (chess == null) throw 'chess is not initialized';
      for (int portNumber in portsWithPriority) {
        try {
          await startSocketServerOn(portNumber);
          break;
        } on SocketException {}
      }
      print('LocalHostConnectEvent event, ip: ${serverSocket?.address.toString()}:${serverSocket?.port.toString()}');
      findIpCubit.defineIpAndPortNum(serverSocket!.port);
      serverSocket!.listen((Socket socket) {
        print('new connection');
        socket.listen((Uint8List dataAsByte) {
          String s = new String.fromCharCodes(dataAsByte);
          print(s);
          ActionType action = decodeRawData(s);
          if (action is CheckConnectivity) {
            send(socket, SendConnectivityState(ableToConnect: clientSocket == null));
          } else if (action is RequestConnection) {
            if (clientSocket == null) {
              clientSocket = socket;
            }
            add(HostLoadEvent());
            send(socket, SendBoard(
              fen: chess!.fen,
              lastMoveFrom: lastMove?.from ?? '',
              lastMoveTo: lastMove?.to ?? '',
            ));
          } else if (action is RequestBoard) {
            send(socket, SendBoard(
              fen: chess!.fen,
              lastMoveFrom: lastMove?.from ?? '',
              lastMoveTo: lastMove?.to ?? '',
            ));
          } else if (action is SendMove) {
            if (socket != clientSocket) return;
            final String from = action.from;
            final String to = action.to;
            final String? promotion = action.promotion;
            if (chess!.turn == ch.Color.BLACK && movablePiecesCoors.contains(from)) {
              add(HostMoveEvent(
                from: from,
                to: to,
                promotion: promotion,
              ));
            }
          } else if (action is SendDisconnectSignal) {
            socket.destroy();
            if (socket == clientSocket) {
              print('guest disconnected');
              clientSocket = null;
            }
            add(HostLoadEvent());
          } else {
            throw 'undefined action';
          }
        });
      });
    }

    else if (event is HostStopEvent) {
      if (serverSocket != null) serverSocket!.close();
      serverSocket = null;
      if (clientSocket != null) clientSocket!.destroy();
      clientSocket = null;
      print('server stopped');
    }

    else if (event is HostFocusEvent) {
      if (chess == null) throw 'chess is not initialized';
      final Set<String> movableCoors = Set();
      for (ch.Move move in chess!.generate_moves()) {
        //print('from: ${move.from} | fromAlgebraic: ${move.fromAlgebraic} | to: ${move.to} | toAlgebraic: ${move.toAlgebraic} | color: ${move.color} | piece: ${move.piece} | flags: ${move.flags} | promotion: ${move.promotion} | captured: ${move.captured}');
        if (move.fromAlgebraic == event.focusCoordinate) {
          movableCoors.add(move.toAlgebraic);
        }
      }
      hostTurnCubit.changeState(chess!.turn == ch.Color.WHITE, chess!.in_checkmate);
      yield _state(
        focusCoordinate: event.focusCoordinate,
        movableCoors: movableCoors,
      );
    }
    
    else if (event is HostRemoveTheFocusEvent) {
     if (chess == null) throw 'chess is not initialized';
      if (!isFocused) {
        throw Exception('trying to remove focus while state is not focused state. (state is ${state.runtimeType}');
      }

      yield _state();
    }

    else if (event is HostMoveEvent) {
      if (chess == null) throw 'chess is not initialized';
      if (!isFocused && event.from == '') {
        throw Exception('trying move from this device while state is not focused state. (state is ${state.runtimeType}');
      }

      final String from = event.from == '' ? (state as HostLoadedState).focusedCoordinate! : event.from;
      final String to = event.to;

      final bool moving = to != from;
      if (moving) {
        await move(event.context, from, to, event.promotion);
        convertToPieceBoard();
        findMovablePiecesCoors();
        StorageManager().setLastHostGameFen(chess!.fen);
        lastMove = LastMoveModel(from: from, to: to);
        StorageManager().setLastHostGameLastMove(lastMove);
        final String stateBundle = fenAndLastMoveToBundleString(chess!.fen, lastMove.toString());
        StorageManager().addHostBoardStateHistory(stateBundle);
        hostRedoableCubit.nonRedoable();
        if (clientSocket != null) {
          send(clientSocket!, SendBoard(
            fen: chess!.fen,
            lastMoveFrom: lastMove?.from ?? '',
            lastMoveTo: lastMove?.to ?? '',
          ));
        }
      }

      hostTurnCubit.changeState(chess!.turn == ch.Color.WHITE, chess!.in_checkmate);
      yield _state();
    }
 
    else if (event is HostUndoEvent) {
      if (chess == null) throw 'chess is not initialized';
      if ((await StorageManager().hostBoardStateHistory).length > 0) {
        undoStateHistory.add(await StorageManager().removeLastFromHostBoardStateHistory());
        String currentState;
        try {
          currentState = (await StorageManager().hostBoardStateHistory).last;
        } on StateError {
          currentState = ch.Chess.DEFAULT_POSITION + '#/';
        }
        hostRedoableCubit.redoable();
        lastMove = getLastMoveFromBundleString(currentState);
        final String fen = getFenFromBundleString(currentState);
        StorageManager().setLastHostGameLastMove(lastMove);
        StorageManager().setLastHostGameFen(chess!.fen);
        chess!.load(fen);
      }
      if (clientSocket != null) {
        send(clientSocket!, SendBoard(
          fen: chess!.fen,
          lastMoveFrom: lastMove?.from ?? '',
          lastMoveTo: lastMove?.to ?? '',
        ));
      }
      findMovablePiecesCoors();
      convertToPieceBoard();

      hostTurnCubit.changeState(chess!.turn == ch.Color.WHITE, chess!.in_checkmate);
      yield _state();
    }
 
    else if (event is HostRedoEvent) {
      if (chess == null) throw 'chess is not initialized';
      if (undoStateHistory.length == 0) {
        print('no undo');
      } else {
        final String lastUndoState = undoStateHistory.removeLast();
        final String fen = getFenFromBundleString(lastUndoState);
        chess!.load(fen);

        if (clientSocket != null) {
          send(clientSocket!, SendBoard(
            fen: chess!.fen,
            lastMoveFrom: lastMove?.from ?? '',
            lastMoveTo: lastMove?.to ?? '',
          ));
        }

        if (undoStateHistory.length == 0) {
          hostRedoableCubit.nonRedoable();
        }
        lastMove = getLastMoveFromBundleString(lastUndoState);
        StorageManager().setLastHostGameLastMove(lastMove);
        StorageManager().setLastHostGameFen(chess!.fen);
        StorageManager().addHostBoardStateHistory(fenAndLastMoveToBundleString(fen, lastMove.toString()));
        findMovablePiecesCoors();
        convertToPieceBoard();

        hostTurnCubit.changeState(chess!.turn == ch.Color.WHITE, chess!.in_checkmate);
        yield _state();
      }
    }

    else if (event is HostKickGuestEvent) {
      if (clientSocket != null) {
        send(clientSocket!, SendKick());
        clientSocket!.close();
        clientSocket = null;
        yield _state();
      }
    }

  }

  startSocketServerOn(int portNumber) async {
    serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, portNumber);
  }
  
  Map<String, String> queryToMap(String query) {
    int keyStartIndex = query.indexOf('?') + 1;
    if (keyStartIndex == 0) return Map();
    int valueStartIndex = query.indexOf('=') + 1;
    int nextKeyStartIndex = query.indexOf('&') + 1;
    Map<String, String> result = Map();
    while(true) {
      result[query.substring(keyStartIndex, valueStartIndex-1)] 
        = query.substring(valueStartIndex, nextKeyStartIndex == 0 ? null : nextKeyStartIndex-1);
      if (nextKeyStartIndex == 0) break;
      keyStartIndex = nextKeyStartIndex;
      valueStartIndex = query.indexOf('=', nextKeyStartIndex) + 1;
      nextKeyStartIndex = query.indexOf('&', valueStartIndex) + 1;
    }
    return result;
  }


  Future move(BuildContext? context, String from, String to, String? promotion) async {
    if (chess == null) throw 'chess is not initialized';
    ch.Move? thisMove;
    Set<ch.Move> possibleMoves = {};
    List<String> promotions = [];
    for (ch.Move move in chess!.generate_moves()) {
      if (
        move.fromAlgebraic == from
        && move.toAlgebraic == to
      ) {
        possibleMoves.add(move);
      }
    }
    for (ch.Move move in possibleMoves) {
      if (move.promotion != null) {
        promotions.add(move.promotion!.name);
      }
    }
    if (promotions.isNotEmpty) {
      final String? selectedPieceCode = promotion ?? await showPromotionDialog(context!, promotions);
      for (ch.Move move in possibleMoves) {
        if (move.promotion?.name == selectedPieceCode) {
          thisMove = move;
          break;
        }
      }
    } else if (possibleMoves.length == 1) {
      thisMove = possibleMoves.elementAt(0);
    } else {
      throw Exception('unexpected state when move');
    }
    if (thisMove == null) throw Exception('unknown move');
    chess!.move(thisMove);
  }

  void convertToPieceBoard() {
    if (chess == null) throw 'chess is not initialized';
    for(int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
        pieceBoard[x][y] = chess!.board[(x + (7-y)*16)];
      }
    }
  }

  void findMovablePiecesCoors() {
    if (chess == null) throw 'chess is not initialized';
    List moves = chess!.generate_moves();
    movablePiecesCoors.clear();
    for (ch.Move move in moves) {
      movablePiecesCoors.add(move.fromAlgebraic);
    }
    //print('movablePiecesCoors: $movablePiecesCoors');
  }

}