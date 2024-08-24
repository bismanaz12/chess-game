import 'package:chess_game/screens/game/game_screen.dart';
import 'package:chess_game/screens/main_menu/main_menu_screen.dart';
import 'package:chess_game/screens/option/option_screen.dart';
import 'package:chess_game/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

class CustomRouter {
  static Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
            settings: const RouteSettings(name: '/'),
            builder: (_) => const Scaffold());
      case SplashScreen.routeName:
        return SplashScreen.route();
      case MainMenuScreen.routeName:
        return MainMenuScreen.route();

      case OptionScreen.routeName:
        return OptionScreen.route(
            options: settings.arguments as Map<String, bool>);

      case GameScreen.routeName:
        return GameScreen.route(
            options: settings.arguments as Map<String, dynamic>);
      default:
        return _errorRoute();
    }
  }

  static Route _errorRoute() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: '/error'),
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Something went wrong!'),
        ),
      ),
    );
  }
}
