import 'package:chess_game/constants.dart';
import 'package:flutter/material.dart';


ThemeData themeData = ThemeData(
  fontFamily: kFontFamily,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  scaffoldBackgroundColor: kPrimaryColor,
  appBarTheme: AppBarTheme(
    iconTheme: IconThemeData(
      color: Colors.black.withOpacity(kBlackOpacity),
    ),
    color: kPrimaryColor,
    titleTextStyle: TextStyle(
      fontFamily: kFontFamily,
      color: Colors.black.withOpacity(kBlackOpacity),
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.zero, backgroundColor: Colors.black.withOpacity(kBlackOpacity),
      elevation: 0,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
    labelStyle: const TextStyle(
      fontSize: 18,
      color: kSecondaryColor,
    ),
    floatingLabelStyle: TextStyle(
      fontSize: 18,
      color: Colors.black.withOpacity(kBlackOpacity),
    ),
    enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            width: kBorderWidth,
            color: Colors.black.withOpacity(kBlackOpacity))),
    focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
            width: kBorderWidth,
            color: Colors.black.withOpacity(kBlackOpacity))),
  ),
  sliderTheme: ThemeData.dark().sliderTheme.copyWith(
        activeTrackColor: Colors.black.withOpacity(kBlackOpacity / 1.5),
        overlayColor: Colors.transparent,
        thumbColor: kIconColor,
        inactiveTrackColor: kSecondaryColor,
      ),
  switchTheme: SwitchThemeData(
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.isNotEmpty && states.first == MaterialState.selected) {
        return Colors.black.withOpacity(kBlackOpacity / 1.5);
      }
      return kSecondaryColor;
    }),
    thumbColor: MaterialStateProperty.resolveWith(
      (states) {
        if (states.isNotEmpty && states.first == MaterialState.selected) {
          return kIconColor;
        }
        return Color.alphaBlend(
            Colors.black.withOpacity(kBlackOpacity / 1.5), kPrimaryColor);
      },
    ),
  ),
  radioTheme: RadioThemeData(
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    fillColor: MaterialStateProperty.resolveWith(
      (states) {
        if (states.isNotEmpty && states.first == MaterialState.selected) {
          return kIconColor;
        }
        return Color.alphaBlend(
            Colors.black.withOpacity(kBlackOpacity / 1.5), kPrimaryColor);
      },
    ),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      color: Colors.black.withOpacity(kBlackOpacity),
      fontWeight: FontWeight.bold,
      fontSize: 40,
      letterSpacing: 2,
    ),
    displayMedium: const TextStyle(
      color: kPrimaryColor,
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
    displaySmall: TextStyle(
      color: Colors.black.withOpacity(kBlackOpacity),
      fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
  ),
);
