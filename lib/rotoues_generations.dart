import 'package:chess_game/LocalAreaNetwork/data/app_theme.dart';
import 'package:flutter/material.dart';
import 'routes.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chess',
      theme: AppTheme().light,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}