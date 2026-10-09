import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'views/login_view.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/dispatcher/dispatcher_dashboard.dart';
import 'views/driver/driver_dashboard.dart';
import 'views/public/public_tracking_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const EntregaYaApp(),
    ),
  );
}

class EntregaYaApp extends StatelessWidget {
  const EntregaYaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EntregaYa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1), // Blue 900
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFFFFB300), // Amber 700
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginView(),
        '/tracking': (context) => const Scaffold(
              body: PublicTrackingView(),
            ),
        '/admin': (context) => const AdminDashboard(),
        '/dispatcher': (context) => const DispatcherDashboard(),
        '/driver': (context) => const DriverDashboard(),
      },
    );
  }
}
