import 'package:chess_game/controller/base_chess_controller.dart';
import 'package:chess_game/controller/movement_vector.dart';
import 'package:flutter/material.dart';

import '../extensions/extensions.dart';
import 'enums.dart';

class ChessController extends BaseChessController {
  ChessController(
      {this.moveDoneCallback,
      this.checkCallback,
      this.checkMateCallback,
      this.gameDrawCallback,
      String? fenString,
      String? pgnString,
      this.computerColor}) {
    reset(fenString: fenString, pgnString: pgnString);
  }

  /// Callback executed when move is done.
  final Future<void> Function()? moveDoneCallback;

  /// Callback executed when player is checked.
  final Function(PieceColor playerColor)? checkCallback;

  /// Checkmate callback.
  final Function(PieceColor playerColor)? checkMateCallback;

  /// Game draw callback.
  final VoidCallback? gameDrawCallback;

  /// Game board representation.
  late List<List<PieceType?>> _board;

  /// All moves during the game are stored in this list.
  final List<String> _moveList = [];

  /// Computer player color.
  final PieceColor? computerColor;

  /// Current player checked.
  bool currentPlayerChecked = false;

  // Some game properties to keep track of.
  late bool blackKingSideCastleRestricted;
  late bool blackQueenSideCastleRestricted;

  late bool whiteKingSideCastleRestricted;
  late bool whiteQueenSideCastleRestricted;

  late bool _isGameEnded;
  late bool _isWhiteTurn;

  // Current player legal moves.
  List<List<String>> legalMovesForCurrentPlayer = [];

  // Reset game.
  void reset({String? fenString, String? pgnString}) {
    _board = List.generate(8, (_) => List.generate(8, (_) => null));

    if (pgnString == null) {
      _loadGameFromFenString(
          fenString ?? BaseChessController.initialFenString());
    } else {
      _loadGameFromPGNString(pgnString);
    }

    // Clear the move list.
    _moveList.clear();

    // Set game properties;
    blackKingSideCastleRestricted = false;
    blackQueenSideCastleRestricted = false;

    whiteKingSideCastleRestricted = false;
    whiteQueenSideCastleRestricted = false;

    _isGameEnded = false;
    _isWhiteTurn = true;

    // Update legal moves for current player.
    _updateLegalMovesForCurrentPlayer();

    // Update checked property.
    currentPlayerChecked = false;
  }

  // End game.
  void dispose() {
    _isGameEnded = true;
  }

  // Scene refresh callback.
  VoidCallback? sceneRefreshCallback;

  // Use getter to expose private properties.
  List<List<PieceType?>> get board => _board;
  List<String> get moveList => _moveList;
  PieceColor get currentTurnColor =>
      _isWhiteTurn ? PieceColor.white : PieceColor.black;

  String get currentPlayerKingPos => BaseChessController.findPieceLocations(
          board: _board,
          piece: currentTurnColor == PieceColor.white
              ? PieceType.whiteKing
              : PieceType.blackKing)
      .first;

  bool get isWhiteTurn => _isWhiteTurn;
  bool get isGameEnded => _isGameEnded;

  bool get canWhiteKingSideCastle =>
      _isWhiteTurn &&
      !whiteKingSideCastleRestricted &&
      _board[0][5] == null &&
      _board[0][6] == null;

  bool get canWhiteQueenSideCastle =>
      _isWhiteTurn &&
      !whiteQueenSideCastleRestricted &&
      board[0][1] == null &&
      _board[0][2] == null &&
      _board[0][3] == null;

  bool get canBlackKingSideCastle =>
      !_isWhiteTurn &&
      !blackKingSideCastleRestricted &&
      _board[7][5] == null &&
      _board[7][6] == null;

  bool get canBlackQueenSideCastle =>
      !_isWhiteTurn &&
      !blackQueenSideCastleRestricted &&
      board[7][1] == null &&
      _board[7][2] == null &&
      _board[7][3] == null;

  String get gamePGN {
    List<String> pgnList = [];
    int n = 0;
    for (int i = 0; i < _moveList.length; i++) {
      if (i % 2 == 0) {
        pgnList.add((++n).toString() + '.');
      }
      pgnList.add(_moveList[i]);
    }
    return pgnList.join(" ");
  }

  // Call this method in your scene.
  void updateSceneRefreshCallback(VoidCallback sceneRefreshCallback) =>
      this.sceneRefreshCallback = sceneRefreshCallback;

  void undoMove() {
    // Remove last move from the Move List.
    if (moveList.isNotEmpty) {
      _moveList.removeLast();
      // Need to undo one more move if game is singleplayer and computer has played its turn.
      if (computerColor != null && currentTurnColor != computerColor) {
        _moveList.removeLast();
      }
      _loadGameFromPGNString(gamePGN);
    }
  }

  void makeMove({
    required String fromPos,
    required String toPos,
    bool executeCheckCallback = true,
  }) {
    List<int> fromLoc = BaseChessController.positionToLocation(fromPos);
    List<int> toLoc = BaseChessController.positionToLocation(toPos);

    PieceType? piece = _board[fromLoc.first][fromLoc.last];

    // no. of row & columns displaced respectively, while moving the piece.
    int xMoveDisplacement = toLoc.last - fromLoc.last;
    // int yMoveDisplacement = toLoc.first - fromLoc.first;

    // Check if a valid piece can be moved.
    if (legalMovesForCurrentPlayer
        .any((move) => move.first == fromPos && move.last == toPos)) {
      // Castling move check.
      bool castlingMove = false;
      bool enPassantMove = false;

      if ((piece! == PieceType.whiteKing || piece == PieceType.blackKing) &&
          xMoveDisplacement.abs() > 1) {
        castlingMove = true;

        if (xMoveDisplacement < 0) {
          // Queen Side Castle.
          _board[fromLoc.first][0] = null;
          _board[fromLoc.first][3] =
              _isWhiteTurn ? PieceType.whiteRook : PieceType.blackRook;
        } else {
          // King Side Castle.
          _board[fromLoc.first][7] = null;
          _board[fromLoc.first][5] =
              _isWhiteTurn ? PieceType.whiteRook : PieceType.blackRook;
        }
      }

      // En-Passant move check.
      if ((piece == PieceType.whitePawn || piece == PieceType.blackPawn) &&
          _board[toLoc.first][toLoc.last] == null &&
          xMoveDisplacement.abs() > 0) {
        _board[fromLoc.first][fromLoc.last + xMoveDisplacement] = null;
        enPassantMove = true;
      }

      // Add move to the move list.
      _moveList.add((BaseChessController.convertMoveToAlgebricNotation(
        board: board,
        fromLoc: fromLoc,
        toLoc: toLoc,
        castlingMove: castlingMove,
        enPassantMove: enPassantMove,
      )));

      // Update board.
      _movePiece(piece: piece, loc: toPos);
      _board[fromLoc.first][fromLoc.last] = null;

      // Update turn.
      _isWhiteTurn = !_isWhiteTurn;

      // Update castling restrictions.
      _updateCastlingRestrictions(fromPos);

      // Check if pawn can be transformed to higher value piece.
      _pawnTransfromConditionCheck();

      // Update legal moves.
      _updateLegalMovesForCurrentPlayer(
          executeCheckCallback: executeCheckCallback);

      // Move done callback.
      if (moveDoneCallback != null) {
        moveDoneCallback!();
      }

      // Scene refresh callback.
      if (sceneRefreshCallback != null) {
        sceneRefreshCallback!();
      }
    }
  }

  // Return legal moves for selected pos
  List<String> getLegalMovesForSelectedPos(String pos) {
    return legalMovesForCurrentPlayer
        .where((move) => move.first == pos)
        .map((move) => move.last)
        .toList();
  }

  //-----------------------------** Private Methods **----------------------------//

  void _movePiece({
    required PieceType piece,
    required String loc,
  }) {
    List<int> locationIndex = BaseChessController.positionToLocation(loc);
    int row = locationIndex[0];
    int col = locationIndex[1];

    _board[row][col] = piece;
  }

  void _loadGameFromFenString(String fenString) {
    List<String> boardConfig = fenString.split(' ').first.split('/');

    for (int i = 0; i < 8; i++) {
      int offset = 0;
      for (int j = 0; j < boardConfig[i].length; j++) {
        int? nSkip = int.tryParse(boardConfig[i][j]);

        if (nSkip == null) {
          _movePiece(
              piece: BaseChessController.fenCharToPieceType(boardConfig[i][j]),
              loc: '${BaseChessController.files[j + offset]}${8 - i}');
        } else {
          offset += nSkip - 1;
        }
      }
    }
  }

  void _loadGameFromPGNString(String pgnString) {
    reset();

    if (pgnString.isEmpty) {
      if (sceneRefreshCallback != null) {
        sceneRefreshCallback!();
      }
      return;
    }

    List<String> moveList = pgnString.split(RegExp(r'\s+'))
      ..removeWhere((e) => e.last == '.');

    String? initialPos;
    PieceType pieceType;
    String finalPos;

    for (int i = 0; i < moveList.length; i++) {
      // King side castle.
      if (moveList[i] == '0-0') {
        makeMove(
            fromPos: i % 2 == 0 ? 'e1' : 'e8', toPos: i % 2 == 0 ? 'g1' : 'g8');
        continue;
      }
      // Queen side castle.
      if (moveList[i] == '0-0-0') {
        makeMove(
            fromPos: i % 2 == 0 ? 'e1' : 'e8', toPos: i % 2 == 0 ? 'c1' : 'c8');
        continue;
      }

      finalPos = moveList[i].substring(moveList[i].length - 2);

      // Get piece type
      if (moveList[i].length > 2 && moveList[i].contains(RegExp(r'[A-Z]'))) {
        String chessPiece =
            BaseChessController.fenCharToPieceType(moveList[i].first)
                .toString()
                .split('.')
                .last
                .substring(5);
        String chessPieceType =
            i % 2 == 0 ? 'white' + chessPiece : 'black' + chessPiece;
        pieceType = PieceType.values.firstWhere(
            (element) => element.toString().split('.').last == chessPieceType);
      } else {
        pieceType = i % 2 == 0 ? PieceType.whitePawn : PieceType.blackPawn;
      }

      // Find initial position.
      for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
          String pos = BaseChessController.locationToPosition([row, col]);
          if (_board[row][col] == pieceType &&
              _getPseudoLegalMovesForSelectedPos(pos).contains(finalPos)) {
            initialPos = pos;
          }
        }
      }

      // Finally if pgn is valid, make move.
      if (initialPos != null) {
        makeMove(
            fromPos: initialPos, toPos: finalPos, executeCheckCallback: false);
      } else {
        return;
      }
    }
  }

  // Check if pawn can be transformed to queen.
  void _pawnTransfromConditionCheck() {
    for (int i = 0; i < 8; i++) {
      if (_board[0][i] == PieceType.blackPawn) {
        _board[0][i] = PieceType.blackQueen;
      }

      if (_board[7][i] == PieceType.whitePawn) {
        _board[7][i] = PieceType.whiteQueen;
      }
    }
  }

  // Castling allowed only if king and rook are not moved from their original positions during the game.
  void _updateCastlingRestrictions(String pos) {
    if (pos == 'h1' || pos == 'e1') {
      whiteKingSideCastleRestricted = true;
    }
    if (pos == 'a1' || pos == 'e1') {
      whiteQueenSideCastleRestricted = true;
    }
    if (pos == 'h8' || pos == 'e8') {
      blackKingSideCastleRestricted = true;
    }
    if (pos == 'a8' || pos == 'e8') {
      blackQueenSideCastleRestricted = true;
    }
  }

  /// Updates legal moves for the current player.
  void _updateLegalMovesForCurrentPlayer({bool executeCheckCallback = true}) {
    // Get the current player king position.
    String kingPos = currentPlayerKingPos;

    // Update current player checked property.
    currentPlayerChecked = _getPseudoLegalMovesforPlayer(
            currentTurnColor == PieceColor.black
                ? PieceColor.white
                : PieceColor.black)
        .any((move) => move.last == kingPos);

    List<List<String>> currentPlayerLegalMoves =
        _getPseudoLegalMovesforPlayer(currentTurnColor);

    List<List<PieceType?>> altBoard = board;

    // Play the move and see if the king can be saved.
    int itr = -1;
    while (++itr < currentPlayerLegalMoves.length) {
      List<int> initialLoc = BaseChessController.positionToLocation(
          currentPlayerLegalMoves[itr].first);
      List<int> finalLoc = BaseChessController.positionToLocation(
          currentPlayerLegalMoves[itr].last);

      PieceType? initialPiece = altBoard[initialLoc.first][initialLoc.last];
      PieceType? finalPiece = altBoard[finalLoc.first][finalLoc.last];

      altBoard[initialLoc.first][initialLoc.last] = null;
      altBoard[finalLoc.first][finalLoc.last] = initialPiece;

      PieceColor attackingPlayer = currentTurnColor == PieceColor.white
          ? PieceColor.black
          : PieceColor.white;

      // If the king is moved, find its position.
      String nextKingPos = (initialPiece == PieceType.blackKing ||
              initialPiece == PieceType.whiteKing)
          ? currentPlayerLegalMoves[itr].last
          : kingPos;

      if (_getPseudoLegalMovesforPlayer(attackingPlayer, altBoard: altBoard)
          .any((threatMove) => threatMove.last == nextKingPos)) {
        currentPlayerLegalMoves.removeAt(itr--);
      }

      // Reset board.
      altBoard[initialLoc.first][initialLoc.last] = initialPiece;
      altBoard[finalLoc.first][finalLoc.last] = finalPiece;
    }

    // Check if game has ended, and further conclude.
    if (!currentPlayerChecked && currentPlayerLegalMoves.isEmpty) {
      _isGameEnded = true;
      if (gameDrawCallback != null) {
        gameDrawCallback!();
      }
    } else if (currentPlayerChecked && currentPlayerLegalMoves.isEmpty) {
      _isGameEnded = true;
      if (checkMateCallback != null) {
        checkMateCallback!(currentTurnColor);
      }
    } else if (currentPlayerChecked && currentPlayerLegalMoves.isNotEmpty) {
      _isGameEnded = true;
      if (executeCheckCallback && checkCallback != null) {
        checkCallback!(currentTurnColor);
      }
    }

    legalMovesForCurrentPlayer = currentPlayerLegalMoves;
  }

  /// Returns all pseudo legal moves for the specified player.
  List<List<String>> _getPseudoLegalMovesforPlayer(PieceColor playerColor,
      {List<List<PieceType?>>? altBoard}) {
    List<List<String>> legalMoves = [];
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        PieceType? piece = (altBoard ?? _board)[row][col];
        if (piece != null &&
            BaseChessController.getPieceTypeColor(piece) == playerColor) {
          final String initialPos =
              BaseChessController.locationToPosition([row, col]);

          _getPseudoLegalMovesForSelectedPos(initialPos).forEach((finalPos) {
            legalMoves.add([initialPos, finalPos]);
          });
        }
      }
    }
    return legalMoves;
  }

  /// Returns all pseudo legal moves for the selected position.
  List<String> _getPseudoLegalMovesForSelectedPos(String pos,
      {List<List<PieceType?>>? altBoard}) {
    List<int> locationIndex = BaseChessController.positionToLocation(pos);
    PieceType? piece =
        (altBoard ?? _board)[locationIndex.first][locationIndex.last];

    List<String> legalMoves = [];

    if (piece != null) {
      MovementVector boardPiece = pieceMovementOffset[piece]!;

      legalMoves = boardPiece.directionalOffsets(
          board: altBoard ?? _board, moveList: _moveList, pos: pos);

      // Castling moves.
      // If current player's king is not checked, only then he can castle.
      if (!currentPlayerChecked) {
        if (canWhiteKingSideCastle && piece == PieceType.whiteKing) {
          legalMoves.add('g1');
        }
        if (canWhiteQueenSideCastle && piece == PieceType.whiteKing) {
          legalMoves.add('c1');
        }
        if (canBlackKingSideCastle && piece == PieceType.blackKing) {
          legalMoves.add('g8');
        }
        if (canBlackQueenSideCastle && piece == PieceType.blackKing) {
          legalMoves.add('c8');
        }
      }
    }

    return legalMoves;
  }
}
