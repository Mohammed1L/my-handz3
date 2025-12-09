import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:senior_project/firebase_options.dart';
import '_ProfilePageState.dart';
import 'phone_verification_page.dart';
import '_LandingPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '_SplashPage.dart';
import '_Chatbot.dart';
import '_BookingScreenState.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'main_page.dart';
import 'CompanyRegisterPage.dart';
import 'CompanyDashboardPage.dart';
import 'services/stripe_service.dart';
import 'admin/admin_reindex_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  await EasyLocalization.ensureInitialized();
  try { await dotenv.load(fileName: "K.env"); } catch (_) {}
  try { await StripeService.init(); } catch (_) {}
  final prefs = await SharedPreferences.getInstance();
  final hasSeenLanding = prefs.getBool('seenLandingPage') ?? false;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'lib/translations',
      fallbackLocale: const Locale('en'),
      child: MyApp(hasSeenLanding: hasSeenLanding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasSeenLanding;
  const MyApp({super.key, required this.hasSeenLanding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Handz',
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const SplashScreen(),
      routes: {
        '/landing': (context) => const LandingPage(),
        '/phoneVerification': (context) => const PhoneVerificationPage(),
        '/main': (context) => const MainPage(),
        '/chatbot': (context) => const ChatbotPage(),
        '/profile': (context) => const MyProfilePage(),
        '/companyRegister': (context) => const CompanyRegisterPage(),
        '/companyDashboard': (context) => const CompanyDashboardPage(),
        '/admin/reindex': (context) => const AdminReindexPage(),

        '/booking': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>?;

          return BookingScreen(
            services: args?['services'] ?? [],
            providerName: args?['providerName'] ?? 'Unknown Provider',
            totalCost: args?['totalCost'] ?? 0.0,
          );

        },
      },
    );
  }
}
