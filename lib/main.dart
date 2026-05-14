import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/sale_model.dart';
import 'views/main_navigation.dart';

void main() {
  // Tangkap error global agar aplikasi tidak crash
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Error handler untuk Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exceptionAsString()}');
    };

    try {
      // Inisialisasi Hive
      await Hive.initFlutter();

      // Registrasi Adapter (PENTING)
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SaleAdapter());
      }

      // Buka Box Storage
      await Hive.openBox<Sale>('sales_box');

      runApp(const AmagiTrackApp());
    } catch (e) {
      // Jika Hive gagal, tampilkan halaman error
      debugPrint('Database Error: $e');
      runApp(const AmagiTrackErrorApp());
    }
  }, (error, stackTrace) {
    debugPrint('Uncaught Error: $error');
    debugPrint('Stack Trace: $stackTrace');
  });
}

class AmagiTrackApp extends StatelessWidget {
  const AmagiTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AmagiTrack',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

// Halaman error jika database gagal
class AmagiTrackErrorApp extends StatelessWidget {
  const AmagiTrackErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFDF7F2),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Database tidak dapat dimuat.\nCoba restart aplikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF8B8B8B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}