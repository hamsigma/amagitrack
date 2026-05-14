import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sale_model.dart';
import 'dashboard_page.dart' show formatRupiah;
import '../utils/download_helper.dart'
    if (dart.library.html) '../utils/download_helper_web.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const _bgColor = Color(0xFFFDF7F2);
  static const _primaryGreen = Color(0xFF2D5233);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF8B8B8B);

  int _visibleCount = 10;
  DateTime _selectedDate = DateTime.now();
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Daftar menu lengkap untuk dropdown edit
  final Map<String, int> _allMenus = {
    'Kopi Hitam': 13000,
    'Kopi Susu': 15000,
    'Kopi Krim': 15000,
    'Kopi Milo Krim': 20000,
    'Kopi Gula Aren': 20000,
    'Cappuccino': 18000,
    'V60': 20000,
    'Teh': 5000,
    'Teh Tarik': 15000,
    'Lemon Tea': 10000,
    'Leci Tea': 10000,
    'Peach Tea': 10000,
    'Milo': 15000,
    'Milo Krim': 20000,
    'Red Velvet': 20000,
    'Orange Squash': 20000,
    'Blue Curacao (krim/soda)': 20000,
    'Raspberry (krim/soda)': 20000,
  };

  Box<Sale> get _salesBox => Hive.box<Sale>('sales_box');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Sale> _getSalesByDate() {
    return _salesBox.values.where((s) {
      return s.dateTime.year == _selectedDate.year &&
          s.dateTime.month == _selectedDate.month &&
          s.dateTime.day == _selectedDate.day;
    }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Sale> _getFilteredSales(List<Sale> sales) {
    if (_searchQuery.isEmpty) return sales;
    return sales.where((s) {
      return s.menuName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  int _totalRevenue(List<Sale> sales) =>
      sales.fold(0, (sum, s) => sum + s.totalPrice);

  int _totalCups(List<Sale> sales) =>
      sales.fold(0, (sum, s) => sum + s.quantity);

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              surface: Color(0xFFFDF7F2),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _visibleCount = 10;
      });
    }
  }

  // ===== EDIT TRANSAKSI (Pop-up Dialog) =====
  void _showEditDialog(Sale sale) {
    String editMenu = sale.menuName;
    final qtyController = TextEditingController(text: sale.quantity.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final price = _allMenus[editMenu] ?? sale.pricePerItem;
            final qty = int.tryParse(qtyController.text) ?? 0;
            final subtotal = price * qty;

            return AlertDialog(
              backgroundColor: const Color(0xFFFDF7F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Edit Transaksi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: editMenu,
                          items: _allMenus.keys.map((name) {
                            return DropdownMenuItem(
                              value: name,
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setDialogState(() => editMenu = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Jumlah',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Subtotal: ${formatRupiah(subtotal)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Batal', style: TextStyle(color: _textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newQty = int.tryParse(qtyController.text);
                    if (newQty == null || newQty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Jumlah harus lebih dari 0'),
                        ),
                      );
                      return;
                    }
                    // Update data di Hive
                    final key = sale.key;
                    final updatedSale = Sale(
                      menuName: editMenu,
                      quantity: newQty,
                      pricePerItem: _allMenus[editMenu] ?? sale.pricePerItem,
                      dateTime: sale.dateTime,
                    );
                    _salesBox.put(key, updatedSale);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Transaksi berhasil diperbarui'),
                        backgroundColor: _primaryGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===== DELETE TRANSAKSI (Konfirmasi Dialog) =====
  void _showDeleteDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDF7F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Transaksi?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Yakin ingin menghapus transaksi "${sale.menuName}" (${sale.quantity} cup)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                sale.delete();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Transaksi berhasil dihapus'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _salesBox.listenable(),
      builder: (context, Box<Sale> box, _) {
        final dateSales = _getSalesByDate();
        final filteredSales = _getFilteredSales(dateSales);
        final revenue = _totalRevenue(filteredSales);
        final cups = _totalCups(filteredSales);
        final visibleSales = filteredSales.take(_visibleCount).toList();
        final hasMore = filteredSales.length > _visibleCount;

        return Scaffold(
          backgroundColor: _bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _isSearching
                      ? _buildSearchBar()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                            IconButton(
                              onPressed: () =>
                                  setState(() => _isSearching = true),
                              icon: const Icon(
                                Icons.search,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),

                // Date + Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'EEEE, d MMM',
                            ).format(_selectedDate).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'History',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Tombol Export CSV
                          GestureDetector(
                            onTap: _exportCSV,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: const Icon(
                                Icons.file_download_outlined,
                                size: 18,
                                color: _primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tombol Tanggal
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _isToday
                                    ? Colors.white
                                    : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isToday
                                      ? const Color(0xFFE0E0E0)
                                      : _primaryGreen,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: _isToday
                                        ? _textSecondary
                                        : _primaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isToday
                                        ? 'Today'
                                        : DateFormat(
                                            'd MMM yyyy',
                                          ).format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _isToday
                                          ? _textPrimary
                                          : _primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Summary Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL SALES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatRupiah(revenue),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL CUPS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$cups cups',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Transaction List
                Expanded(
                  child: filteredSales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 56,
                                color: _textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Tidak ada hasil untuk "$_searchQuery"'
                                    : 'Belum ada data transaksi',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Coba kata kunci lain'
                                    : 'Transaksi yang disimpan akan muncul di sini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: visibleSales.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == visibleSales.length) {
                              return _buildLoadMoreButton();
                            }
                            return _buildTransactionItem(visibleSales[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== SEARCH BAR =====
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari nama menu...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Tutup',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===== TRANSACTION ITEM (long press + tombol edit/delete) =====
  Widget _buildTransactionItem(Sale sale) {
    return GestureDetector(
      onLongPress: () => _showActionMenu(sale),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getMenuColor(sale.menuName),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.coffee, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.menuName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${sale.quantity} cup • ${DateFormat('HH:mm').format(sale.dateTime)} WIB',
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRupiah(sale.totalPrice),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _showEditDialog(sale),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: _primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showDeleteDialog(sale),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== POP UP MENU: EDIT / DELETE =====
  void _showActionMenu(Sale sale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFFDF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                sale.menuName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${sale.quantity} cup • ${formatRupiah(sale.totalPrice)}',
                style: const TextStyle(fontSize: 13, color: _textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditDialog(sale);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        side: const BorderSide(color: _primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDeleteDialog(sale);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: OutlinedButton(
          onPressed: () => setState(() => _visibleCount += 10),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          ),
          child: const Text(
            'Load more transactions',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  static Color _getMenuColor(String name) {
    final colors = {
      // Kopi
      'Kopi Hitam': const Color(0xFF3E2723),
      'Kopi Susu': const Color(0xFF8D6E63),
      'Kopi Krim': const Color(0xFFBCAAA4),
      'Kopi Milo Krim': const Color(0xFF5D4037),
      'Kopi Gula Aren': const Color(0xFFFF8F00),
      'Cappuccino': const Color(0xFFA1887F),
      'V60': const Color(0xFF2D5233),
      // Teh
      'Teh': const Color(0xFF558B2F),
      'Teh Tarik': const Color(0xFFE65100),
      'Lemon Tea': const Color(0xFFF9A825),
      'Leci Tea': const Color(0xFFD81B60),
      'Peach Tea': const Color(0xFFFF7043),
      // Non Kopi
      'Milo': const Color(0xFF4E342E),
      'Milo Krim': const Color(0xFF6D4C41),
      'Red Velvet': const Color(0xFFC62828),
      'Orange Squash': const Color(0xFFEF6C00),
      'Blue Curacao (krim/soda)': const Color(0xFF1565C0),
      'Raspberry (krim/soda)': const Color(0xFFAD1457),
    };
    return colors[name] ?? const Color(0xFF6D4C41);
  }

  // ===== EXPORT CSV =====
  Future<void> _exportCSV() async {
    try {
      // Filter hanya data dari tanggal yang dipilih
      final sales = _salesBox.values.where((s) {
        return s.dateTime.year == _selectedDate.year &&
            s.dateTime.month == _selectedDate.month &&
            s.dateTime.day == _selectedDate.day;
      }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));

      final dateLabel = DateFormat('d MMM yyyy').format(_selectedDate);

      if (sales.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak ada data tanggal $dateLabel'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('Laporan Penjualan AmagiTrack - $dateLabel');
      buffer.writeln('No,Tanggal,Waktu,Menu,Jumlah,Harga Satuan,Total');

      for (int i = 0; i < sales.length; i++) {
        final s = sales[i];
        buffer.writeln(
          '${i + 1},'
          '${DateFormat('yyyy-MM-dd').format(s.dateTime)},'
          '${DateFormat('HH:mm').format(s.dateTime)},'
          '${s.menuName},'
          '${s.quantity},'
          '${s.pricePerItem},'
          '${s.totalPrice}',
        );
      }

      final totalRev = sales.fold(0, (sum, s) => sum + s.totalPrice);
      final totalQty = sales.fold(0, (sum, s) => sum + s.quantity);
      buffer.writeln('');
      buffer.writeln(',,,TOTAL,$totalQty,,$totalRev');

      final fileName =
          'AmagiTrack_${DateFormat('yyyyMMdd').format(_selectedDate)}.csv';
      await downloadCSV(buffer.toString(), fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil export: $fileName'),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal export: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
