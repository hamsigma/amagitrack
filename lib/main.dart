import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/sale_model.dart';
import 'views/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Hive
  await Hive.initFlutter();
  
  // Registrasi Adapter (PENTING)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(SaleAdapter());
  }
  
  // Buka Box Storage
  await Hive.openBox<Sale>('sales_box');

  runApp(const AmagiTrackApp());
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
      // Memanggil MainNavigation sebagai shell utama
      home: const MainNavigation(), 
    );
  }
}