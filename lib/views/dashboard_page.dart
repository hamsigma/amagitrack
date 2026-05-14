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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _bgColor = Color(0xFFFDF7F2);
  static const _primaryGreen = Color(0xFF2D5233);
  static const _revenueGreen = Color(0xFFE8F5E9);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF8B8B8B);

  // Toggle: 0 = Weekly, 1 = Monthly
  int _chartMode = 0;

  Box<Sale> get _salesBox => Hive.box<Sale>('sales_box');

  List<Sale> _getTodaySales() {
    final now = DateTime.now();
    return _salesBox.values.where((s) {
      return s.dateTime.year == now.year &&
          s.dateTime.month == now.month &&
          s.dateTime.day == now.day;
    }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
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

  // Data 7 hari terakhir untuk chart weekly
  List<MapEntry<String, int>> _getWeeklyData() {
    final now = DateTime.now();
    final data = <MapEntry<String, int>>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final daySales = _salesBox.values.where((s) {
        return s.dateTime.year == day.year &&
            s.dateTime.month == day.month &&
            s.dateTime.day == day.day;
      });
      final rev = daySales.fold(0, (sum, s) => sum + s.totalPrice);
      data.add(MapEntry(DateFormat('E').format(day), rev));
    }
    return data;
  }

  // Data 4 minggu terakhir untuk chart monthly
  List<MapEntry<String, int>> _getMonthlyData() {
    final now = DateTime.now();
    final data = <MapEntry<String, int>>[];
    for (int w = 3; w >= 0; w--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (w * 7)));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekSales = _salesBox.values.where((s) {
        final d = s.dateTime;
        return (d.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            d.isBefore(weekEnd.add(const Duration(days: 1))));
      });
      final rev = weekSales.fold(0, (sum, s) => sum + s.totalPrice);
      final label = 'W${4 - w}';
      data.add(MapEntry(label, rev));
    }
    return data;
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
        final chartData = _chartMode == 0
            ? _getWeeklyData()
            : _getMonthlyData();

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: _textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'MMMM d,\nyyyy',
                              ).format(DateTime.now()),
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
                  _buildRevenueCard(revenue, yRevenue, pctChange),
                  const SizedBox(height: 16),

                  // ===== GRAFIK PENJUALAN =====
                  _buildSalesChart(chartData),
                  const SizedBox(height: 16),

                  // Transactions Card
                  _buildTransactionsCard(txCount, avgTicket),
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
                      GestureDetector(
                        onTap: () => _showCategoryReport(context, todaySales),
                        child: const Text(
                          'View Report >',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primaryGreen,
                          ),
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
                      GestureDetector(
                        onTap: () => _showAllActivity(context, todaySales),
                        child: const Text(
                          'SEE ALL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primaryGreen,
                          ),
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

  // ===== REVENUE CARD =====
  Widget _buildRevenueCard(int revenue, int yRevenue, double pctChange) {
    return Container(
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
          if (yRevenue == 0 && revenue == 0)
            Text(
              'Belum ada transaksi hari ini & kemarin',
              style: TextStyle(fontSize: 12, color: _textSecondary),
            )
          else if (yRevenue == 0)
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: _primaryGreen),
                const SizedBox(width: 4),
                Text(
                  'Tidak ada data kemarin untuk perbandingan',
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Icon(
                  pctChange >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: pctChange >= 0 ? _primaryGreen : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${pctChange >= 0 ? '+' : ''}${pctChange.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pctChange >= 0 ? _primaryGreen : Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${pctChange >= 0 ? '+' : ''}${formatRupiah(revenue - yRevenue)})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: pctChange >= 0 ? _primaryGreen : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Kemarin: ${formatRupiah(yRevenue)}',
              style: TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  // ===== GRAFIK PENJUALAN (Custom Bar Chart) =====
  Widget _buildSalesChart(List<MapEntry<String, int>> data) {
    final maxVal = data.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return Container(
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
          // Header + Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SALES OVERVIEW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _chartMode == 0 ? '7 Hari Terakhir' : '4 Minggu Terakhir',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn('Weekly', 0),
                    _buildToggleBtn('Monthly', 1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((entry) {
                final barRatio = maxVal > 0 ? (entry.value / maxVal) : 0.0;
                final isToday = data.indexOf(entry) == data.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.value > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatShortRupiah(entry.value),
                              style: TextStyle(
                                fontSize: 9,
                                color: isToday ? _primaryGreen : _textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 3),
                        Container(
                          height: barRatio * 130 < 6 && entry.value > 0
                              ? 6
                              : barRatio * 130,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isToday
                                ? _primaryGreen
                                : const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 10,
                              color: isToday ? _primaryGreen : _textSecondary,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, int mode) {
    final isActive = _chartMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _chartMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : _textSecondary,
          ),
        ),
      ),
    );
  }

  String _formatShortRupiah(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}rb';
    return amount.toString();
  }

  // ===== TRANSACTIONS CARD =====
  Widget _buildTransactionsCard(int txCount, int avgTicket) {
    return Container(
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
                style: const TextStyle(
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
      'Teh': const Color(0xFF558B2F),
      'Teh Tarik': const Color(0xFFE65100),
      'Lemon Tea': const Color(0xFFF9A825),
      'Leci Tea': const Color(0xFFD81B60),
      'Peach Tea': const Color(0xFFFF7043),
      'Milo': const Color(0xFF4E342E),
      'Milo Krim': const Color(0xFF6D4C41),
      'Red Velvet': const Color(0xFFC62828),
      'Orange Squash': const Color(0xFFEF6C00),
      'Blue Curacao (krim/soda)': const Color(0xFF1565C0),
      'Raspberry (krim/soda)': const Color(0xFFAD1457),
    };
    return colors[name] ?? const Color(0xFF6D4C41);
  }

  // Bottom Sheet: Laporan Kategori Lengkap
  void _showCategoryReport(BuildContext context, List<Sale> todaySales) {
    final Map<String, Map<String, int>> report = {};
    for (var sale in todaySales) {
      if (!report.containsKey(sale.menuName)) {
        report[sale.menuName] = {'qty': 0, 'revenue': 0};
      }
      report[sale.menuName]!['qty'] =
          report[sale.menuName]!['qty']! + sale.quantity;
      report[sale.menuName]!['revenue'] =
          report[sale.menuName]!['revenue']! + sale.totalPrice;
    }
    final sorted = report.entries.toList()
      ..sort((a, b) => b.value['revenue']!.compareTo(a.value['revenue']!));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFDF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Laporan Kategori Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              if (sorted.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Belum ada data penjualan hari ini'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sorted.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final entry = sorted[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getMenuColor(entry.key),
                          child: const Icon(
                            Icons.coffee,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text('${entry.value['qty']} cup terjual'),
                        trailing: Text(
                          formatRupiah(entry.value['revenue']!),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Bottom Sheet: Semua Aktivitas Hari Ini
  void _showAllActivity(BuildContext context, List<Sale> todaySales) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFDF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
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
                'Semua Aktivitas Hari Ini (${todaySales.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              if (todaySales.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Belum ada aktivitas hari ini'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: todaySales.length,
                    itemBuilder: (ctx, i) => _buildActivityItem(todaySales[i]),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
