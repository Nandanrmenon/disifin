import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  visualDensity: VisualDensity.adaptivePlatformDensity,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 243, 102, 156),
    brightness: Brightness.dark,
    surface: Colors.black,
    outline: Colors.white10,
    outlineVariant: Colors.white10,
    dynamicSchemeVariant: DynamicSchemeVariant.content,
  ),
  pageTransitionsTheme: PageTransitionsTheme(
    builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
      TargetPlatform.values,
      value: (_) => const FadeForwardsPageTransitionsBuilder(),
    ),
  ),
  iconTheme: const IconThemeData(fill: 0, weight: 300, color: Colors.white),
  useMaterial3: true,
  // sliderTheme: SliderThemeData(
  //   trackHeight: 10,
  //   // activeTrackColor: Colors.white,
  //   // inactiveTrackColor: Colors.grey,
  // ),
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
    selectedIconTheme: IconThemeData(size: 26),
    unselectedIconTheme: IconThemeData(size: 26),
    selectedLabelStyle: const TextStyle(fontSize: 12),
    unselectedLabelStyle: const TextStyle(fontSize: 12),
    backgroundColor: Colors.transparent,
    enableFeedback: true,
  ),
  listTileTheme: ListTileThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white12,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  ),
);
