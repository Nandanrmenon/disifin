import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData;

  ThemeNotifier(this._themeData);

  ThemeData get themeData => _themeData;

  Future<void> setSeedColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', color.value);
    _themeData = await getAppTheme();
    notifyListeners();
  }

  Future<void> setSchemeVariant(DynamicSchemeVariant variant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('schemeVariant', variant.index);
    _themeData = await getAppTheme();
    notifyListeners();
  }

  Future<void> setAmoledBackground(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('amoledBackground', value);
    _themeData = await getAppTheme();
    notifyListeners();
  }

  Future<Color> _loadSeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    return Color(prefs.getInt('seedColor') ?? Colors.red.value);
  }

  Future<DynamicSchemeVariant> _loadSchemeVariant() async {
    final prefs = await SharedPreferences.getInstance();
    final schemeVariantValue = prefs.getInt('schemeVariant') ?? 0;
    return DynamicSchemeVariant.values[schemeVariantValue];
  }

  Future<bool> _loadAmoledBackground() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('amoledBackground') ?? false;
  }
}

Future<ThemeData> getAppTheme() async {
  final themeNotifier = ThemeNotifier(ThemeData());
  final seedColor = await themeNotifier._loadSeedColor();
  final schemeVariant = await themeNotifier._loadSchemeVariant();
  final amoledBackground = await themeNotifier._loadAmoledBackground();
  return ThemeData(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface:
          amoledBackground ? Colors.black : const Color.fromRGBO(14, 14, 14, 1),
      outline: Colors.white10,
      outlineVariant: Colors.white10,
      dynamicSchemeVariant: schemeVariant,
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const FadeForwardsPageTransitionsBuilder(),
      ),
    ),
    iconTheme: const IconThemeData(fill: 0, weight: 300, color: Colors.white),
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor:
          amoledBackground ? Colors.black : const Color.fromRGBO(14, 14, 14, 1),
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      // systemOverlayStyle: SystemUiOverlayStyle(
      //   systemNavigationBarColor: amoledBackground
      //       ? Colors.black
      //       : const Color.fromRGBO(14, 14, 14, 1),
      //   systemNavigationBarIconBrightness: Brightness.light,
      //   systemNavigationBarDividerColor: Colors.transparent,
      //   statusBarColor: Colors.transparent,
      //   statusBarIconBrightness: Brightness.light,
      //   statusBarBrightness: Brightness.dark,
      // ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      // elevation: 2.0,
      backgroundColor: const Color.fromRGBO(14, 14, 14, 1),
      // labelType: NavigationRailLabelType.all,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: amoledBackground
          ? Colors.black
          : const Color.fromARGB(255, 20, 20, 20),
      indicatorShape: BeveledRectangleBorder(),
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStatePropertyAll(IconThemeData()),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.white,
      selectedLabelStyle:
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      enableFeedback: true,
      backgroundColor: amoledBackground
          ? Colors.black
          : const Color.fromARGB(255, 20, 20, 20),
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
}
