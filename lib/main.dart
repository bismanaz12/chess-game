import 'package:chess_game/screens/main_menu/main_menu_screen.dart';
import 'package:chess_game/theme.dart';
import 'package:flutter/material.dart';

import 'config/custom_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({Key? key}) : super(key: key);

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Chess',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: CustomRouter.onGenerateRoute,
      initialRoute: MainMenuScreen.routeName,
      theme: themeData,
    );
  }
}
