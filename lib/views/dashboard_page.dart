import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sale_model.dart';

// Helper format Rupiah
String formatRupiah(int amount) {
  String s = amount.toString();
  String result = s.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return 'Rp $result';
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const _bgColor = Color(0xFFFDF7F2);
  static const _primaryGreen = Color(0xFF2D5233);
  static const _revenueGreen = Color(0xFFE8F5E9);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF8B8B8B);

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

  List<Sale> _getYesterdaySales() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return _salesBox.values.where((s) {
      return s.dateTime.year == y.year &&
          s.dateTime.month == y.month &&
          s.dateTime.day == y.day;
    }).toList();
  }

  int _totalRevenue(List<Sale> sales) =>
      sales.fold(0, (sum, s) => sum + s.totalPrice);

  int _totalTransactions(List<Sale> sales) => sales.length;

  Map<String, int> _topCategories(List<Sale> sales) {
    final map = <String, int>{};
    for (var s in sales) {
      map[s.menuName] = (map[s.menuName] ?? 0) + s.totalPrice;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _salesBox.listenable(),
      builder: (context, Box<Sale> box, _) {
        final todaySales = _getTodaySales();
        final yesterdaySales = _getYesterdaySales();
        final revenue = _totalRevenue(todaySales);
        final yRevenue = _totalRevenue(yesterdaySales);
        final txCount = _totalTransactions(todaySales);
        final avgTicket = txCount > 0 ? revenue ~/ txCount : 0;
        final categories = _topCategories(todaySales);
        final recentSales = todaySales.take(3).toList();

        // Percentage change
        double pctChange = 0;
        if (yRevenue > 0) {
          pctChange = ((revenue - yRevenue) / yRevenue) * 100;
        }

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
                  const SizedBox(height: 24),

                  // Control Center + Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONTROL CENTER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Daily\nSummary',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: _textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMMM d,\nyyyy').format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Revenue Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _revenueGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL DAILY REVENUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _primaryGreen.withValues(alpha: 0.7),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatRupiah(revenue),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              pctChange >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 16,
                              color: pctChange >= 0
                                  ? _primaryGreen
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${pctChange.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: pctChange >= 0
                                    ? _primaryGreen
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'vs. kemarin',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Transactions Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF0F0F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _revenueGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.receipt_long, size: 20, color: _primaryGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'TRANSACTIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$txCount',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Avg Ticket',
                              style: TextStyle(fontSize: 13, color: _textSecondary),
                            ),
                            Text(
                              formatRupiah(avgTicket),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Top Categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOP CATEGORIES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'View Report >',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (categories.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Belum ada data penjualan hari ini',
                          style: TextStyle(color: _textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    _buildCategoryGrid(categories),
                  const SizedBox(height: 20),

                  // Recent Activity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        'SEE ALL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recentSales.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Belum ada aktivitas hari ini',
                          style: TextStyle(color: _textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...recentSales.map((sale) => _buildActivityItem(sale)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid(Map<String, int> categories) {
    final entries = categories.entries.take(4).toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: entries.map((e) {
        return SizedBox(
          width: 155,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.key,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatRupiah(e.value),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityItem(Sale sale) {
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _getMenuColor(sale.menuName),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.coffee, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.menuName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('HH:mm').format(sale.dateTime)} WIB • ${sale.quantity} cup',
                  style: TextStyle(fontSize: 12, color: _textSecondary),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'COMPLETED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
        ],
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
