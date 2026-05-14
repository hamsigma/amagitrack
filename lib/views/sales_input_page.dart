import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sale_model.dart';
import 'dashboard_page.dart' show formatRupiah;

class SalesInputPage extends StatefulWidget {
  const SalesInputPage({super.key});

  @override
  State<SalesInputPage> createState() => _SalesInputPageState();
}

class _SalesInputPageState extends State<SalesInputPage> {
  static const _bgColor = Color(0xFFFDF7F2);
  static const _primaryGreen = Color(0xFF2D5233);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF8B8B8B);

  String? _selectedMenu;
  String _quantityStr = '0';
  String _selectedCategory = '☕ Kopi';

  // Menu dikelompokkan berdasarkan kategori
  final Map<String, Map<String, int>> _menuCategories = {
    '☕ Kopi': {
      'Kopi Hitam': 13000,
      'Kopi Susu': 15000,
      'Kopi Krim': 15000,
      'Kopi Milo Krim': 20000,
      'Kopi Gula Aren': 20000,
      'Cappuccino': 18000,
      'V60': 20000,
    },
    '🍵 Teh': {
      'Teh': 5000,
      'Teh Tarik': 15000,
      'Lemon Tea': 10000,
      'Leci Tea': 10000,
      'Peach Tea': 10000,
    },
    '🥤 Non Kopi': {
      'Milo': 15000,
      'Milo Krim': 20000,
      'Red Velvet': 20000,
      'Orange Squash': 20000,
      'Blue Curacao (krim/soda)': 20000,
      'Raspberry (krim/soda)': 20000,
    },
  };

  // Gabungan semua menu untuk lookup harga
  Map<String, int> get _allMenus {
    final map = <String, int>{};
    for (var category in _menuCategories.values) {
      map.addAll(category);
    }
    return map;
  }

  Box<Sale> get _salesBox => Hive.box<Sale>('sales_box');

  int get _quantity => int.tryParse(_quantityStr) ?? 0;

  int get _subtotal {
    if (_selectedMenu == null || _quantity <= 0) return 0;
    return _allMenus[_selectedMenu]! * _quantity;
  }

  int _getTodaySalesCount() {
    final now = DateTime.now();
    return _salesBox.values.where((s) {
      return s.dateTime.year == now.year &&
          s.dateTime.month == now.month &&
          s.dateTime.day == now.day;
    }).length;
  }

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'C') {
        _quantityStr = '0';
      } else if (value == '⌫') {
        if (_quantityStr.length > 1) {
          _quantityStr = _quantityStr.substring(0, _quantityStr.length - 1);
        } else {
          _quantityStr = '0';
        }
      } else {
        if (_quantityStr == '0') {
          _quantityStr = value;
        } else if (_quantityStr.length < 4) {
          _quantityStr += value;
        }
      }
    });
  }

  void _saveData() {
    if (_selectedMenu == null) {
      _showSnackbar('Pilih menu terlebih dahulu!');
      return;
    }
    if (_quantity <= 0) {
      _showSnackbar('Jumlah harus lebih dari 0!');
      return;
    }

    final newSale = Sale(
      menuName: _selectedMenu!,
      quantity: _quantity,
      pricePerItem: _allMenus[_selectedMenu]!,
      dateTime: DateTime.now(),
    );

    _salesBox.add(newSale);
    _showSnackbar('Berhasil menyimpan $_selectedMenu!');

    setState(() {
      _selectedMenu = null;
      _quantityStr = '0';
    });
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _salesBox.listenable(),
      builder: (context, Box<Sale> box, _) {
        final todayCount = _getTodaySalesCount();

        return Scaffold(
          backgroundColor: _bgColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Header
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          '../../assets/images/amagi_logo.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AmagiTrack',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Today's Sales Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF0F0F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TODAY'S SALES",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$todayCount',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kategori Tab Selector
                  Row(
                    children: _menuCategories.keys.map((category) {
                      final isActive = _selectedCategory == category;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                                _selectedMenu = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isActive ? _primaryGreen : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? _primaryGreen
                                      : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? Colors.white
                                        : _textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Select Product
                  Text(
                    'SELECT PRODUCT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text(
                          'Pilih Menu',
                          style: TextStyle(color: _textSecondary),
                        ),
                        value: _selectedMenu,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: _textSecondary,
                        ),
                        items: _buildCategoryMenuItems(),
                        onChanged: (val) => setState(() => _selectedMenu = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quantity
                  Text(
                    'QUANTITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Center(
                      child: Text(
                        _quantityStr,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtotal
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                            Text(
                              formatRupiah(_subtotal),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Numpad
                  _buildNumpad(),
                  const SizedBox(height: 16),

                  // Simpan Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saveData,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _onNumpadTap(key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Center(
                          child: key == '⌫'
                              ? Icon(
                                  Icons.backspace_outlined,
                                  size: 20,
                                  color: _textSecondary,
                                )
                              : Text(
                                  key,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: key == 'C'
                                        ? Colors.red
                                        : _textPrimary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // Membuat dropdown items berdasarkan kategori yang dipilih
  List<DropdownMenuItem<String>> _buildCategoryMenuItems() {
    final menus = _menuCategories[_selectedCategory] ?? {};
    return menus.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              entry.key,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
            ),
            Text(
              formatRupiah(entry.value),
              style: const TextStyle(color: Color(0xFF8B8B8B), fontSize: 12),
            ),
          ],
        ),
      );
    }).toList();
  }
}
