import 'package:chess_game/LocalAreaNetwork/data/model/game_search_information.dart';
import 'package:chess_game/LocalAreaNetwork/data/provider/game_scanner.dart';
import 'package:chess_game/LocalAreaNetwork/data/provider/network_info_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class GameScanCubit extends Cubit<GameScanState> {
  GameScanCubit() : super(GameScanState(
    searchStatus: SearchStatus.init,
    games: const [],
  ));

  /// return true if scan is successful
  Future<bool> startScan() async {
    emit(GameScanState(
      searchStatus: SearchStatus.searching,
      games: [],
    ));
    final String? inet = await NetworkInfoProvider().getInetAddress();
    final String? submask = await NetworkInfoProvider().getSubmask();
    if (inet == null) return false;
    if (submask == null) return false;
    emit(GameScanState(
      searchStatus: SearchStatus.searching,
      games: await GameScanner().scan(inet, submask),
    ));
    finishScan();
    return true;
  }

  finishScan() {
    emit(GameScanState(
      searchStatus: SearchStatus.searched,
      games: state.games,
    ));
  }
}

class GameScanState {
  final SearchStatus searchStatus;
  final List<GameSearchInformation> games;

  GameScanState({
    required this.searchStatus,
    required this.games,
  });
}

enum SearchStatus {
  init,
  searching,
  searched,
}