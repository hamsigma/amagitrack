import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sale_model.dart';
import 'dashboard_page.dart' show formatRupiah;

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

  Box<Sale> get _salesBox => Hive.box<Sale>('sales_box');

  List<Sale> _getTodaySales() {
    final now = DateTime.now();
    return _salesBox.values.where((s) {
      return s.dateTime.year == now.year &&
          s.dateTime.month == now.month &&
          s.dateTime.day == now.day;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  int _totalRevenue(List<Sale> sales) =>
      sales.fold(0, (sum, s) => sum + s.totalPrice);

  int _totalCups(List<Sale> sales) =>
      sales.fold(0, (sum, s) => sum + s.quantity);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _salesBox.listenable(),
      builder: (context, Box<Sale> box, _) {
        final todaySales = _getTodaySales();
        final revenue = _totalRevenue(todaySales);
        final cups = _totalCups(todaySales);
        final visibleSales = todaySales.take(_visibleCount).toList();
        final hasMore = todaySales.length > _visibleCount;

        return Scaffold(
          backgroundColor: _bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.coffee, color: Colors.white, size: 18),
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
                        onPressed: () {},
                        icon: Icon(Icons.search, color: _textSecondary),
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
                            DateFormat('EEEE, d MMM').format(DateTime.now()).toUpperCase(),
                            style: TextStyle(
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: _textSecondary),
                            const SizedBox(width: 6),
                            const Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
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
                              Text(
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
                                style: TextStyle(
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
                              Text(
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
                                style: TextStyle(
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
                  child: todaySales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 56, color: _textSecondary.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada data transaksi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Transaksi yang disimpan akan muncul di sini',
                                style: TextStyle(fontSize: 12, color: _textSecondary.withValues(alpha: 0.7)),
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

  Widget _buildTransactionItem(Sale sale) {
    return Container(
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
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ),
          Text(
            formatRupiah(sale.totalPrice),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ],
      ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
      'Kopi Hitam': const Color(0xFF3E2723),
      'Kopi Susu': const Color(0xFF8D6E63),
      'Kopi Krim': const Color(0xFFBCAAA4),
      'Kopi Milo Krim': const Color(0xFF5D4037),
      'Kopi Gula Aren': const Color(0xFFFF8F00),
      'Cappuccino': const Color(0xFFA1887F),
      'V60': const Color(0xFF2D5233),
    };
    return colors[name] ?? const Color(0xFF6D4C41);
  }
}
