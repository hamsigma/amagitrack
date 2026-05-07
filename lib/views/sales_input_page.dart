import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/sale_model.dart';

class SalesInputPage extends StatefulWidget {
  const SalesInputPage({super.key});

  @override
  State<SalesInputPage> createState() => _SalesInputPageState();
}

class _SalesInputPageState extends State<SalesInputPage> {
  final TextEditingController _qtyController = TextEditingController();
  String? _selectedMenu;

  // Menggunakan Map agar kita bisa menyimpan nama menu dan harganya
  final Map<String, int> _menuList = {
    'Kopi Hitam': 13000,
    'Kopi Susu': 15000,
    'Kopi Krim': 15000,
    'Kopi Milo Krim': 20000,
    'Kopi Gula Aren': 20000,
    'Cappuccino': 18000,
    'V60': 20000,
  };

  void _saveData() {
    if (_selectedMenu == null || _qtyController.text.isEmpty) {
      _showSnackbar("Pilih menu dan isi jumlah dulu!");
      return;
    }

    final salesBox = Hive.box<Sale>('sales_box');
    
    final newSale = Sale(
      menuName: _selectedMenu!,
      quantity: int.parse(_qtyController.text),
      pricePerItem: _menuList[_selectedMenu]!,
      dateTime: DateTime.now(),
    );

    salesBox.add(newSale);

    // Perbaikan: Hapus kurung kurawal pada $_selectedMenu
    _showSnackbar("Berhasil menyimpan $_selectedMenu!");

    setState(() {
      _selectedMenu = null;
      _qtyController.clear();
    });
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F2),
      appBar: AppBar(
        title: const Text("Amagi Track", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6D4C41),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MENU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Pilih Menu Kopi"),
              value: _selectedMenu,
              // .keys digunakan di sini untuk mengambil nama menu dari Map
              items: _menuList.keys.map((String key) {
                return DropdownMenuItem<String>(value: key, child: Text(key));
              }).toList(),
              onChanged: (val) => setState(() => _selectedMenu = val),
            ),
            const SizedBox(height: 20),
            const Text("QUANTITY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Contoh: 2"),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D4C41)),
                child: const Text("SIMPAN TRANSAKSI", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}