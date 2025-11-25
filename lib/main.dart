import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:smartclassrom/pages/dashboard_admin.dart';
import 'package:smartclassrom/pages/dashboard_maestro.dart';
import 'package:smartclassrom/pages/login_page.dart';

void main() async {
  // Asegura la correcta inicialización del entorno Flutter antes de ejecutar código asíncrono.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase usando las opciones generadas por FlutterFire CLI.
  // Esto asegura que la app se conecte a tu proyecto de Firebase en cualquier plataforma.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ejecuta la aplicación principal.
  runApp(const SmartClassApp());
}

class SmartClassApp extends StatelessWidget {
  const SmartClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Oculta el banner de debug en la esquina superior derecha.
      debugShowCheckedModeBanner: false,

      // Nombre de la aplicación.
      title: 'SmartClass',

      // Configuración global del tema visual.
      theme: ThemeData(
        // Color primario utilizado en varios widgets.
        primaryColor: const Color(0xFF527630),

        // Genera un esquema de colores completo a partir del color semilla.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF527630)),

        // Activa Material Design 3.
        useMaterial3: true,
      ),

      // Ruta inicial cuando se abre la app.
      initialRoute: '/',

      // Mapa de rutas que definen la navegación dentro de la app.
      routes: {
        // Página principal de inicio de sesión.
        '/': (context) => const LoginPage(),

        // Dashboard exclusivo para administradores.
        '/dashboard_admin': (context) => const DashboardAdmin(),

        // Dashboard exclusivo para maestros.
        '/dashboard_maestro': (context) => const DashboardMaestro(),
      },
    );
  }
}
