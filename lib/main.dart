import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'dashboard_admin.dart';
import 'dashboard_maestro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase con la configuración de FlutterFire
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SmartClassApp());
}

class SmartClassApp extends StatelessWidget {
  const SmartClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartClass',
      theme: ThemeData(
        primaryColor: const Color(0xFF527630),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF527630)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard_admin': (context) => const DashboardAdmin(),
        '/dashboard_maestro': (context) => const DashboardMaestro(),
      },
    );
  }
}
