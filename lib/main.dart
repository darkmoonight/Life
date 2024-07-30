import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:life/utils/device_info.dart';
import 'package:time_machine/time_machine.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:life/app/data/diary.dart';
import 'package:life/app/modules/home.dart';
import 'package:life/app/modules/onboarding.dart';
import 'package:life/theme/theme.dart';
import 'package:life/theme/theme_controller.dart';
import 'package:life/translation/translation.dart';
import 'package:path_provider/path_provider.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

late Isar isar;
late Settings settings;

bool amoledTheme = false;
bool materialColor = false;
String timeformat = '24';
Locale locale = const Locale('en', 'US');

final List appLanguages = [
  {'name': 'English', 'locale': const Locale('en', 'US')},
  {'name': 'Русский', 'locale': const Locale('ru', 'RU')},
];

void main() async {
  final String timeZoneName;
  WidgetsFlutterBinding.ensureInitialized();
  DeviceFeature().init();
  if (Platform.isAndroid) {
    await setOptimalDisplayMode();
  }
  if (Platform.isAndroid || Platform.isIOS) {
    timeZoneName = await FlutterTimezone.getLocalTimezone();
  } else {
    timeZoneName = '${DateTimeZone.local}';
  }
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  await isarInit();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(const MyApp());
}

Future<void> setOptimalDisplayMode() async {
  final List<DisplayMode> supported = await FlutterDisplayMode.supported;
  final DisplayMode active = await FlutterDisplayMode.active;
  final List<DisplayMode> sameResolution = supported
      .where((DisplayMode m) =>
          m.width == active.width && m.height == active.height)
      .toList()
    ..sort((DisplayMode a, DisplayMode b) =>
        b.refreshRate.compareTo(a.refreshRate));
  final DisplayMode mostOptimalMode =
      sameResolution.isNotEmpty ? sameResolution.first : active;
  await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
}

Future<void> isarInit() async {
  isar = await Isar.open([
    SettingsSchema,
  ], directory: (await getApplicationSupportDirectory()).path);
  settings = isar.settings.where().findFirstSync() ?? Settings();

  if (settings.language == null) {
    settings.language = '${Get.deviceLocale}';
    isar.writeTxnSync(() => isar.settings.putSync(settings));
  }

  if (settings.theme == null) {
    settings.theme = 'system';
    isar.writeTxnSync(() => isar.settings.putSync(settings));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static Future<void> updateAppState(
    BuildContext context, {
    bool? newAmoledTheme,
    bool? newMaterialColor,
    String? newTimeformat,
    Locale? newLocale,
  }) async {
    final state = context.findAncestorStateOfType<_MyAppState>()!;

    if (newAmoledTheme != null) {
      state.changeAmoledTheme(newAmoledTheme);
    }
    if (newMaterialColor != null) {
      state.changeMarerialTheme(newMaterialColor);
    }
    if (newTimeformat != null) {
      state.changeTimeFormat(newTimeformat);
    }
    if (newLocale != null) {
      state.changeLocale(newLocale);
    }
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final themeController = Get.put(ThemeController());

  void changeAmoledTheme(bool newAmoledTheme) {
    setState(() {
      amoledTheme = newAmoledTheme;
    });
  }

  void changeMarerialTheme(bool newMaterialColor) {
    setState(() {
      materialColor = newMaterialColor;
    });
  }

  void changeTimeFormat(String newTimeformat) {
    setState(() {
      timeformat = newTimeformat;
    });
  }

  void changeLocale(Locale newLocale) {
    setState(() {
      locale = newLocale;
    });
  }

  @override
  void initState() {
    amoledTheme = settings.amoledTheme;
    materialColor = settings.materialColor;
    timeformat = settings.timeformat;
    locale = Locale(
        settings.language!.substring(0, 2), settings.language!.substring(3));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final edgeToEdgeAvailable = DeviceFeature().isEdgeToEdgeAvailable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: DynamicColorBuilder(
        builder: (lightColorScheme, darkColorScheme) {
          final lightMaterialTheme = lightTheme(
              lightColorScheme?.surface, lightColorScheme, edgeToEdgeAvailable);
          final darkMaterialTheme = darkTheme(
              darkColorScheme?.surface, darkColorScheme, edgeToEdgeAvailable);
          final darkMaterialThemeOled =
              darkTheme(oledColor, darkColorScheme, edgeToEdgeAvailable);

          return GetMaterialApp(
            theme: materialColor
                ? lightColorScheme != null
                    ? lightMaterialTheme
                    : lightTheme(
                        lightColor, colorSchemeLight, edgeToEdgeAvailable)
                : lightTheme(lightColor, colorSchemeLight, edgeToEdgeAvailable),
            darkTheme: amoledTheme
                ? materialColor
                    ? darkColorScheme != null
                        ? darkMaterialThemeOled
                        : darkTheme(
                            oledColor, colorSchemeDark, edgeToEdgeAvailable)
                    : darkTheme(oledColor, colorSchemeDark, edgeToEdgeAvailable)
                : materialColor
                    ? darkColorScheme != null
                        ? darkMaterialTheme
                        : darkTheme(
                            darkColor, colorSchemeDark, edgeToEdgeAvailable)
                    : darkTheme(
                        darkColor, colorSchemeDark, edgeToEdgeAvailable),
            themeMode: themeController.theme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            translations: Translation(),
            locale: locale,
            fallbackLocale: const Locale('en', 'US'),
            supportedLocales:
                appLanguages.map((e) => e['locale'] as Locale).toList(),
            debugShowCheckedModeBanner: false,
            home: settings.onboard ? const HomePage() : const OnBording(),
          );
        },
      ),
    );
  }
}
