import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  visualDensity: VisualDensity.adaptivePlatformDensity,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 102, 243, 170),
    brightness: Brightness.dark,
    surface: Colors.black,
    outline: Colors.white10,
    outlineVariant: Colors.white10,
    dynamicSchemeVariant: DynamicSchemeVariant.content,
  ),
  useMaterial3: true,
  sliderTheme: SliderThemeData(
    trackHeight: 10,
    activeTrackColor: Colors.white,
    inactiveTrackColor: Colors.grey,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  chipTheme: ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    selectedIconTheme: IconThemeData(size: 30),
    unselectedIconTheme: IconThemeData(size: 24),
    selectedLabelStyle: const TextStyle(fontSize: 12),
    unselectedLabelStyle: const TextStyle(fontSize: 10),
  ),
  listTileTheme: ListTileThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
);
