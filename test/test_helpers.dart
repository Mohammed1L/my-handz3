import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;

class InMemoryAssetLoader extends AssetLoader {
  final Map<String, Map<String, dynamic>> data;
  InMemoryAssetLoader(this.data);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return data[locale.languageCode] ?? {};
  }
}

Future<void> pumpWithLocalization(
    WidgetTester tester,
    Widget child, {
      Locale initialLocale = const Locale('en'),
      Map<String, Map<String, dynamic>> translations = const {
        'en': {
          'start_app': 'Start',
          'hello': 'Hello',
          'home.available_services': 'Available Services',
          // add any keys your widgets use during tests
        },
        'ar': {
          'start_app': 'إبدأ',
          'hello': 'مرحباً',
          'home.available_services': 'الخدمات المتاحة',
        },
      },
    }) async {
  // EasyLocalization needs binding
  TestWidgetsFlutterBinding.ensureInitialized();

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'ignored', // path is ignored by custom loader
      fallbackLocale: const Locale('en'),
      assetLoader: InMemoryAssetLoader(translations),
      startLocale: initialLocale,
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
